import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/owner_application.dart';
import 'firebase_state.dart';
import 'role_store.dart';

class OwnerApplicationStore {
  static const String _applicationsKey = 'owner_applications_v2';
  static const String _collectionName = 'owner_applications';

  static Map<String, OwnerApplication>? _cachedApplications;

  static Future<Map<String, OwnerApplication>> _loadApplicationsFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_applicationsKey);
    if (raw == null || raw.isEmpty) return <String, OwnerApplication>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, OwnerApplication>{};

    final applications = <String, OwnerApplication>{};
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        applications[entry.key] = OwnerApplication.fromJson(value);
      } else if (value is Map) {
        applications[entry.key] = OwnerApplication.fromJson(
          value.map((key, item) => MapEntry(key.toString(), item)),
        );
      }
    }
    return applications;
  }

  static Future<void> _saveApplicationsToDisk(
    Map<String, OwnerApplication> applications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = applications.map(
      (key, value) => MapEntry(key, value.toJson()),
    );
    await prefs.setString(_applicationsKey, jsonEncode(encoded));
  }

  static Future<Map<String, OwnerApplication>> _applications() async {
    return _cachedApplications ??= await _loadApplicationsFromDisk();
  }

  static String? _normalizeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static Future<void> _persist(
    Map<String, OwnerApplication> applications,
  ) async {
    _cachedApplications = applications;
    await _saveApplicationsToDisk(applications);
  }

  static Future<void> saveApplication(OwnerApplication application) async {
    final normalizedEmail = _normalizeEmail(application.email);
    if (normalizedEmail == null) return;

    final applications = Map<String, OwnerApplication>.from(await _applications());
    final normalizedApplication = OwnerApplication(
      email: normalizedEmail,
      centerName: application.centerName,
      phone: application.phone,
      address: application.address,
      contactLink: application.contactLink,
      note: application.note,
      requestedAt: application.requestedAt,
    );
    applications[normalizedEmail] = normalizedApplication;
    await _persist(applications);

    if (!firebaseAvailable) return;
    await _collection.doc(normalizedEmail).set(normalizedApplication.toJson());
  }

  static Future<OwnerApplication?> applicationForEmail(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return null;

    final cached = (await _applications())[normalizedEmail];
    if (firebaseAvailable) {
      final currentEmail = _normalizeEmail(FirebaseAuth.instance.currentUser?.email);
      if (currentEmail == normalizedEmail || RoleStore.isAdminEmail(currentEmail)) {
        try {
          final snapshot = await _collection.doc(normalizedEmail).get().timeout(
            const Duration(seconds: 8),
          );
          final data = snapshot.data();
          if (data != null) {
            final application = OwnerApplication.fromJson(data);
            final applications = Map<String, OwnerApplication>.from(
              await _applications(),
            );
            applications[normalizedEmail] = application;
            await _persist(applications);
            return application;
          }
        } on FirebaseException catch (error) {
          debugPrint(
            'OwnerApplicationStore.applicationForEmail failed: ${error.code} ${error.message}',
          );
        } catch (error) {
          debugPrint('OwnerApplicationStore.applicationForEmail failed: $error');
        }
      }
    }

    return cached;
  }

  static Future<Map<String, OwnerApplication>> allApplications() async {
    final cached = Map<String, OwnerApplication>.from(await _applications());
    if (!firebaseAvailable ||
        !RoleStore.isAdminEmail(FirebaseAuth.instance.currentUser?.email)) {
      return cached;
    }

    try {
      final snapshot = await _collection.get().timeout(const Duration(seconds: 8));
      final applications = <String, OwnerApplication>{};
      for (final doc in snapshot.docs) {
        applications[doc.id] = OwnerApplication.fromJson(doc.data());
      }
      await _persist(applications);
      return applications;
    } on FirebaseException catch (error) {
      debugPrint(
        'OwnerApplicationStore.allApplications failed: ${error.code} ${error.message}',
      );
    } catch (error) {
      debugPrint('OwnerApplicationStore.allApplications failed: $error');
    }

    return cached;
  }

  static Future<void> removeApplication(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail == null) return;

    final applications = Map<String, OwnerApplication>.from(await _applications())
      ..remove(normalizedEmail);
    await _persist(applications);

    if (!firebaseAvailable) return;
    await _collection.doc(normalizedEmail).delete();
  }

  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection(_collectionName);
}
