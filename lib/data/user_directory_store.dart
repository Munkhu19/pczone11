import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_state.dart';
import 'role_store.dart';

class UserDirectoryStore {
  static const String _usersKey = 'app_users_v2';
  static const String _collectionName = 'user_directory';

  static Set<String>? _cachedUsers;

  static Future<Set<String>> _loadUsersFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return <String>{};

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <String>{};

    return decoded
        .whereType<Object>()
        .map((e) => e.toString().trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static Future<void> _saveUsersToDisk(Set<String> users) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = users.toList(growable: false)..sort();
    await prefs.setString(_usersKey, jsonEncode(sorted));
  }

  static Future<Set<String>> _users() async {
    return _cachedUsers ??= await _loadUsersFromDisk();
  }

  static String? _normalizeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static Future<void> _persist(Set<String> users) async {
    _cachedUsers = users;
    await _saveUsersToDisk(users);
  }

  static Future<void> register(String? email) async {
    final user = firebaseAvailable ? FirebaseAuth.instance.currentUser : null;
    final normalizedEmail = _normalizeEmail(user?.email ?? email);
    if (normalizedEmail == null) return;

    final users = Set<String>.from(await _users())..add(normalizedEmail);
    await _persist(users);

    if (!firebaseAvailable || user == null) return;

    await _collection.doc(normalizedEmail).set(<String, dynamic>{
      'email': normalizedEmail,
      'uid': user.uid,
      'displayName': user.displayName,
      'photoUrl': user.photoURL,
      'lastSeenAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }

  static Future<void> remove(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return;

    final users = Set<String>.from(await _users())..remove(normalizedEmail);
    await _persist(users);

    if (!firebaseAvailable) return;
    await _collection.doc(normalizedEmail).delete();
  }

  static Future<Set<String>> all() async {
    final cached = Set<String>.from(await _users());
    if (!firebaseAvailable ||
        !RoleStore.isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      return cached;
    }

    try {
      final snapshot = await _collection.get().timeout(const Duration(seconds: 8));
      final users = snapshot.docs
          .map((doc) => _normalizeEmail(doc.data()['email']?.toString() ?? doc.id))
          .whereType<String>()
          .toSet();
      await _persist(users);
      return users;
    } on FirebaseException catch (error) {
      debugPrint(
        'UserDirectoryStore.all failed: ${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('UserDirectoryStore.all failed: $error');
    }

    return cached;
  }

  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(_collectionName);
}
