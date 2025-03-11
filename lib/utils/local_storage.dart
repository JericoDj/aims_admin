import 'package:get_storage/get_storage.dart';

class LocalStorage {
  static final GetStorage _storage = GetStorage();

  // Keys for storing data
  static const String _fcmTokenKey = 'fcmToken';
  static const String _userIdKey = 'userId';

  // Initialize GetStorage (usually done in main function)
  static Future<void> init() async {
    await GetStorage.init();
  }

  // Save FCM token to local storage
  static Future<void> saveFCMToken(String fcmToken) async {
    await _storage.write(_fcmTokenKey, fcmToken);
    print("✅ FCM Token saved locally: $fcmToken");
  }

  // Retrieve FCM token from local storage
  static String? getFCMToken() {
    return _storage.read<String>(_fcmTokenKey);
  }

  // Delete FCM token from local storage
  static Future<void> deleteFCMToken() async {
    await _storage.remove(_fcmTokenKey);
    print("✅ FCM Token deleted locally");
  }

  // Save user UID to local storage
  static Future<void> saveUserId(String userId) async {
    await _storage.write(_userIdKey, userId);
    print("✅ User UID saved locally: $userId");
  }

  // Retrieve user UID from local storage
  static String? getUserId() {
    return _storage.read<String>(_userIdKey);
  }

  // Delete user UID from local storage
  static Future<void> deleteUserId() async {
    await _storage.remove(_userIdKey);
    print("✅ User UID deleted locally");
  }
}
