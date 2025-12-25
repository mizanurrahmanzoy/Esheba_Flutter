import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsageService {
  /// Free providers: max 2 services
  static Future<bool> canPostService() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final uid = user.uid;

    // 🔹 Load provider document
    final providerDoc = await FirebaseFirestore.instance
        .collection('providers')
        .doc(uid)
        .get();

    // ❌ Provider not registered properly
    if (!providerDoc.exists) {
      return false;
    }

    final data = providerDoc.data()!;

    // 🔹 Premium providers have unlimited posts
    final bool isPremium = data['isPremium'] ?? false;
    if (isPremium) return true;

    // 🔹 Count services posted by provider
    final servicesSnap = await FirebaseFirestore.instance
        .collection('services')
        .where('providerId', isEqualTo: uid)
        .get();

    return servicesSnap.size < 2;
  }

  /// Optional (can be empty for now)
  static Future<void> increasePostCount() async {
    // Not required if counting via services collection
  }
}
