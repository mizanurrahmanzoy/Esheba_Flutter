import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsageService {
  static Future<bool> canPostService() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(uid);
    final userSnap = await userRef.get();

    final data = userSnap.data()!;
    final bool isPremium = data['isPremium'] ?? false;
    final int postCount = data['servicePostCount'] ?? 0;

    if (isPremium) return true;
    return postCount < 2; // free limit
  }

  static Future<void> increasePostCount() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'servicePostCount': FieldValue.increment(1),
    });
  }
}
