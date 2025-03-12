import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class MyFirebaseMessagingService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// **Initialize Firebase Messaging**
  static Future<void> initialize() async {
    // Request permissions
    await _firebaseMessaging.requestPermission();

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print("🔥 FCM Token: $token");

    // Configure Notification Settings
    _configureLocalNotifications();

    // Listen to incoming messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Notification: ${message.notification?.title}");
      _showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔗 Notification Clicked! ${message.data}");
    });
  }

  /// **Handle Background Messages**
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print("🌙 Background Message: ${message.messageId}");
  }

  /// **Configure Local Notifications**
  static void _configureLocalNotifications() {
    var androidSettings = const AndroidInitializationSettings('@mipmap/ic_launcher');
    var initSettings = InitializationSettings(android: androidSettings);

    _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  /// **Show Local Notification**
  static void _showNotification(RemoteMessage message) async {
    var androidDetails = const AndroidNotificationDetails(
      "default_channel", "General Notifications",
      importance: Importance.high, priority: Priority.high,
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      0, // ID
      message.notification?.title ?? "New Notification",
      message.notification?.body ?? "You have a new message",
      notificationDetails,
    );
  }
}
