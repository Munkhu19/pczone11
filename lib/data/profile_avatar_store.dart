import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatarStore {
  static const String _avatarPrefix = 'profile_avatar_';
  static const String _avatarUrlPrefix = 'profile_avatar_url_';

  static Future<Uint8List?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_avatarPrefix$uid');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      return base64Decode(raw);
    } catch (_) {
      await prefs.remove('$_avatarPrefix$uid');
      return null;
    }
  }

  static Future<void> save({
    required String uid,
    required Uint8List bytes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarPrefix$uid', base64Encode(bytes));
  }

  static Future<String?> loadPhotoUrl(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_avatarUrlPrefix$uid');
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw;
  }

  static Future<void> savePhotoUrl({
    required String uid,
    required String photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_avatarUrlPrefix$uid', photoUrl);
  }

  static Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_avatarPrefix$uid');
    await prefs.remove('$_avatarUrlPrefix$uid');
  }
}
