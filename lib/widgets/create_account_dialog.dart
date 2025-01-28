import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/colors.dart';
import '../repository/authentication_repository.dart';

class CreateAccountDialog extends StatefulWidget {
  @override
  _CreateAccountDialogState createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<CreateAccountDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String selectedRole = "User"; // Default role
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      child: Container(
        width: MediaQuery.of(context).size.width, // Set dialog width to 90% of screen
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(width: 40),
                      Text(
                        "CREATE ACCOUNT",
                        style: GoogleFonts.roboto(
                          color: MyColors.red,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: MyColors.red),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Account Type",
                    style: GoogleFonts.roboto(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChoiceChip("User", setState),
                      const SizedBox(width: 15),
                      _buildChoiceChip("Admin", setState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildInputField("Full Name", Icons.person, nameController),
                  const SizedBox(height: 14),
                  _buildInputField("Email Address", Icons.email, emailController),
                  const SizedBox(height: 14),
                  _buildInputField("Phone Number", Icons.phone, phoneController),
                  const SizedBox(height: 14),
                  _buildPasswordField("Password", obscurePassword, passwordController, () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  }),
                  const SizedBox(height: 14),
                  _buildPasswordField("Confirm Password", obscureConfirmPassword, confirmPasswordController, () {
                    setState(() {
                      obscureConfirmPassword = !obscureConfirmPassword;
                    });
                  }),
                  const SizedBox(height: 24),
                  _buildSignUpButton(),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String role, StateSetter setState) {
    return ChoiceChip(
      label: Text(
        role,
        style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w500, color: selectedRole == role ? Colors.white : MyColors.red),
      ),
      selectedColor: MyColors.orange,
      backgroundColor: Colors.white,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(color: selectedRole == role ? MyColors.orange : Colors.grey.shade400),
      ),
      selected: selectedRole == role,
      onSelected: (bool selected) {
        setState(() {
          selectedRole = role;
        });
      },
    );
  }

  Widget _buildSignUpButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: MyColors.red, width: 1.5),
        borderRadius: BorderRadius.all(Radius.circular(5)),
        color: MyColors.orange,
      ),
      child: TextButton(
        onPressed: () async {
          if (nameController.text.isEmpty ||
              emailController.text.isEmpty ||
              phoneController.text.isEmpty ||
              passwordController.text.isEmpty ||
              confirmPasswordController.text.isEmpty) {
            Get.snackbar("Error", "All fields are required", backgroundColor: Colors.red, colorText: Colors.white);
            return;
          }

          if (passwordController.text != confirmPasswordController.text) {
            Get.snackbar("Error", "Passwords do not match", backgroundColor: Colors.red, colorText: Colors.white);
            return;
          }

          // Call Auth Repository
          await AuthenticationRepository.instance.createAccount(
            name: nameController.text,
            email: emailController.text,
            phone: phoneController.text,
            password: passwordController.text,
            role: selectedRole,
          );
        },
        child: Text(
          'SIGN UP',
          style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w400, color: MyColors.red),
        ),
      ),
    );
  }
}



Widget _buildPasswordField(String label, bool obscureText, TextEditingController controller, VoidCallback toggleVisibility) {
  return Focus(
    child: Builder(
      builder: (BuildContext context) {
        return TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: Focus.of(context).hasFocus ? FontWeight.w600 : FontWeight.w400,
              color: Focus.of(context).hasFocus ? MyColors.red : Colors.black87, // Black default, red when focused
            ),
            hintText: "Enter your $label",
            hintStyle: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade500),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: MyColors.orange, width: 2),
            ),
            prefixIcon: Icon(Icons.lock, color: MyColors.orange, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, size: 20, color: MyColors.red),
              onPressed: toggleVisibility,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
        );
      },
    ),
  );
}




Widget _buildInputField(String label, IconData icon, TextEditingController controller) {
  return Focus(
    child: Builder(
      builder: (BuildContext context) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: Focus.of(context).hasFocus ? FontWeight.w600 : FontWeight.w400,
              color: Focus.of(context).hasFocus ? MyColors.red : Colors.black87, // Black default, red when focused
            ),
            hintText: "Enter $label",
            hintStyle: GoogleFonts.roboto(fontSize: 14, color: Colors.grey.shade500),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(color: MyColors.orange, width: 2),
            ),
            prefixIcon: Icon(icon, color: MyColors.orange, size: 20),
            filled: true,
            fillColor: Colors.white,
          ),
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.black),
        );
      },
    ),
  );
}
