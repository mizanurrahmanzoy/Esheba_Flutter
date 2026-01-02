import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCache {
  static Future<void> save(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(key, jsonEncode(value));
  }

  static Future<dynamic> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(key);
    return data != null ? jsonDecode(data) : null;
  }
}
