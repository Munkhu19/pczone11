import 'package:cloud_firestore/cloud_firestore.dart';

class BookingRecord {
  final String id;
  final String centerId;
  final String centerName;
  final String customerName;
  final String phone;
  final int durationHours;
  final int pricePerHour;
  final int totalPrice;
  final List<int> seatIndexes;
  final DateTime startAt;
  final DateTime createdAt;
  final String? createdByUid;
  final String? createdByEmail;
  final bool isCanceled;
  final DateTime? canceledAt;
  final int graceMinutes;
  final DateTime? checkedInAt;
  final DateTime? noShowAt;

  const BookingRecord({
    required this.id,
    required this.centerId,
    required this.centerName,
    required this.customerName,
    required this.phone,
    required this.durationHours,
    required this.pricePerHour,
    required this.totalPrice,
    required this.seatIndexes,
    required this.startAt,
    required this.createdAt,
    this.createdByUid,
    this.createdByEmail,
    this.isCanceled = false,
    this.canceledAt,
    this.graceMinutes = 15,
    this.checkedInAt,
    this.noShowAt,
  });

  DateTime get endAt => startAt.add(Duration(hours: durationHours));
  DateTime get noShowDeadline => startAt.add(Duration(minutes: graceMinutes));
  bool get isCheckedIn => checkedInAt != null;
  bool get isNoShow => noShowAt != null;

  String statusCodeAt(DateTime now) {
    if (isNoShow) return 'no_show';
    if (isCanceled) return 'canceled';
    if (!endAt.isAfter(now)) return 'completed';
    if (isCheckedIn) return 'checked_in';
    if (startAt.isAfter(now)) return 'upcoming';
    return 'active';
  }

  BookingRecord copyWith({
    bool? isCanceled,
    DateTime? canceledAt,
    int? graceMinutes,
    DateTime? checkedInAt,
    DateTime? noShowAt,
  }) {
    return BookingRecord(
      id: id,
      centerId: centerId,
      centerName: centerName,
      customerName: customerName,
      phone: phone,
      durationHours: durationHours,
      pricePerHour: pricePerHour,
      totalPrice: totalPrice,
      seatIndexes: seatIndexes,
      startAt: startAt,
      createdAt: createdAt,
      createdByUid: createdByUid,
      createdByEmail: createdByEmail,
      isCanceled: isCanceled ?? this.isCanceled,
      canceledAt: canceledAt ?? this.canceledAt,
      graceMinutes: graceMinutes ?? this.graceMinutes,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      noShowAt: noShowAt ?? this.noShowAt,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'centerId': centerId,
      'centerName': centerName,
      'customerName': customerName,
      'phone': phone,
      'durationHours': durationHours,
      'pricePerHour': pricePerHour,
      'totalPrice': totalPrice,
      'seatIndexes': seatIndexes,
      'startAt': startAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdByUid': createdByUid,
      'createdByEmail': createdByEmail,
      'isCanceled': isCanceled,
      'canceledAt': canceledAt?.toIso8601String(),
      'graceMinutes': graceMinutes,
      'checkedInAt': checkedInAt?.toIso8601String(),
      'noShowAt': noShowAt?.toIso8601String(),
    };
  }

  factory BookingRecord.fromMap(Map<String, dynamic> map) {
    final rawSeats = map['seatIndexes'];
    final seats = rawSeats is List
        ? rawSeats.map((e) => int.tryParse(e.toString()) ?? 0).toList()
        : <int>[];
    final parsedCreatedAt = _parseDateTime(map['createdAt']) ?? DateTime.now();
    final parsedStartAt = _parseDateTime(map['startAt']) ?? parsedCreatedAt;

    return BookingRecord(
      id: map['id']?.toString() ?? '',
      centerId: map['centerId']?.toString() ?? '',
      centerName: map['centerName']?.toString() ?? '',
      customerName: map['customerName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      durationHours: int.tryParse(map['durationHours'].toString()) ?? 0,
      pricePerHour: int.tryParse(map['pricePerHour'].toString()) ?? 0,
      totalPrice: int.tryParse(map['totalPrice'].toString()) ?? 0,
      seatIndexes: seats,
      startAt: parsedStartAt,
      createdAt: parsedCreatedAt,
      createdByUid: map['createdByUid']?.toString(),
      createdByEmail: map['createdByEmail']?.toString(),
      isCanceled: map['isCanceled'] == true,
      canceledAt: _parseDateTime(map['canceledAt']),
      graceMinutes: int.tryParse(map['graceMinutes'].toString()) ?? 15,
      checkedInAt: _parseDateTime(map['checkedInAt']),
      noShowAt: _parseDateTime(map['noShowAt']),
    );
  }
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) return null;
  if (value is Timestamp) {
    return value.toDate();
  }
  return DateTime.tryParse(value.toString());
}
