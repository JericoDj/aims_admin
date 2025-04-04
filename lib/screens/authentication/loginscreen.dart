import 'package:aims_admin/screens/authentication/create_account.dart';
import 'package:aims_admin/repository/authentication_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/colors.dart';
import '../../../utils/version.dart';
import '../../utils/local_storage.dart';
import '../home/homescreen.dart';
import 'forgotpasswordscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  bool _obscureText = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthenticationRepository _authRepo = AuthenticationRepository();


  Future<void> _login() async {
    print("pressed");

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar("Error", "Email and password cannot be empty.",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      UserCredential? userCredential = await _authRepo.loginWithEmailAndPassword(email, password);

      // Dismiss the loading spinner after trying to login
      Get.back();

      if (userCredential != null) {
        User user = userCredential.user!;
        print("✅ User logged in: ${user.uid}");

        bool isAdmin = await _checkIfUserIsAdmin(user);

        if (!isAdmin) {
          Get.snackbar("Access Denied", "You are not an Admin. Access restricted.",
              backgroundColor: Colors.red, colorText: Colors.white);
          await FirebaseAuth.instance.signOut();
          return;
        }

        // If user is admin, proceed with admin setup if necessary
        try {
          print("🔧 Setting user as admin...");

          // This block is no longer needed since we already check if the user is admin
          // and simply proceed. If the user is admin, there's no need to set them again.

          // ✅ Save user data locally only after successful login
          await LocalStorage.saveUserId(user.uid);
          await LocalStorage.saveFCMToken();

          // All checks passed: go to home
          Get.offAll(() => HomeScreen());
          Get.snackbar("Login Successful", "Welcome back!",
              backgroundColor: Colors.green, colorText: Colors.white);
        } catch (e) {
          Get.snackbar("Error", "Failed during admin setup: ${e.toString()}",
              backgroundColor: Colors.red, colorText: Colors.white);
          await FirebaseAuth.instance.signOut();
          return;
        }
      } else {
        Get.snackbar("Login Failed", "Invalid credentials or user not found.",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      // Dismiss the loading spinner in case of an error
      Get.back();
      Get.snackbar("Login Error", e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }






  Future<bool> _checkIfUserIsAdmin(User user) async {
    try {
      // Get the user's UID
      final uid = user.uid;

      // Get the Firestore document for the user
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      // Check if the document exists and if the 'role' field is available
      if (userDoc.exists) {
        // Get the role from Firestore
        final role = userDoc['role'];

        // Return true if the role is 'Admin', false otherwise
        return role == 'Admin';
      } else {
        // If the user document does not exist, you may handle it accordingly (e.g., not found or unauthorized)
        return false;
      }
    } catch (e) {
      // Handle error (e.g., network error, Firestore error)
      print('Error checking user role: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the full height of the device screen.
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await _showExitDialog(context);
        return exitApp;
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: Container(
            width: double.infinity,
            height: screenHeight,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_background/AIMS_LOGIN_BACKGROUND.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Stack(
              children: [
                // Main scrollable login content
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 80), // extra bottom padding for the version text
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/logo/logo.png', height: 180),
                      const SizedBox(height: 20),
                      Text(
                        "AIMS",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MyColors.white,
                          fontSize: 36,
                          letterSpacing: 5,
                        ),
                      ),
                      Text(
                        "ADMIN APP",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MyColors.orange,
                          fontSize: 20,
                          letterSpacing: 5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Email text field with violet input text and label
                      TextField(

                        controller: _emailController,
                        style: TextStyle(color: MyColors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(fontSize: 18, color: MyColors.orange, fontWeight: FontWeight.bold),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: MyColors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: MyColors.white, width: 2),
                          ),
                          prefixIcon: Icon(Icons.email, color: MyColors.white),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Password text field with violet input text and label
                      TextField(

                        controller: _passwordController,
                        obscureText: _obscureText,
                        style: TextStyle(color: MyColors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: 18, color: MyColors.orange,fontWeight: FontWeight.bold),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: MyColors.orange),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: MyColors.white, width: 2),
                          ),
                          prefixIcon: Icon(Icons.lock, color: MyColors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility_off : Icons.visibility,
                              color: MyColors.white,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: ButtonStyle(
                            foregroundColor: MaterialStateProperty.all(MyColors.white),
                          ),
                          onPressed: () {

                            // Navigate to the Forgot Password screen
                            Get.to(ForgotPasswordScreen());
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      Container(
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(30)),
                          border: Border.all(color: MyColors.red, width: 2),
                          color: MyColors.orange,
                        ),
                        child: TextButton(
                          onPressed: _login,
                          child: Text(
                            'LOG IN',
                            style: TextStyle(
                                color: MyColors.white, fontSize: 18,fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                // Positioned version text at the bottom
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      "Version: ${AppVersion.version} (Build: ${AppVersion.build})",
                      style: const TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Exit App",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Exit")),
        ],
      ),
    ) ??
        false;
  }
}
