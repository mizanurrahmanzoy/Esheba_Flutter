import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const String _cacheKey = 'cached_categories';

  /// Fetch categories from Firestore and cache locally
  static Future<List<String>> fetchAndCacheCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    final categories =
        snapshot.docs.map((d) => d['name'] as String).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(categories));

    return categories;
  }

  /// Load categories from local cache
  static Future<List<String>> loadCachedCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);

    if (cached == null) return [];

    final List list = jsonDecode(cached);
    return list.cast<String>();
  }

  /// Get categories (cache-first strategy)
  static Future<List<String>> getCategories() async {
    final cached = await loadCachedCategories();

    if (cached.isNotEmpty) {
      // refresh silently in background
      fetchAndCacheCategories();
      return cached;
    }

    return await fetchAndCacheCategories();
  }
}
