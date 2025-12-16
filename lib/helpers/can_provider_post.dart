import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<bool> canProviderPost() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  // Fetch provider account data
  final userDoc = await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .get();

  if (!userDoc.exists) return false;

  final data = userDoc.data()!;
  final bool isPremium = data["isPremium"] ?? false;
  final Timestamp? expiry = data["premiumExpiry"];

  // PREMIUM USER → unlimited
  if (isPremium && expiry != null) {
    if (expiry.toDate().isAfter(DateTime.now())) {
      return true;
    } else {
      // Premium expired → reset
      await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .update({"isPremium": false, "premiumExpiry": null});
    }
  }

  // FREE USER → allow only 2 posts
  final countSnap = await FirebaseFirestore.instance
      .collection("services")
      .where("providerId", isEqualTo: uid)
      .count()
      .get();

  return countSnap.count! < 2;
}
