import 'dart:async';
import 'dart:ui';

import 'package:aims_admin/repository/authentication_repository.dart';
import 'package:aims_admin/screens/home/offline/connect_to_offline_controller.dart';
import 'package:aims_admin/utils/local_storage.dart';
import 'package:aims_admin/utils/notification_controller.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'package:aims_admin/screens/authentication/loginscreen.dart';
import 'package:aims_admin/screens/home/offline/local_server.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("\u2705 Background Message: \${message.notification?.title}");
}

Future<void> _initializeNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    debugPrint("\u2705 Notifications enabled.");
  } else {
    debugPrint("\u274C Notifications denied.");
  }

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  final InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (response) {
      debugPrint("\ud83d\udd14 Notification Clicked: \${response.payload}");
    },
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint("\u2705 Foreground Message: \${message.notification?.title}");
    _showNotification(message);
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
    if (apnsToken != null) {
      debugPrint("\u2705 APNS Token: \$apnsToken");
    } else {
      debugPrint("\u274C Failed to fetch APNS token.");
    }
  }
}

Future<void> _showNotification(RemoteMessage message) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'default_channel',
    'Default Channel',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformDetails =
  NotificationDetails(android: androidDetails);

  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? "New Notification",
    message.notification?.body ?? "You have a new message",
    platformDetails,
  );
}

Future<void> onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  final localServer = LocalServer();
  await localServer.startServer();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setAutoStartOnBootMode(true);
  }

  Timer.periodic(Duration(minutes: 5), (timer) {
    service.invoke("ping", {"status": "alive"});
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Offline Server Running',
      initialNotificationContent: 'Waiting for incoming data...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      onBackground: (service) async => true,

    ),
  );
  await service.startService(); // ✅ Fixed

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).then((FirebaseApp value) => Get.put(AuthenticationRepository()));

    await _initializeNotifications();
    await LocalStorage.init();
    await _requestPermissions();

    Get.put(ConnectToOfflineController());
    Get.put(NotificationController());

    runApp(const MyApp());
  } catch (e) {
    debugPrint("\u274C Firebase initialization failed: \$e");
  }
}

Future<void> _requestPermissions() async {
  if (!kIsWeb) {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
      Permission.manageExternalStorage,
      Permission.photos,
    ].request();

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