import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProviderCache {
  static const _key = 'provider_profile';

  /// ✅ Save provider data safely
  static Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    final safeData = _serialize(data);

    await prefs.setString(_key, jsonEncode(safeData));
  }

  /// ✅ Load provider data
  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_key);
    if (raw == null) return null;

    final decoded = jsonDecode(raw);

    return _deserialize(decoded);
  }

  /// ❌ Convert Timestamp → int
  static Map<String, dynamic> _serialize(
      Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    map.forEach((key, value) {
      if (value is Timestamp) {
        map[key] = value.millisecondsSinceEpoch;
      }
    });

    return map;
  }

  /// 🔁 Convert int → DateTime (optional)
  static Map<String, dynamic> _deserialize(
      Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    map.forEach((key, value) {
      if (key == 'createdAt' && value is int) {
        map[key] = DateTime.fromMillisecondsSinceEpoch(value);
      }
    });

    return map;
  }

  /// 🧹 Clear cache
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
