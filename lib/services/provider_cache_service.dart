import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProviderCacheService {
  static const _key = 'provider_profile';

  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> get() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
