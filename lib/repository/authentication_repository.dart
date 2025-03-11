import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio; // Rename Dio's Response class

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// **Check if email already exists**
  Future<bool> checkEmailExists(String email) async {
    try {
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(
          email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking email existence: $e");
      // Return false to allow the signup process to continue if an error occurs.
      return false;
    }
  }

  /// **Create a new account with Firebase Authentication**
  /// **Create a new account with Firebase Authentication**
  Future<void> createAccount({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      // **Step 1: Check if email already exists**
      bool emailExists = await checkEmailExists(email);
      if (emailExists) {
        Get.snackbar(
          "Error",
          "Email is already in use. Please use a different email.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: Duration(seconds: 3), // ✅ Keep Snackbar visible
        );
        return;
      }

      // **Step 2: Create user in Firebase Authentication**
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // **Step 3: Save user details in Firestore**
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "uid": userCredential.user!.uid,
        "name": name,
        "email": email,
        "phone": phone,
        "role": role,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // **Step 4: Show success Snackbar**
      Get.snackbar(
        "Success",
        "Account created successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3), // ✅ Snackbar remains visible
      );

      // **Step 5: Close the dialog after Snackbar disappears**
      Future.delayed(Duration(seconds: 3), () {
        if (Get.isDialogOpen!) {
          Get.back(); // ✅ Close dialog only after 3 seconds
        }
      });

    } catch (e) {
      debugPrint("Error creating account: $e");
      Get.snackbar(
        "Error",
        "Failed to create account: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: Duration(seconds: 3), // ✅ Ensure visibility
      );
    }
  }


  /// **Log in with email and password**
  Future<UserCredential?> loginWithEmailAndPassword(String email,
      String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Login failed: $e");
      Get.snackbar(
        "Login Failed",
        e.message ?? "An error occurred",
        backgroundColor: const Color(0xFFE57373),
        colorText: Colors.white,
      );
      return null;
    }
  }

  Future<void> setUserAsAdmin(String uid) async {
    try {
      // 🔹 Make sure you use the correct deployed Cloud Function URL
      String functionUrl = "https://setadmin-eh5kbvz3vq-uc.a.run.app";

      dio.Dio httpClient = dio.Dio();

      debugPrint("📡 Calling Cloud Function: $functionUrl with UID: $uid");

      dio.Response response = await httpClient.post(
        functionUrl,
        data: {"uid": uid},
        options: dio.Options(
          headers: {
            "Content-Type": "application/json", // Ensure JSON format
          },
        ),
      );

      debugPrint("📡 Response Status: ${response.statusCode}");
      debugPrint("📡 Response Data: ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        Get.snackbar("Success", "User is now an admin!",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error", "Failed to set admin. Response: ${response.data}",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("🔥 Error setting admin: $e");
      Get.snackbar("Error", "Failed to set admin: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}
