import 'package:aims_admin/screens/authentication/create_account.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';
import '../../../utils/version.dart';
import '../home/homescreen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool exitApp = await _showExitDialog(context);
        return exitApp;
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  Image.asset('assets/images/logo/logo.png', height: 200),
                  const SizedBox(height: 20),
                  Text("AIMS", style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,
                      color: MyColors.red, fontSize: 36, letterSpacing: 5),),
                  Text("ADMIN APP", style: GoogleFonts.roboto(
                      fontWeight: FontWeight.bold,

                      color: MyColors.orange, fontSize: 20, letterSpacing: 5)),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: GoogleFonts.roboto(fontSize: 18, color: MyColors.red),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MyColors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MyColors.red, width: 2),
                      ),
                      prefixIcon: Icon(Icons.email, color: MyColors.red),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: GoogleFonts.roboto(fontSize: 18, color: MyColors.red),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MyColors.red),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: MyColors.red, width: 2),
                      ),
                      prefixIcon: Icon(Icons.lock, color: MyColors.red),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.all(MyColors.red),
                      ),
                      onPressed: () {
                        Get.snackbar('Forgot Password', 'Forgot Password button pressed', snackPosition: SnackPosition.BOTTOM);
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      border: Border.all(color: MyColors.red, width: 2),
                      color: MyColors.orange,
                    ),
                    child: TextButton(
                      onPressed: () {
                        Get.to(()=> HomeScreen());
                        Get.snackbar('Login', 'Login button pressed', snackPosition: SnackPosition.BOTTOM);
                      },
                      child: Text(
                        'LOG IN',
                        style: GoogleFonts.roboto(color: MyColors.red, fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Get.to(()=> CreateAccountScreen());
                      Get.snackbar('Sign Up', 'Create Account button pressed', snackPosition: SnackPosition.BOTTOM);
                    },
                    child: const Text('Create Account', style: TextStyle(color: MyColors.red)),
                  ),
                  const SizedBox(height: 40),
                  Text("Version: ${AppVersion.version} (Build: ${AppVersion.build})",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
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
        title: Text("Exit App", style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: Text("Cancel", style: TextStyle(color: MyColors.red)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: Text("Exit", style: TextStyle(color: MyColors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }
}
