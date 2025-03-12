import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAPI {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initNotifications(String userId) async {
    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ User declined notification permissions.');
      return;
    }

    // ✅ Get and Save FCM Token
    await _updateFCMToken(userId);

    // ✅ Listen for Token Refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      saveTokenToFirestore(userId, newToken);
    });

    // ✅ Handle Foreground Notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground Notification: ${message.notification?.title}');
    });

    // ✅ Set Background Message Handler
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);


  }

  /// Get and Save FCM Token to Firestore
  Future<void> _updateFCMToken(String userId) async {
    try {
      final fcmToken = await _firebaseMessaging.getToken();
      if (fcmToken != null) {
        print('✅ FCM Token: $fcmToken');
        await saveTokenToFirestore(userId, fcmToken);
      } else {
        print('⚠️ Failed to get FCM token');
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
  }

  /// Save Token to Firestore
  Future<void> saveTokenToFirestore(String userId, String fcmToken) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': fcmToken,
      }, SetOptions(merge: true));
      print('✅ FCM token saved for user: $userId');
    } catch (e) {
      print('❌ Failed to save FCM token: $e');
    }
  }
}

/// Background Message Handler
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print('📩 Background Message: ${message.notification?.title}');
  print('📩 Message Data: ${message.data}');
}

/// Initialize Notifications for Logged-in User
Future<void> setupFirebaseNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseAPI().initNotifications(user.uid);
  } else {
    print('❌ User not authenticated, skipping FCM setup.');
  }
}
