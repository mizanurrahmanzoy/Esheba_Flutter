import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 🔹 STEP 4 — Permission request
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 🔹 STEP 5 — Save token
    final token = await _messaging.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (token != null && uid != null) {
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .update({'deviceToken': token});
    }

    // 🔹 Foreground listener
    FirebaseMessaging.onMessage.listen((message) {
      print("🔔 Foreground notification: ${message.notification?.title}");
    });
  }
}
