import 'package:aims_admin/screens/authentication/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../utils/colors.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedAccountType = 'User';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account', style: GoogleFonts.roboto(color: MyColors.red, fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: MyColors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Align(
                alignment: Alignment.topCenter,
                child: Text("Account Type", style: GoogleFonts.roboto(fontSize: 22, color: MyColors.red))),

            SizedBox(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                ChoiceChip(
                  label: Text('User',
                      style: GoogleFonts.roboto(

                          fontSize: 20,
                          color: MyColors.red)),
                  selectedColor: MyColors.orange,
                  backgroundColor: Colors.white,
                  checkmarkColor: MyColors.red,
                  shape: StadiumBorder(side: BorderSide(color: _selectedAccountType == 'User' ? MyColors.orange : Colors.grey)),
                  selected: _selectedAccountType == 'User',
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedAccountType = 'User';
                    });
                  },
                ),
                const SizedBox(width: 15),
                ChoiceChip(
                  label: Text('Admin',


                      style: GoogleFonts.roboto(
                        fontSize: 20,

                          color: MyColors.red)),
                  selectedColor: MyColors.orange,
                  backgroundColor: Colors.white,
                  checkmarkColor: MyColors.red,
                  shape: StadiumBorder(side: BorderSide(color: _selectedAccountType == 'Admin' ? MyColors.orange : Colors.grey)),
                  selected: _selectedAccountType == 'Admin',
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedAccountType = 'Admin';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField('Full Name', Icons.person),
            const SizedBox(height: 15),
            _buildTextField('Email Address', Icons.email),
            const SizedBox(height: 15),
            _buildTextField('Phone Number', Icons.phone),
            const SizedBox(height: 15),
            _buildPasswordField('Password', _obscurePassword, () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            }),
            const SizedBox(height: 15),
            _buildPasswordField('Confirm Password', _obscureConfirmPassword, () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            }),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                border: Border.all(color: MyColors.red, width: 2),
                color: MyColors.orange,
              ),
              child: TextButton(
                onPressed: () {
                  Get.to(() => LoginScreen());
                },
                child: Text('SIGN UP', style: GoogleFonts.roboto(color: MyColors.red, fontSize: 18)),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text('Already have an account? Login', style: TextStyle(color: MyColors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.roboto(fontSize: 18, color: MyColors.red),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyColors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyColors.red, width: 2),
        ),
        prefixIcon: Icon(icon, color: MyColors.red),
      ),
    );
  }

  Widget _buildPasswordField(String label, bool obscureText, VoidCallback toggleVisibility) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.roboto(fontSize: 18, color: MyColors.red),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyColors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyColors.red, width: 2),
        ),
        prefixIcon: Icon(Icons.lock, color: MyColors.red),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: MyColors.red),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}
