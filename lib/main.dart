import 'package:aims_admin/repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // ✅ Import Firebase options
import 'package:aims_admin/screens/authentication/loginscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform, // ✅ Ensure Firebase is initialized correctly
    );

    // ✅ Use `Get.put` to ensure AuthRepository is ready immediately
    Get.put(AuthenticationRepository());

    runApp(const MyApp());
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
      title: 'Flutter Login',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
