import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  Future<void> activatePlan(String plan) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    Duration duration;

    if (plan == "monthly") {
      duration = const Duration(days: 30);
    } else if (plan == "6months") {
      duration = const Duration(days: 180);
    } else {
      duration = const Duration(days: 365);
    }

    final expiry = DateTime.now().add(duration);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({"isPremium": true, "premiumExpiry": expiry});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Go Premium")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => activatePlan("monthly"),
              child: const Text("Monthly – 500 Tk"),
            ),
            ElevatedButton(
              onPressed: () => activatePlan("6months"),
              child: const Text("6 Months – 2500 Tk"),
            ),
            ElevatedButton(
              onPressed: () => activatePlan("yearly"),
              child: const Text("Yearly – 4000 Tk"),
            ),
          ],
        ),
      ),
    );
  }
}
