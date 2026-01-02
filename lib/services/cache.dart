
import 'package:hive_flutter/hive_flutter.dart';

class LocalCache {
  static Future init() async {
    await Hive.initFlutter();
    await Hive.openBox('cache');
  }

  static Future save(String key, dynamic value) async {
    Hive.box('cache').put(key, value);
  }

  static dynamic get(String key) {
    return Hive.box('cache').get(key);
  }
}
