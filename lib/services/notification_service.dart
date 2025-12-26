import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();

  /// Initialize everything
  static Future<void> init() async {
    // 1️⃣ Request permission (Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2️⃣ Get & save token
    final token = await _fcm.getToken();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid != null && token != null) {
      await FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .update({'deviceToken': token});
    }

    // 3️⃣ Local notification setup
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _local.initialize(settings);

    // 4️⃣ Foreground listener
    FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  /// Show notification when app is open
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'Important Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _local.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
