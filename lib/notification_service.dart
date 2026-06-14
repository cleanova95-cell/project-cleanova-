import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handled in main.dart, but keeping this top-level declaration clean
  print("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // NOTE: Ensure this channel ID matches what you put in main.dart and AndroidManifest.xml
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'cleanova_booking_channel',        // id
    'Booking Status Updates',          // name shown in phone settings
    description: 'Notifies customers when their booking status changes.',
    importance: Importance.high,
  );

  static Future<void> init() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    const InitializationSettings settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(settings);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFF43A047),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    });
  }

  /// Fetches the current FCM device token and saves it securely to Firestore.
  /// Also sets up a listener to auto-update Firestore if Firebase changes the token later.
  static Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Get current token and upload
      final token = await _fcm.getToken();
      if (token != null) {
        await _uploadTokenToFirestore(user.uid, token);
      }

      // 2. Setup live stream to listen for any mid-session token updates
      _fcm.onTokenRefresh.listen((newToken) async {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _uploadTokenToFirestore(currentUser.uid, newToken);
        }
      });
    } catch (e) {
      print("Error managing FCM Token: $e");
    }
  }

  /// Internal helper to execute the Firestore write safely
  static Future<void> _uploadTokenToFirestore(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({
      'fcmToken': token,
    }, SetOptions(merge: true)); // Using merge: true avoids crashing on fresh registrations
    print('FCM Token securely linked to Firestore for user: $uid');
  }

  // ─────────────────────────────────────────────────────────────────
  // NEW: Listen to Firestore notifications for real-time popup
  // ─────────────────────────────────────────────────────────────────
  static Stream<List<Map<String, dynamic>>> listenToUserNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => {
      ...doc.data(),
      'id': doc.id,
    })
        .toList());
  }

  // ─────────────────────────────────────────────────────────────────
  // NEW: Show local notification popup
  // ─────────────────────────────────────────────────────────────────
  static Future<void> showLocalNotification({
    required String title,
    required String message,
  }) async {
    await _localNotifications.show(
      DateTime.now().hashCode,
      title,
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF43A047),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}