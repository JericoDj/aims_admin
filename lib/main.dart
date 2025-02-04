import 'package:aims_admin/repository/authentication_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ Import Firebase options
import 'package:aims_admin/screens/authentication/loginscreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // ✅ Ensure Firebase is initialized correctly
    );

    // ✅ Use `Get.put` to ensure AuthRepository is ready immediately
    Get.put(AuthenticationRepository());

    if (kIsWeb) {
      // ✅ If running on web, use WebApp
      Get.testMode = true; // Optional: Enables test mode for GetX on web
      runApp(WebApp());
    } else {
      // ✅ If running on mobile, use MyApp
      runApp(const MyApp());
    }
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
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
      home: const LoginScreen(), // Start with the Login Screen
    );
  }
}

class WebApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 600, // Web-specific container width
        height: 800, // Web-specific container height
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 2), // Optional: Add a border for visibility
        ),
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AIMS Inventory',
          theme: ThemeData(
            primarySwatch: Colors.blue, // Web-specific theme
          ),
          home: const LoginScreen(), // Start with the Login Screen
        ),
      ),
    );
  }
}
