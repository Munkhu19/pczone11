import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/center.dart';
import 'centers.dart';
import 'firebase_state.dart';

class CenterCloudSyncException implements Exception {
  const CenterCloudSyncException(
    this.message, {
    this.savedLocally = false,
  });

  final String message;
  final bool savedLocally;

  @override
  String toString() => message;
}

class CenterStore {
  static const String _centersKey = 'centers_v2';
  static const String _dirtyCenterIdsKey = 'centers_dirty_v1';
  static const String _collectionName = 'centers';
  static const Duration _cloudWriteTimeout = Duration(seconds: 12);
  static const Set<String> _removedLegacyCenterIds = {'awp', 'pro'};

  static final ValueNotifier<List<EsportCenter>> centersNotifier =
      ValueNotifier<List<EsportCenter>>(
        List<EsportCenter>.unmodifiable(seedCenters),
      );

  static bool _initialized = false;
  static final Set<String> _dirtyCenterIds = <String>{};
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _cloudSubscription;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final localCenters = await _loadLocalCenters();
    await _loadDirtyCenterIds();
    await _pruneDirtyCenterIds(localCenters.map((center) => center.id));
    centersNotifier.value = List<EsportCenter>.unmodifiable(localCenters);

    if (!firebaseAvailable) return;

    unawaited(_initializeCloud(localCenters));
  }

  static Future<void> _initializeCloud(List<EsportCenter> localCenters) async {
    try {
      final remoteCenters = await _loadRemoteCenters();
      final merged = _mergeCenters(
        localCenters: localCenters,
        remoteCenters: remoteCenters,
      );

      await _persistLocalWithFallback(merged);
      centersNotifier.value = List<EsportCenter>.unmodifiable(merged);
      await _syncMergedCentersToCloud(
        merged: merged,
        remoteCenters: remoteCenters,
      );
      _startCloudSync();
    } catch (error, stackTrace) {
      debugPrint('CenterStore.initialize cloud sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      centersNotifier.value = List<EsportCenter>.unmodifiable(localCenters);
    }
  }

  static List<EsportCenter> all() => centersNotifier.value;

  static List<EsportCenter> ownedBy(String? ownerEmail) {
    final normalizedOwnerEmail = _normalizeOwnerEmail(ownerEmail);
    if (normalizedOwnerEmail == null) return const <EsportCenter>[];
    return centersNotifier.value
        .where(
          (center) => _normalizeOwnerEmail(center.ownerEmail) == normalizedOwnerEmail,
        )
        .toList(growable: false);
  }

  static Future<void> addCenter(EsportCenter center) async {
    final previous = List<EsportCenter>.from(centersNotifier.value);
    final next = [...previous, center];
    await _applyLocalCenters(next);
    if (_shouldSyncToCloud(center)) {
      await _markCenterDirty(center.id);
    }

    if (!firebaseAvailable || !_shouldSyncToCloud(center)) {
      return;
    }

    try {
      await _collection
          .doc(center.id)
          .set(_cloudMapFor(center))
          .timeout(_cloudWriteTimeout);
      await _markCenterClean(center.id);
    } catch (error, stackTrace) {
      debugPrint('CenterStore.addCenter cloud sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _throwCloudSyncException(error, savedLocally: true);
    }
  }

  static Future<void> updateCenter(EsportCenter center) async {
    final previous = List<EsportCenter>.from(centersNotifier.value);
    final next = previous
        .map((item) => item.id == center.id ? center : item)
        .toList(growable: false);
    await _applyLocalCenters(next);
    if (_shouldSyncToCloud(center)) {
      await _markCenterDirty(center.id);
    }

    if (!firebaseAvailable || !_shouldSyncToCloud(center)) {
      return;
    }

    try {
      await _collection
          .doc(center.id)
          .set(_cloudMapFor(center))
          .timeout(_cloudWriteTimeout);
      await _markCenterClean(center.id);
    } catch (error, stackTrace) {
      debugPrint('CenterStore.updateCenter cloud sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _throwCloudSyncException(error, savedLocally: true);
    }
  }

  static Future<void> deleteCenter(String centerId) async {
    final previous = List<EsportCenter>.from(centersNotifier.value);
    final wasDirty = _dirtyCenterIds.contains(centerId);
    final removed = previous.where((item) => item.id == centerId).toList(growable: false);
    final next = previous
        .where((item) => item.id != centerId)
        .toList(growable: false);
    await _applyLocalCenters(next);
    await _markCenterClean(centerId);
    final shouldDeleteCloud = removed.any(_shouldSyncToCloud);
    if (!firebaseAvailable || !shouldDeleteCloud) return;

    try {
      await _collection.doc(centerId).delete();
    } catch (error, stackTrace) {
      debugPrint('CenterStore.deleteCenter cloud sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _applyLocalCenters(previous);
      if (wasDirty) {
        await _markCenterDirty(centerId);
      }
      _throwCloudSyncException(error);
    }
  }

  static Future<void> deleteCenters(Set<String> centerIds) async {
    if (centerIds.isEmpty) return;
    final previous = List<EsportCenter>.from(centersNotifier.value);
    final dirtyBeforeDelete = centerIds
        .where(_dirtyCenterIds.contains)
        .toSet();
    final removed = previous
        .where((item) => centerIds.contains(item.id))
        .toList(growable: false);
    final next = previous
        .where((item) => !centerIds.contains(item.id))
        .toList(growable: false);
    await _applyLocalCenters(next);
    await _markCentersClean(centerIds);
    final cloudIds = removed.where(_shouldSyncToCloud).map((e) => e.id).toSet();
    if (!firebaseAvailable || cloudIds.isEmpty) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final centerId in cloudIds) {
        batch.delete(_collection.doc(centerId));
      }
      await batch.commit();
    } catch (error, stackTrace) {
      debugPrint('CenterStore.deleteCenters cloud sync failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      await _applyLocalCenters(previous);
      for (final centerId in dirtyBeforeDelete) {
        await _markCenterDirty(centerId);
      }
      _throwCloudSyncException(error);
    }
  }

  static Future<List<EsportCenter>> _loadLocalCenters() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_centersKey);
    if (raw == null || raw.isEmpty) {
      await _persistLocal(seedCenters);
      return seedCenters;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await _persistLocal(seedCenters);
        return seedCenters;
      }

      final loaded = decoded
          .whereType<Map>()
          .map((e) => EsportCenter.fromMap(Map<String, dynamic>.from(e)))
          .where((center) => center.id.isNotEmpty)
          .toList(growable: false);
      final migrated = _sanitizeCenters(loaded);
      if (migrated.isEmpty) {
        await _persistLocal(seedCenters);
        return seedCenters;
      }
      if (!_sameCenterSet(migrated, loaded)) {
        await _persistLocal(migrated);
      }
      return migrated;
    } catch (_) {
      await _persistLocal(seedCenters);
      return seedCenters;
    }
  }

  static Future<List<EsportCenter>> _loadRemoteCenters() async {
    final snapshot = await _collection.get().timeout(const Duration(seconds: 8));
    final loaded = snapshot.docs
        .map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = data['id']?.toString().isNotEmpty == true ? data['id'] : doc.id;
          return EsportCenter.fromMap(data);
        })
        .where((center) => center.id.isNotEmpty)
        .toList(growable: false);
    return _sanitizeCenters(loaded);
  }

  static void _startCloudSync() {
    _cloudSubscription?.cancel();
    _cloudSubscription = _collection.snapshots().listen((snapshot) async {
      final remoteCenters = _sanitizeCenters(
        snapshot.docs
            .map((doc) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] =
                  data['id']?.toString().isNotEmpty == true ? data['id'] : doc.id;
              return EsportCenter.fromMap(data);
            })
            .toList(growable: false),
      );

      if (remoteCenters.isEmpty) return;
      final merged = _mergeCenters(
        localCenters: centersNotifier.value,
        remoteCenters: remoteCenters,
      );
      await _persistLocalWithFallback(merged);
      centersNotifier.value = List<EsportCenter>.unmodifiable(merged);
    });
  }

  static Future<void> _persistLocal(List<EsportCenter> centers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _centersKey,
      jsonEncode(centers.map((e) => e.toMap()).toList()),
    );
  }

  static Future<void> _loadDirtyCenterIds() async {
    final prefs = await SharedPreferences.getInstance();
    final dirtyIds = prefs.getStringList(_dirtyCenterIdsKey) ?? const <String>[];
    _dirtyCenterIds
      ..clear()
      ..addAll(
        dirtyIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty),
      );
  }

  static Future<void> _persistDirtyCenterIds() async {
    final prefs = await SharedPreferences.getInstance();
    final dirtyIds = _dirtyCenterIds.toList(growable: false)..sort();
    await prefs.setStringList(_dirtyCenterIdsKey, dirtyIds);
  }

  static Future<void> _markCenterDirty(String centerId) async {
    final trimmed = centerId.trim();
    if (trimmed.isEmpty || !_dirtyCenterIds.add(trimmed)) {
      return;
    }
    await _persistDirtyCenterIds();
  }

  static Future<void> _markCenterClean(String centerId) async {
    final trimmed = centerId.trim();
    if (trimmed.isEmpty || !_dirtyCenterIds.remove(trimmed)) {
      return;
    }
    await _persistDirtyCenterIds();
  }

  static Future<void> _markCentersClean(Iterable<String> centerIds) async {
    var changed = false;
    for (final centerId in centerIds) {
      final trimmed = centerId.trim();
      if (trimmed.isEmpty) continue;
      if (_dirtyCenterIds.remove(trimmed)) {
        changed = true;
      }
    }
    if (changed) {
      await _persistDirtyCenterIds();
    }
  }

  static Future<void> _pruneDirtyCenterIds(Iterable<String> validCenterIds) async {
    final validIds = validCenterIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final before = _dirtyCenterIds.length;
    _dirtyCenterIds.removeWhere((centerId) => !validIds.contains(centerId));
    if (_dirtyCenterIds.length != before) {
      await _persistDirtyCenterIds();
    }
  }

  static Future<void> _applyLocalCenters(List<EsportCenter> centers) async {
    final sanitized = _sanitizeCenters(centers);
    await _persistLocalWithFallback(sanitized);
    centersNotifier.value = List<EsportCenter>.unmodifiable(sanitized);
  }

  static Future<void> _persistLocalWithFallback(List<EsportCenter> centers) async {
    try {
      await _persistLocal(centers);
      return;
    } catch (error, stackTrace) {
      debugPrint('CenterStore._persistLocal full payload failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    final withoutGallery = centers
        .map(
          (center) => center.copyWith(
            imagesBase64: const <String>[],
          ),
        )
        .toList(growable: false);
    try {
      await _persistLocal(withoutGallery);
      debugPrint(
        'CenterStore._persistLocal retried without gallery images to avoid local storage limits.',
      );
      return;
    } catch (error, stackTrace) {
      debugPrint('CenterStore._persistLocal without gallery failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    final metadataOnly = centers
        .map(
          (center) => center.copyWith(
            profileImageBase64: null,
            imagesBase64: const <String>[],
          ),
        )
        .toList(growable: false);
    await _persistLocal(metadataOnly);
    debugPrint(
      'CenterStore._persistLocal saved metadata only because local storage quota was reached.',
    );
  }

  static Future<void> _syncMergedCentersToCloud({
    required List<EsportCenter> merged,
    required List<EsportCenter> remoteCenters,
  }) async {
    final signedInOwner = _normalizeOwnerEmail(_currentSignedInEmail());
    final mergedCloud = merged
        .where(
          (center) =>
              _shouldSyncToCloud(center) &&
              (signedInOwner == null ||
                  _normalizeOwnerEmail(center.ownerEmail) == signedInOwner),
        )
        .toList(growable: false);
    final remoteCloud = remoteCenters
        .where(
          (center) =>
              _shouldSyncToCloud(center) &&
              (signedInOwner == null ||
                  _normalizeOwnerEmail(center.ownerEmail) == signedInOwner),
        )
        .toList(growable: false);
    if (_sameCenterSet(mergedCloud, remoteCloud)) {
      await _markCentersClean(mergedCloud.map((center) => center.id));
      return;
    }

    final remoteIds = remoteCloud.map((e) => e.id).toSet();
    final mergedIds = mergedCloud.map((e) => e.id).toSet();
    final removedIds = remoteIds.difference(mergedIds);

    for (final center in mergedCloud) {
      try {
        await _collection.doc(center.id).set(_cloudMapFor(center));
        await _markCenterClean(center.id);
      } catch (error, stackTrace) {
        debugPrint(
          'CenterStore._syncMergedCentersToCloud failed for ${center.id}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    for (final centerId in removedIds) {
      try {
        await _collection.doc(centerId).delete();
        await _markCenterClean(centerId);
      } catch (error, stackTrace) {
        debugPrint(
          'CenterStore._syncMergedCentersToCloud delete failed for $centerId: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  static List<EsportCenter> _mergeCenters({
    required List<EsportCenter> localCenters,
    required List<EsportCenter> remoteCenters,
  }) {
    final merged = <String, EsportCenter>{
      for (final center in remoteCenters) center.id: center,
    };

    for (final center in localCenters) {
      final existing = merged[center.id];
      merged[center.id] = existing == null
          ? center
          : _preferLocalIfLikelyUserData(local: center, remote: existing);
    }

    return merged.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  static EsportCenter _preferLocalIfLikelyUserData({
    required EsportCenter local,
    required EsportCenter remote,
  }) {
    return _mergeLocalAndRemote(
      local: local,
      remote: remote,
      localDirty: _dirtyCenterIds.contains(local.id),
    );
  }

  @visibleForTesting
  static EsportCenter mergeCentersForTesting({
    required EsportCenter local,
    required EsportCenter remote,
    bool localDirty = false,
  }) {
    return _mergeLocalAndRemote(
      local: local,
      remote: remote,
      localDirty: localDirty,
    );
  }

  static EsportCenter _mergeLocalAndRemote({
    required EsportCenter local,
    required EsportCenter remote,
    required bool localDirty,
  }) {
    final localLooksCustom = local.ownerEmail != null && local.ownerEmail!.isNotEmpty;
    final remoteLooksSeed = seedCenters.any((seed) => seed.id == remote.id);
    if (localDirty || (localLooksCustom && remoteLooksSeed)) {
      return local;
    }

    return remote.copyWith(
      profileImageBase64: _mergedProfileImage(local: local, remote: remote),
      imagesBase64: remote.imagesBase64.isNotEmpty ? remote.imagesBase64 : local.imagesBase64,
    );
  }

  static String? _mergedProfileImage({
    required EsportCenter local,
    required EsportCenter remote,
  }) {
    final remoteImage = remote.profileImageBase64?.trim();
    if (remoteImage != null && remoteImage.isNotEmpty) {
      return remoteImage;
    }

    final localImage = local.profileImageBase64?.trim();
    if (localImage == null || localImage.isEmpty) {
      return null;
    }
    return localImage;
  }

  static List<EsportCenter> _sanitizeCenters(List<EsportCenter> centers) {
    final migrated = centers
        .map(_mergeSeedMetadataIfNeeded)
        .where((center) => !_isRemovedLegacyCenter(center))
        .where((center) => center.id.isNotEmpty)
        .toList(growable: false);
    if (migrated.isEmpty) {
      return List<EsportCenter>.unmodifiable(seedCenters);
    }
    return migrated;
  }

  static bool _isRemovedLegacyCenter(EsportCenter center) {
    final normalizedName = center.name.toLowerCase().replaceAll(' ', '');
    final normalizedId = center.id.toLowerCase().replaceAll(' ', '');
    final hasOwner = center.ownerEmail != null && center.ownerEmail!.isNotEmpty;
    if (_removedLegacyCenterIds.contains(normalizedId)) return true;
    return !hasOwner &&
        normalizedName == 'uniongaming' &&
        normalizedId == 'uniongaming';
  }

  static String? _normalizeOwnerEmail(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static bool _shouldSyncToCloud(EsportCenter center) {
    final owner = _normalizeOwnerEmail(center.ownerEmail);
    return owner != null && owner.isNotEmpty;
  }

  static String? _currentSignedInEmail() {
    final email = FirebaseAuth.instance.currentUser?.email?.trim();
    if (email == null || email.isEmpty) return null;
    return email;
  }

  static String? _resolvedCloudOwnerEmail(EsportCenter center) {
    final ownerEmail = center.ownerEmail?.trim();
    if (ownerEmail == null || ownerEmail.isEmpty) return null;

    final signedInEmail = _currentSignedInEmail();
    if (signedInEmail == null) return ownerEmail;

    final normalizedOwner = _normalizeOwnerEmail(ownerEmail);
    final normalizedSignedIn = _normalizeOwnerEmail(signedInEmail);
    if (normalizedOwner == normalizedSignedIn) {
      return signedInEmail;
    }
    return ownerEmail;
  }

  static Never _throwCloudSyncException(
    Object error, {
    bool savedLocally = false,
  }) {
    if (error is FirebaseException) {
      throw CenterCloudSyncException(
        'Cloud sync failed: ${error.code}${error.message == null ? '' : ' - ${error.message}'}',
        savedLocally: savedLocally,
      );
    }
    throw CenterCloudSyncException(
      'Cloud sync failed: $error',
      savedLocally: savedLocally,
    );
  }

  static EsportCenter _mergeSeedMetadataIfNeeded(EsportCenter center) {
    final seed = seedCenters.cast<EsportCenter?>().firstWhere(
          (item) => item?.id == center.id,
          orElse: () => null,
        );
    if (seed == null) return center;

    final hasDefaultRating = center.rating == 4.7;
    final hasDefaultReviewCount = center.reviewCount == 24;
    final hasDefaultSnippet =
        center.reviewSnippet == 'Players like the setup and atmosphere.';

    if (!hasDefaultRating && !hasDefaultReviewCount && !hasDefaultSnippet) {
      return center;
    }

    return center.copyWith(
      rating: hasDefaultRating ? seed.rating : center.rating,
      reviewCount: hasDefaultReviewCount ? seed.reviewCount : center.reviewCount,
      reviewSnippet:
          hasDefaultSnippet ? seed.reviewSnippet : center.reviewSnippet,
    );
  }

  static bool _sameCenterSet(List<EsportCenter> a, List<EsportCenter> b) {
    if (a.length != b.length) return false;
    final encodedA = (a.map((e) => e.toMap()).toList()..sort(_compareMaps))
        .map(jsonEncode)
        .toList(growable: false);
    final encodedB = (b.map((e) => e.toMap()).toList()..sort(_compareMaps))
        .map(jsonEncode)
        .toList(growable: false);
    return listEquals(encodedA, encodedB);
  }

  static int _compareMaps(Map<String, dynamic> a, Map<String, dynamic> b) {
    return (a['id']?.toString() ?? '').compareTo(b['id']?.toString() ?? '');
  }

  static Map<String, dynamic> _cloudMapFor(EsportCenter center) {
    final data = Map<String, dynamic>.from(center.toMap());
    final ownerEmail = _resolvedCloudOwnerEmail(center);
    final profileImage = center.profileImageBase64;
    final galleryImages = center.imagesBase64
        .where(_isCloudImageReference)
        .toList(growable: false);

    if (ownerEmail != null && ownerEmail.isNotEmpty) {
      data['ownerEmail'] = ownerEmail;
    } else {
      data.remove('ownerEmail');
    }

    if (profileImage != null && _isCloudImageReference(profileImage)) {
      data['profileImageBase64'] = profileImage;
    } else {
      data.remove('profileImageBase64');
    }

    if (galleryImages.isNotEmpty) {
      data['imagesBase64'] = galleryImages;
    } else {
      data.remove('imagesBase64');
    }
    return data;
  }

  static bool _isCloudImageReference(String value) {
    return value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('gs://') ||
        value.startsWith('centers/');
  }

  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(_collectionName);
}
