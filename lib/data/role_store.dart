import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_state.dart';

class RoleStore {
  static const String _rolesKey = 'user_roles_v2';
  static const String _collectionName = 'user_roles';
  static const String customerRole = 'customer';
  static const String adminRole = 'admin';
  static const String ownerPendingRole = 'owner_pending';
  static const String ownerRole = 'owner';
  static final ValueNotifier<int> rolesRevision = ValueNotifier<int>(0);
  static const Set<String> _adminEmails = <String>{
    'batsaikhanbatmunkh88@gmail.com',
  };

  static Map<String, String>? _cachedRoles;
  static bool _initialized = false;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _adminRolesSubscription;
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _selfRoleSubscription;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _cachedRoles = await _loadRolesFromDisk();
    _ensureAdminRoles();
    if (!firebaseAvailable) return;

    FirebaseAuth.instance.authStateChanges().listen((_) {
      unawaited(_refreshCloudSubscription());
    });
    await _refreshCloudSubscription();
  }

  static Future<Map<String, String>> _loadRolesFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rolesKey);
    if (raw == null || raw.isEmpty) return <String, String>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, String>{};
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  static Future<void> _saveRolesToDisk(Map<String, String> roles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_rolesKey, jsonEncode(roles));
  }

  static Map<String, String> _roles() {
    return _cachedRoles ??= <String, String>{};
  }

  static void _ensureAdminRoles([Map<String, String>? target]) {
    final roles = target ?? _roles();
    for (final email in _adminEmails) {
      roles[email] = adminRole;
    }
  }

  static String? _normalizeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static Future<void> _refreshCloudSubscription() async {
    await _adminRolesSubscription?.cancel();
    await _selfRoleSubscription?.cancel();
    _adminRolesSubscription = null;
    _selfRoleSubscription = null;

    final currentEmail = _normalizeEmail(FirebaseAuth.instance.currentUser?.email);
    if (currentEmail == null) return;

    if (isAdminEmail(currentEmail)) {
      _adminRolesSubscription = _collection.snapshots().listen((snapshot) {
        final nextRoles = <String, String>{};
        for (final doc in snapshot.docs) {
          final role = _roleFromData(doc.data());
          final email = _normalizeEmail(doc.data()['email']?.toString() ?? doc.id);
          if (email == null || role == null || role.isEmpty) continue;
          nextRoles[email] = role;
        }
        unawaited(_replaceCloudRoles(nextRoles));
      });
      await _refreshAllRolesFromCloud();
      return;
    }

    _selfRoleSubscription = _collection.doc(currentEmail).snapshots().listen((doc) {
      unawaited(_applySelfRoleSnapshot(currentEmail, doc.data()));
    });
    await _refreshRoleFromCloud(currentEmail);
  }

  static String? _roleFromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    final role = data['role']?.toString().trim();
    if (role == null || role.isEmpty) return null;
    return role;
  }

  static Future<void> _replaceCloudRoles(Map<String, String> cloudRoles) async {
    final nextRoles = <String, String>{
      for (final entry in _roles().entries)
        if (isAdminEmail(entry.key)) entry.key: entry.value,
    };
    nextRoles.addAll(cloudRoles);
    _ensureAdminRoles(nextRoles);
    await _setCachedRoles(nextRoles);
  }

  static Future<void> _applySelfRoleSnapshot(
    String email,
    Map<String, dynamic>? data,
  ) async {
    final nextRoles = Map<String, String>.from(_roles());
    final role = _roleFromData(data);
    if (role == null) {
      nextRoles.remove(email);
    } else {
      nextRoles[email] = role;
    }
    _ensureAdminRoles(nextRoles);
    await _setCachedRoles(nextRoles);
  }

  static Future<void> _setCachedRoles(Map<String, String> roles) async {
    final currentEncoded = jsonEncode(_roles());
    final nextEncoded = jsonEncode(roles);
    _cachedRoles = roles;
    await _saveRolesToDisk(roles);
    if (currentEncoded != nextEncoded) {
      rolesRevision.value++;
    }
  }

  static Future<void> saveRole({
    required String email,
    required String role,
  }) async {
    await initialize();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return;

    final nextRoles = Map<String, String>.from(_roles())
      ..[normalizedEmail] = isAdminEmail(normalizedEmail) ? adminRole : role;
    _ensureAdminRoles(nextRoles);
    await _setCachedRoles(nextRoles);

    if (!firebaseAvailable || isAdminEmail(normalizedEmail)) return;

    await _collection.doc(normalizedEmail).set(<String, dynamic>{
      'email': normalizedEmail,
      'role': role,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  static Future<void> removeRole(String email) async {
    await initialize();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null || isAdminEmail(normalizedEmail)) return;

    final nextRoles = Map<String, String>.from(_roles())..remove(normalizedEmail);
    _ensureAdminRoles(nextRoles);
    await _setCachedRoles(nextRoles);

    if (!firebaseAvailable) return;
    await _collection.doc(normalizedEmail).delete();
  }

  static Future<String> roleForEmail(String? email) async {
    await initialize();
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return customerRole;
    if (isAdminEmail(normalizedEmail)) return adminRole;

    final cachedRole = _roles()[normalizedEmail];
    if (cachedRole != null && cachedRole.isNotEmpty) {
      return cachedRole;
    }

    final fetchedRole = await _refreshRoleFromCloud(normalizedEmail);
    if (fetchedRole != null && fetchedRole.isNotEmpty) {
      return fetchedRole;
    }

    final inferredRole = await _inferRoleFromCloud(normalizedEmail);
    if (inferredRole != null) {
      await saveRole(email: normalizedEmail, role: inferredRole);
      return inferredRole;
    }

    return customerRole;
  }

  static bool isAdminEmail(String? email) {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return false;
    return _adminEmails.contains(normalizedEmail);
  }

  static Future<List<MapEntry<String, String>>> pendingOwnerRequests() async {
    await initialize();
    if (firebaseAvailable && isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      await _refreshAllRolesFromCloud(roleFilter: ownerPendingRole);
    }

    return _roles().entries
        .where((entry) => entry.value == ownerPendingRole)
        .toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  static Future<Map<String, String>> allRoles() async {
    await initialize();
    if (firebaseAvailable && isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      await _refreshAllRolesFromCloud();
    }
    final roles = Map<String, String>.from(_roles());
    _ensureAdminRoles(roles);
    return roles;
  }

  static Future<String?> _refreshRoleFromCloud(String email) async {
    if (!firebaseAvailable) return null;

    try {
      final snapshot = await _collection.doc(email).get().timeout(
        const Duration(seconds: 8),
      );
      final role = _roleFromData(snapshot.data());
      final nextRoles = Map<String, String>.from(_roles());
      if (role == null) {
        nextRoles.remove(email);
      } else {
        nextRoles[email] = role;
      }
      _ensureAdminRoles(nextRoles);
      await _setCachedRoles(nextRoles);
      return role;
    } on FirebaseException catch (error) {
      debugPrint(
        'RoleStore._refreshRoleFromCloud failed: ${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('RoleStore._refreshRoleFromCloud failed: $error');
    }

    return null;
  }

  static Future<void> _refreshAllRolesFromCloud({
    String? roleFilter,
  }) async {
    if (!firebaseAvailable) return;

    try {
      Query<Map<String, dynamic>> query = _collection;
      if (roleFilter != null) {
        query = query.where('role', isEqualTo: roleFilter);
      }
      final snapshot = await query.get().timeout(const Duration(seconds: 8));
      if (roleFilter == null) {
        final nextRoles = <String, String>{};
        for (final doc in snapshot.docs) {
          final email = _normalizeEmail(doc.data()['email']?.toString() ?? doc.id);
          final role = _roleFromData(doc.data());
          if (email == null || role == null || role.isEmpty) continue;
          nextRoles[email] = role;
        }
        await _replaceCloudRoles(nextRoles);
        return;
      }

      final nextRoles = Map<String, String>.from(_roles());
      nextRoles.removeWhere((_, existingRole) => existingRole == roleFilter);
      for (final doc in snapshot.docs) {
        final email = _normalizeEmail(doc.data()['email']?.toString() ?? doc.id);
        final role = _roleFromData(doc.data());
        if (email == null || role == null || role.isEmpty) continue;
        nextRoles[email] = role;
      }
      _ensureAdminRoles(nextRoles);
      await _setCachedRoles(nextRoles);
    } on FirebaseException catch (error) {
      debugPrint(
        'RoleStore._refreshAllRolesFromCloud failed: ${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('RoleStore._refreshAllRolesFromCloud failed: $error');
    }
  }

  static Future<String?> _inferRoleFromCloud(String email) async {
    if (!firebaseAvailable) return null;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('centers')
          .where('ownerEmail', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 8));
      if (snapshot.docs.isNotEmpty) {
        return ownerRole;
      }
    } on FirebaseException catch (error) {
      debugPrint(
        'RoleStore._inferRoleFromCloud failed: ${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('RoleStore._inferRoleFromCloud failed: $error');
    }

    return null;
  }

  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(_collectionName);
}
