import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AuthStore {
  static const String _usersKey = 'users_v1';

  static Future<Map<String, String>> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return <String, String>{};

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return <String, String>{};

    return decoded.map(
      (key, value) => MapEntry(key, value.toString()),
    );
  }

  static Future<void> _saveUsers(Map<String, String> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(users));
  }

  static Future<bool> register({
    required String username,
    required String password,
  }) async {
    final users = await _loadUsers();
    if (users.containsKey(username)) return false;

    users[username] = password;
    await _saveUsers(users);
    return true;
  }

  static Future<bool> login({
    required String username,
    required String password,
  }) async {
    final users = await _loadUsers();
    return users[username] == password;
  }
}
