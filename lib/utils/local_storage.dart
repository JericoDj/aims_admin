import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:get_storage/get_storage.dart';

class LocalStorage {
  static final GetStorage _storage = GetStorage();

  // Keys for storing data
  static const String _fcmTokenKey = 'fcmToken';
  static const String _userIdKey = 'userId';
  static const String _apnTokenKey = 'apnsToken';


  // Retrieve FCM and APN token from local storage
  static String? getFCMToken() => _storage.read<String>(_fcmTokenKey);
  static String? getAPNsToken() => _storage.read<String>(_apnTokenKey);

  // Initialize GetStorage (usually done in main function)
  static Future<void> init() async {
    await GetStorage.init();
  }




  /// Save FCM token and link APNs if on iOS
  static Future<void> saveFCMToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await _storage.write(_fcmTokenKey, fcmToken);
      print("✅ FCM Token saved locally: $fcmToken");

      // On iOS, get APNs token and link with FCM
      if (Platform.isIOS) {
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken != null) {
          await _storage.write(_apnTokenKey, apnsToken);
          print("📱 APNs Token saved locally: $apnsToken");

          // Optional: register APNs token with FCM (mostly automatic)
          await FirebaseMessaging.instance.setAutoInitEnabled(true);
        } else {
          print("⚠️ APNs Token is null. Make sure notifications are allowed.");
        }
      }
    } else {
      print("❌ FCM Token is null. Check Firebase initialization.");
    }
  }







  // Delete FCM token from local storage
  static Future<void> deleteFCMToken() async {
    await _storage.remove(_fcmTokenKey);
    await FirebaseMessaging.instance.deleteToken();
    print("🗑️ FCM Token deleted locally and from Firebase");

    if (Platform.isIOS) {
      await _storage.remove(_apnTokenKey);
      print("🗑️ APNs Token deleted locally");
    }
  }

  // Save user UID to local storage
  static Future<void> saveUserId(String userId) async {
    await _storage.write(_userIdKey, userId);
    print("✅ User UID saved locally: $userId");
  }


  // Retrieve user UID from local storage

  static String? getUserId() => _storage.read<String>(_userIdKey);


  // Delete user UID from local storage
  static Future<void> deleteUserId() async {
    await _storage.remove(_userIdKey);
    print("✅ User UID deleted locally");
  }
}
