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
    try {
      // 🔒 Request permission first
      await FirebaseMessaging.instance.requestPermission();

      if (Platform.isIOS) {
        String? apnsToken;
        int retryCount = 0;

        // ⏳ Wait for APNs token to be set (up to 5 seconds)
        while (apnsToken == null && retryCount < 5) {
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          print("⏳ Waiting for APNs token... attempt ${retryCount + 1}");
          await Future.delayed(Duration(seconds: 1));
          retryCount++;
        }

        if (apnsToken == null) {
          print("⚠️ APNs Token still null after retries. Delaying FCM token registration.");
          return;
        }

        await _storage.write(_apnTokenKey, apnsToken);
        print("📱 APNs Token saved locally: $apnsToken");
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();

      if (fcmToken != null) {
        await _storage.write(_fcmTokenKey, fcmToken);
        print("✅ FCM Token saved locally: $fcmToken");
      } else {
        print("❌ FCM Token is null even after APNs. Double-check Firebase setup.");
      }

    } catch (e) {
      print("❌ Error saving FCM/APNs token: $e");
    }
  }








  static Future<void> deleteFCMToken() async {
    await _storage.remove(_fcmTokenKey);

    if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();

      if (apnsToken == null) {
        print("⚠️ APNs token not available yet. Skipping Firebase token deletion on iOS.");
      } else {
        try {
          await FirebaseMessaging.instance.deleteToken();
          print("🗑️ FCM Token deleted from Firebase on iOS");
        } catch (e) {
          print("❌ Error deleting FCM token on iOS: $e");
        }
      }

      await _storage.remove(_apnTokenKey);
      print("🗑️ APNs Token deleted locally");
    } else {
      // For Android and others
      try {
        await FirebaseMessaging.instance.deleteToken();
        print("🗑️ FCM Token deleted from Firebase");
      } catch (e) {
        print("❌ Error deleting FCM token: $e");
      }
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




  // Key for server IP
  static const String _serverIpKey = 'serverIp';

// Save server IP
  static Future<void> saveServerIp(String ip) async {
    await _storage.write(_serverIpKey, ip);
    print("✅ Server IP saved locally: $ip");
  }

// Get server IP
  static String? getServerIp() {
    return _storage.read<String>(_serverIpKey);
  }

// Delete server IP
  static Future<void> deleteServerIp() async {
    await _storage.remove(_serverIpKey);
    print("✅ Server IP deleted locally");
  }
}


