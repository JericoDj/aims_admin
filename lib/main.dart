import 'package:aims_admin/repository/authentication_repository.dart';
import 'package:aims_admin/utils/local_storage.dart';
import 'package:aims_admin/utils/notification_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:aims_admin/screens/authentication/loginscreen.dart';

// ✅ Initialize Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// ✅ Background message handler (Must be a top-level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("✅ Background Message: ${message.notification?.title}");
}

/// ✅ Initialize Firebase Messaging and Notifications
Future<void> _initializeNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // ✅ Request notification permissions
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint("✅ Notifications enabled.");
  } else {
    debugPrint("❌ Notifications denied.");
  }

  // ✅ Initialize Local Notifications
  const AndroidInitializationSettings androidInitializationSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: androidInitializationSettings);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      debugPrint("🔔 Notification Clicked: ${response.payload}");
    },
  );

  // ✅ Listen for foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("✅ Foreground Message: ${message.notification?.title}");
    _showNotification(message);
  });

  // ✅ Handle background messages
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

/// ✅ Show local notification
Future<void> _showNotification(RemoteMessage message) async {
  AndroidNotificationDetails androidPlatformChannelSpecifics =
  const AndroidNotificationDetails(
    'default_channel', 'Default Channel',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  NotificationDetails platformChannelSpecifics =
  NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? "New Notification",
    message.notification?.body ?? "You have a new message",
    platformChannelSpecifics,
  );
}

void main() async {


    // Register the NotificationController globally before running the app
    Get.put(NotificationController());

    WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );


    // ✅ Initialize notifications
    await _initializeNotifications();

    // ✅ Initialize GetStorage
    await LocalStorage.init();

    // ✅ Request necessary permissions
    await _requestPermissions();

    // ✅ Use `Get.put` to ensure AuthRepository is ready immediately
    Get.put(AuthenticationRepository());

    if (kIsWeb) {
      // ✅ If running on web, use WebApp
      Get.testMode = true;
      runApp(WebApp());
    } else {
      // ✅ If running on mobile, use MyApp
      runApp(const MyApp());
    }
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }
}

/// ✅ Request Permissions for Android & iOS
Future<void> _requestPermissions() async {
  if (!kIsWeb) {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
    ].request();

    // ✅ Request Notification Permission Separately
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AIMS Inventory',
      theme: ThemeData(
        fontFamily: 'Bourgeois',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class WebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 600,
        height: 800,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AIMS Inventory',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}
