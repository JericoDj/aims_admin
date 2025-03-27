import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../utils/version.dart';
import 'loginscreen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: MyColors.red,
          centerTitle: true,
          title: Text(
            "FORGOT PASSWORD",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Get.back(); // ✅ Go back to LoginScreen
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 50),

              // Instruction Text
              Text(
                "Enter your email to reset your password",
                style: GoogleFonts.roboto(fontSize: 18, color: MyColors.red),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 30),

              // Email Input
              TextField(
                controller: _emailController,
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

              SizedBox(height: 20),

              // Reset Password Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  border: Border.all(color: MyColors.red, width: 2),
                  color: MyColors.orange,
                ),
                child: TextButton(
                  onPressed: () {
                    _resetPassword();
                  },
                  child: Text(
                    'RESET PASSWORD',
                    style: GoogleFonts.roboto(color: MyColors.red, fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 50),
          Text("Version: ${AppVersion.version} (Build: ${AppVersion.build})",
            style: TextStyle(color: Colors.grey, fontSize: 16),),


            ],
          ),
        ),
      ),
    );
  }

  /// **🔹 Simulate Password Reset Request**
  void _resetPassword() {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your email!", style: TextStyle(color: Colors.white)), backgroundColor: MyColors.red),
      );
      return;
    }

    // ✅ Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Reset link sent to $email!", style: TextStyle(color: Colors.black)),
        backgroundColor: MyColors.white,
      ),
    );

    // ✅ Optionally, navigate back to LoginScreen after a delay
    Future.delayed(Duration(seconds: 2), () {
      Get.off(() => LoginScreen());
    });
  }
}
