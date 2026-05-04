import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booking_record.dart';
import '../models/center.dart';
import '../utils/document_ids.dart';
import '../utils/seat_labels.dart';
import 'firebase_state.dart';

class BookingStore {
  static const String _historyKey = 'booking_history_v3';
  static const String _blockedKey = 'blocked_seats_v3';
  static const String _bookingsCollectionName = 'bookings';
  static const String _blockedCollectionName = 'center_blocked_seats';
  static final Map<String, Set<int>> _selectedByCenter = {};
  static final Map<String, Set<int>> _bookedByCenter = {};
  static final Map<String, Set<int>> _blockedByCenter = {};
  static final Map<String, StreamController<Set<int>>> _bookedControllers = {};
  static final Map<String, StreamController<Set<int>>> _blockedControllers = {};
  static final StreamController<List<BookingRecord>> _historyController =
      StreamController<List<BookingRecord>>.broadcast(onListen: _emitHistory);
  static final List<BookingRecord> _history = [];
  static bool _initialized = false;
  static Timer? _statusTimer;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _bookingSubscription;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _blockedSubscription;

  static StreamController<Set<int>> _bookedController(String centerId) {
    return _bookedControllers.putIfAbsent(centerId, () {
      late final StreamController<Set<int>> controller;
      controller = StreamController<Set<int>>.broadcast(
        onListen: () => controller.add(Set.unmodifiable(bookedSeats(centerId))),
      );
      return controller;
    });
  }

  static StreamController<Set<int>> _blockedController(String centerId) {
    return _blockedControllers.putIfAbsent(centerId, () {
      late final StreamController<Set<int>> controller;
      controller = StreamController<Set<int>>.broadcast(
        onListen: () =>
            controller.add(Set.unmodifiable(blockedSeats(centerId))),
      );
      return controller;
    });
  }

  static void _emitBooked(String centerId) {
    final controller = _bookedControllers[centerId];
    if (controller == null || controller.isClosed) return;
    controller.add(Set.unmodifiable(bookedSeats(centerId)));
  }

  static void _emitBlocked(String centerId) {
    final controller = _blockedControllers[centerId];
    if (controller == null || controller.isClosed) return;
    controller.add(Set.unmodifiable(blockedSeats(centerId)));
  }

  static void _emitHistory() {
    if (_historyController.isClosed) return;
    _historyController.add(List.unmodifiable(_history));
  }

  static void _emitAllBlocked() {
    for (final centerId in _blockedControllers.keys) {
      _emitBlocked(centerId);
    }
  }

  static void _emitAllBooked() {
    for (final centerId in _bookedControllers.keys) {
      _emitBooked(centerId);
    }
  }

  static void _rebuildBookedSeats() {
    _bookedByCenter.clear();
    final now = DateTime.now();
    for (final item in _history) {
      if (item.isCanceled) continue;
      final isActiveNow = !item.startAt.isAfter(now) && item.endAt.isAfter(now);
      if (!isActiveNow) continue;
      bookedSeats(item.centerId).addAll(item.seatIndexes);
    }
  }

  static bool _hasOverlap({
    required DateTime startA,
    required DateTime endA,
    required DateTime startB,
    required DateTime endB,
  }) {
    return startA.isBefore(endB) && startB.isBefore(endA);
  }

  static Set<String> _applyAutomaticUpdates() {
    final now = DateTime.now();
    final changedIds = <String>{};
    for (var i = 0; i < _history.length; i++) {
      final item = _history[i];
      if (item.isCanceled || item.isCheckedIn) continue;
      if (now.isBefore(item.noShowDeadline)) continue;
      _history[i] = item.copyWith(
        isCanceled: true,
        canceledAt: now,
        noShowAt: now,
      );
      changedIds.add(item.id);
    }
    return changedIds;
  }

  static void _refreshDerivedState({
    bool emitBooked = true,
    bool emitHistory = true,
  }) {
    final changedIds = _applyAutomaticUpdates();
    _rebuildBookedSeats();
    if (emitBooked) {
      _emitAllBooked();
    }
    if (emitHistory) {
      _emitHistory();
    }
    if (changedIds.isNotEmpty) {
      unawaited(_saveToDisk());
      if (firebaseAvailable && FirebaseAuth.instance.currentUser != null) {
        unawaited(_syncChangedBookingsToCloud(changedIds));
      }
    }
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadFromDisk();
    _startStatusTimer();
    _refreshDerivedState();

    if (!firebaseAvailable) return;
    FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(_refreshCloudSubscriptions());
    });
    await _refreshCloudSubscriptions();
  }

  static void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _refreshDerivedState(),
    );
  }

  static Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_historyKey);
      final blockedRaw = prefs.getString(_blockedKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final loaded = decoded
              .whereType<Map>()
              .map((e) => BookingRecord.fromMap(Map<String, dynamic>.from(e)))
              .toList(growable: false);
          loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _history
            ..clear()
            ..addAll(loaded);
        }
      }

      _blockedByCenter.clear();
      if (blockedRaw != null && blockedRaw.isNotEmpty) {
        final blockedDecoded = jsonDecode(blockedRaw);
        if (blockedDecoded is Map<String, dynamic>) {
          for (final entry in blockedDecoded.entries) {
            final value = entry.value;
            if (value is! List) continue;
            final seats = value
                .map((e) => int.tryParse(e.toString()) ?? -1)
                .where((e) => e >= 0)
                .toSet();
            _blockedByCenter[entry.key] = seats;
          }
        }
      }

      _rebuildBookedSeats();
      _emitAllBooked();
      _emitAllBlocked();
      _emitHistory();
    } catch (_) {}
  }

  static Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_history.map((e) => e.toMap()).toList());
      await prefs.setString(_historyKey, encoded);
      final blockedEncoded = jsonEncode(
        _blockedByCenter.map(
          (key, value) => MapEntry(key, value.toList()..sort()),
        ),
      );
      await prefs.setString(_blockedKey, blockedEncoded);
    } catch (_) {}
  }

  static Future<void> _refreshCloudSubscriptions() async {
    await _bookingSubscription?.cancel();
    await _blockedSubscription?.cancel();
    _bookingSubscription = null;
    _blockedSubscription = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _history.clear();
      _selectedByCenter.clear();
      _bookedByCenter.clear();
      _blockedByCenter.clear();
      _emitAllBooked();
      _emitAllBlocked();
      _emitHistory();
      await _saveToDisk();
      return;
    }

    _bookingSubscription = _bookingsCollection.snapshots().listen((snapshot) {
      final loaded =
          snapshot.docs
              .map((doc) {
                final data = Map<String, dynamic>.from(doc.data());
                data['id'] = data['id']?.toString().isNotEmpty == true
                    ? data['id']
                    : doc.id;
                return BookingRecord.fromMap(data);
              })
              .where((booking) => booking.id.isNotEmpty)
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _history
        ..clear()
        ..addAll(loaded);
      _refreshDerivedState();
      unawaited(_saveToDisk());
    });

    _blockedSubscription = _blockedCollection.snapshots().listen((snapshot) {
      final nextBlocked = <String, Set<int>>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final centerId = data['centerId']?.toString().trim();
        if (centerId == null || centerId.isEmpty) continue;
        final rawSeats = data['seatIndexes'];
        final seats = rawSeats is List
            ? rawSeats
                  .map((e) => int.tryParse(e.toString()) ?? -1)
                  .where((e) => e >= 0)
                  .toSet()
            : <int>{};
        nextBlocked[centerId] = seats;
      }

      _blockedByCenter
        ..clear()
        ..addAll(nextBlocked);
      _emitAllBlocked();
      unawaited(_saveToDisk());
    });
  }

  static Future<void> _syncChangedBookingsToCloud(
    Set<String> bookingIds,
  ) async {
    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) return;

    for (final bookingId in bookingIds) {
      final booking = _history.cast<BookingRecord?>().firstWhere(
        (item) => item?.id == bookingId,
        orElse: () => null,
      );
      if (booking == null) continue;
      try {
        await _bookingsCollection
            .doc(booking.id)
            .set(_cloudMapForBooking(booking));
      } catch (_) {}
    }
  }

  static Set<int> selectedSeats(String centerId) {
    return _selectedByCenter.putIfAbsent(centerId, () => <int>{});
  }

  static Set<int> bookedSeats(String centerId) {
    return _bookedByCenter.putIfAbsent(centerId, () => <int>{});
  }

  static Set<int> blockedSeats(String centerId) {
    return _blockedByCenter.putIfAbsent(centerId, () => <int>{});
  }

  static Stream<Set<int>> bookedSeatsStream(String centerId) {
    return _bookedController(centerId).stream;
  }

  static Stream<Set<int>> blockedSeatsStream(String centerId) {
    return _blockedController(centerId).stream;
  }

  static Stream<List<BookingRecord>> bookingHistoryStream() {
    return _historyController.stream;
  }

  static void toggleSeat(String centerId, int seatIndex) {
    final selected = selectedSeats(centerId);
    if (blockedSeats(centerId).contains(seatIndex)) return;
    if (selected.contains(seatIndex)) {
      selected.remove(seatIndex);
    } else {
      selected.add(seatIndex);
    }
  }

  static bool toggleBlockedSeat(String centerId, int seatIndex) {
    _refreshDerivedState(emitBooked: false, emitHistory: false);
    final blocked = Set<int>.from(blockedSeats(centerId));
    if (bookedSeats(centerId).contains(seatIndex)) return false;

    if (blocked.contains(seatIndex)) {
      blocked.remove(seatIndex);
    } else {
      blocked.add(seatIndex);
      selectedSeats(centerId).remove(seatIndex);
    }

    _blockedByCenter[centerId] = blocked;
    _emitBlocked(centerId);
    unawaited(_saveToDisk());
    if (firebaseAvailable && FirebaseAuth.instance.currentUser != null) {
      unawaited(_writeBlockedSeatsToCloud(centerId, blocked));
    }
    return true;
  }

  static Future<BookingRecord> confirmBooking({
    required EsportCenter center,
    required String customerName,
    required String phone,
    required int durationHours,
    required int pricePerHour,
    required int graceMinutes,
    required DateTime startAt,
    String? createdByUid,
    String? createdByEmail,
  }) async {
    _refreshDerivedState();
    final selected = selectedSeats(center.id);
    final blocked = blockedSeats(center.id);
    final confirmed = selected.toList()..sort();
    final endAt = startAt.add(Duration(hours: durationHours));

    if (confirmed.any(blocked.contains)) {
      throw Exception('One or more selected seats are blocked.');
    }
    for (final item in _history) {
      if (item.isCanceled || item.centerId != center.id) continue;
      if (!item.seatIndexes.any(confirmed.contains)) continue;
      if (_hasOverlap(
        startA: startAt,
        endA: endAt,
        startB: item.startAt,
        endB: item.endAt,
      )) {
        final seats = item.seatIndexes
            .where(confirmed.contains)
            .map((seat) => seatLabelFor(seat, center: center))
            .join(', ');
        throw Exception('$seats already booked for that time.');
      }
    }

    final totalPrice = durationHours * pricePerHour;
    final createdAt = DateTime.now();
    final record = BookingRecord(
      id: readableBookingDocumentId(
        centerName: center.name,
        customerName: customerName,
        timestamp: createdAt,
      ),
      centerId: center.id,
      centerName: center.name,
      customerName: customerName,
      phone: phone,
      durationHours: durationHours,
      pricePerHour: pricePerHour,
      totalPrice: totalPrice,
      seatIndexes: confirmed,
      startAt: startAt,
      createdAt: createdAt,
      createdByUid: createdByUid,
      createdByEmail: createdByEmail,
      graceMinutes: graceMinutes,
    );

    selected.clear();
    _history.insert(0, record);
    _refreshDerivedState(emitBooked: false, emitHistory: false);
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return record;
    }

    try {
      await _bookingsCollection.doc(record.id).set(_cloudMapForBooking(record));
      return record;
    } catch (error) {
      _history.removeWhere((item) => item.id == record.id);
      _refreshDerivedState(emitBooked: false, emitHistory: false);
      await _saveToDisk();
      rethrow;
    }
  }

  static List<BookingRecord> bookingHistory({
    String? centerId,
    String? createdByUid,
    String? createdByEmail,
  }) {
    _refreshDerivedState(emitBooked: false, emitHistory: false);
    Iterable<BookingRecord> items = _history;
    if (centerId != null) {
      items = items.where((item) => item.centerId == centerId);
    }
    if (createdByUid != null && createdByUid.isNotEmpty) {
      items = items.where((item) => item.createdByUid == createdByUid);
    } else if (createdByEmail != null && createdByEmail.isNotEmpty) {
      items = items.where((item) => item.createdByEmail == createdByEmail);
    }
    final result = items.toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(result);
  }

  static Set<int> scheduledBookedSeats({
    required String centerId,
    required DateTime startAt,
    required int durationHours,
  }) {
    _refreshDerivedState();
    final endAt = startAt.add(Duration(hours: durationHours));
    final result = <int>{};
    for (final item in _history) {
      if (item.isCanceled || item.centerId != centerId) continue;
      if (_hasOverlap(
        startA: startAt,
        endA: endAt,
        startB: item.startAt,
        endB: item.endAt,
      )) {
        result.addAll(item.seatIndexes);
      }
    }
    return result;
  }

  static Future<bool> cancelBooking(String bookingId) async {
    _refreshDerivedState();
    final index = _history.indexWhere((item) => item.id == bookingId);
    if (index == -1) return false;

    final target = _history[index];
    if (target.isCanceled) return false;

    final previous = target;
    selectedSeats(target.centerId).removeAll(target.seatIndexes);
    _history[index] = target.copyWith(
      isCanceled: true,
      canceledAt: DateTime.now(),
    );
    _refreshDerivedState();
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return true;
    }

    try {
      await _bookingsCollection
          .doc(bookingId)
          .set(_cloudMapForBooking(_history[index]));
      return true;
    } catch (error) {
      _history[index] = previous;
      _refreshDerivedState();
      await _saveToDisk();
      rethrow;
    }
  }

  static Future<bool> checkInBooking(String bookingId) async {
    _refreshDerivedState();
    final index = _history.indexWhere((item) => item.id == bookingId);
    if (index == -1) return false;
    final target = _history[index];
    if (target.isCanceled || target.isCheckedIn) return false;

    final previous = target;
    _history[index] = target.copyWith(checkedInAt: DateTime.now());
    _refreshDerivedState();
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return true;
    }

    try {
      await _bookingsCollection
          .doc(bookingId)
          .set(_cloudMapForBooking(_history[index]));
      return true;
    } catch (error) {
      _history[index] = previous;
      _refreshDerivedState();
      await _saveToDisk();
      rethrow;
    }
  }

  static Future<void> clearBookingsForCenters(Set<String> centerIds) async {
    if (centerIds.isEmpty) return;

    final removedBookings = _history
        .where((item) => centerIds.contains(item.centerId))
        .toList(growable: false);
    _history.removeWhere((item) => centerIds.contains(item.centerId));
    for (final centerId in centerIds) {
      selectedSeats(centerId).clear();
    }
    _refreshDerivedState();
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final booking in removedBookings) {
        batch.delete(_bookingsCollection.doc(booking.id));
      }
      await batch.commit();
    } catch (error) {
      _history.addAll(removedBookings);
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _refreshDerivedState();
      await _saveToDisk();
      rethrow;
    }
  }

  static Future<void> removeCenters(Set<String> centerIds) async {
    if (centerIds.isEmpty) return;

    final removedBookings = _history
        .where((item) => centerIds.contains(item.centerId))
        .toList(growable: false);
    final previousBlocked = <String, Set<int>>{
      for (final centerId in centerIds)
        centerId: Set<int>.from(_blockedByCenter[centerId] ?? const <int>{}),
    };

    _history.removeWhere((item) => centerIds.contains(item.centerId));
    for (final centerId in centerIds) {
      _selectedByCenter.remove(centerId);
      _bookedByCenter.remove(centerId);
      _blockedByCenter.remove(centerId);
      _emitBooked(centerId);
      _emitBlocked(centerId);
    }
    _refreshDerivedState();
    _emitAllBlocked();
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final booking in removedBookings) {
        batch.delete(_bookingsCollection.doc(booking.id));
      }
      for (final centerId in centerIds) {
        batch.delete(_blockedCollection.doc(centerId));
      }
      await batch.commit();
    } catch (error) {
      _history.addAll(removedBookings);
      for (final entry in previousBlocked.entries) {
        _blockedByCenter[entry.key] = entry.value;
      }
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _refreshDerivedState();
      _emitAllBlocked();
      await _saveToDisk();
      rethrow;
    }
  }

  static Future<void> removeBookingsByCreator({
    String? createdByUid,
    String? createdByEmail,
  }) async {
    final removed = _history
        .where((item) {
          if (createdByUid != null && createdByUid.isNotEmpty) {
            return item.createdByUid == createdByUid;
          }
          if (createdByEmail != null && createdByEmail.isNotEmpty) {
            return item.createdByEmail == createdByEmail;
          }
          return false;
        })
        .toList(growable: false);
    if (removed.isEmpty) return;

    _history.removeWhere((item) => removed.any((entry) => entry.id == item.id));
    _refreshDerivedState();
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final booking in removed) {
        batch.delete(_bookingsCollection.doc(booking.id));
      }
      await batch.commit();
    } catch (error) {
      _history.addAll(removed);
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _refreshDerivedState();
      await _saveToDisk();
      rethrow;
    }
  }

  static Future<void> clearCanceledBookingsForCenters(
    Set<String> centerIds,
  ) async {
    if (centerIds.isEmpty) return;

    final removed = _history
        .where((item) => item.isCanceled && centerIds.contains(item.centerId))
        .toList(growable: false);
    if (removed.isEmpty) return;

    _history.removeWhere(
      (item) => item.isCanceled && centerIds.contains(item.centerId),
    );
    _refreshDerivedState();
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final booking in removed) {
        batch.delete(_bookingsCollection.doc(booking.id));
      }
      await batch.commit();
    } catch (error) {
      _history.addAll(removed);
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _refreshDerivedState();
      await _saveToDisk();
      rethrow;
    }
  }

  static Future<void> clearCanceledBookings({
    String? createdByUid,
    String? createdByEmail,
  }) async {
    final removed = _history
        .where((item) {
          if (!item.isCanceled) return false;
          if (createdByUid != null && createdByUid.isNotEmpty) {
            return item.createdByUid == createdByUid;
          }
          if (createdByEmail != null && createdByEmail.isNotEmpty) {
            return item.createdByEmail == createdByEmail;
          }
          return false;
        })
        .toList(growable: false);
    if (removed.isEmpty) return;

    _history.removeWhere((item) => removed.any((entry) => entry.id == item.id));
    _refreshDerivedState();
    await _saveToDisk();

    if (!firebaseAvailable || FirebaseAuth.instance.currentUser == null) {
      return;
    }

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final booking in removed) {
        batch.delete(_bookingsCollection.doc(booking.id));
      }
      await batch.commit();
    } catch (error) {
      _history.addAll(removed);
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _refreshDerivedState();
      await _saveToDisk();
      rethrow;
    }
  }

  static Future<void> _writeBlockedSeatsToCloud(
    String centerId,
    Set<int> blockedSeats,
  ) async {
    await _blockedCollection.doc(centerId).set(<String, dynamic>{
      'centerId': centerId,
      'seatIndexes': blockedSeats.toList(growable: false)..sort(),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'updatedByUid': FirebaseAuth.instance.currentUser?.uid,
      'updatedByEmail': FirebaseAuth.instance.currentUser?.email,
    });
  }

  static Map<String, dynamic> _cloudMapForBooking(BookingRecord booking) {
    return <String, dynamic>{
      'id': booking.id,
      'centerId': booking.centerId,
      'centerName': booking.centerName,
      'customerName': booking.customerName,
      'phone': booking.phone,
      'durationHours': booking.durationHours,
      'pricePerHour': booking.pricePerHour,
      'totalPrice': booking.totalPrice,
      'seatIndexes': booking.seatIndexes,
      'startAt': booking.startAt.toUtc().toIso8601String(),
      'createdAt': booking.createdAt.toUtc().toIso8601String(),
      'createdByUid': booking.createdByUid,
      'createdByEmail': booking.createdByEmail,
      'isCanceled': booking.isCanceled,
      'canceledAt': booking.canceledAt?.toUtc().toIso8601String(),
      'graceMinutes': booking.graceMinutes,
      'checkedInAt': booking.checkedInAt?.toUtc().toIso8601String(),
      'noShowAt': booking.noShowAt?.toUtc().toIso8601String(),
    };
  }

  static CollectionReference<Map<String, dynamic>> get _bookingsCollection =>
      FirebaseFirestore.instance.collection(_bookingsCollectionName);

  static CollectionReference<Map<String, dynamic>> get _blockedCollection =>
      FirebaseFirestore.instance.collection(_blockedCollectionName);
}
