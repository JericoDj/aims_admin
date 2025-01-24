
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../utils/version.dart';
import '../authentication/loginscreen.dart';
import '../generateqr/genearateqrscreen.dart';
import '../stockroom/stockroom.dart';
import '../treatmentarea/treatmentareascreen.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool hasNotification = true;
  bool isNotificationDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: MyColors.white,
        body: Stack(
          children: [
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView( // ✅ Makes content scrollable
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SizedBox(height: 20),

                        // Bigger Logo
                        Image.asset(
                          'assets/images/logo/logo.png',
                          height: 200, // Increased size
                        ),
                        SizedBox(height: 36),

                        // Stock Room Button
                        buildButton("STOCK ROOM", MyColors.orange, MyColors.red, () {
                          Get.to(() => StockRoomScreen());
                        }),
                        SizedBox(height: 20),

                        // Treatment Area Button
                        buildButton("TREATMENT AREA", MyColors.orange, MyColors.red, () {
                          Get.to(() => TreatmentAreaScreen());
                        }),
                        SizedBox(height: 20),

                        // Generate QR Code Button
                        buildButton("GENERATE QR CODE", MyColors.orange, MyColors.red, () {
                          Get.to(() => GenerateQRCodeScreen());
                        }),

                        SizedBox(height: 50), // Extra space for scrolling

                        Text("Version: ${AppVersion.version} (Build: ${AppVersion.build})",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),

                      ],
                    ),
                  ),
                ),


              ],
            ),

            // Notification Drawer
            if (isNotificationDrawerOpen) _buildNotificationDrawer(),
          ],
        ),
      ),
    );
  }

  /// **🔹 Custom AppBar**
  Widget _buildAppBar() {
    return Container(
      color: MyColors.red,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // **🔔 Notification Button**
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.white, size: 28),
                onPressed: () {
                  setState(() {
                    isNotificationDrawerOpen = !isNotificationDrawerOpen;
                    hasNotification = false;
                  });
                },
              ),
              if (hasNotification)
                Positioned(
                  right: 11,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      color: MyColors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),

          // **📛 App Title**
          Text(
            "AIMS",
            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),

          // **🔑 Logout Button**
          IconButton(
            style: ButtonStyle(iconSize: WidgetStatePropertyAll(28)),
            icon: Icon(Icons.logout, color: Colors.white,),
            onPressed: _showLogoutDialog,
          ),


        ],
      ),
    );
  }

  /// **🔹 Notification Drawer**
  Widget _buildNotificationDrawer() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Material(
        elevation: 5,
        color: MyColors.white,
        child: Container(
          padding: EdgeInsets.all(16),
          height: 250, // Increased height
          decoration: BoxDecoration(
            border: Border.all(color: MyColors.red),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: Column(
            children: [
              Text(
                "🔔 Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyColors.red),
              ),
              SizedBox(height: 10),
              Divider(color: MyColors.red),

              // **📩 Sample Notifications**
              ListTile(
                leading: Icon(Icons.info, color: MyColors.orange),
                title: Text("New update available!", style: TextStyle(color: MyColors.red)),
                subtitle: Text("Tap to update"),
                onTap: () {},
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: MyColors.orange),
                title: Text("Backup Completed", style: TextStyle(color: MyColors.red)),
                subtitle: Text("Your inventory is safe"),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// **🔹 Logout Confirmation Dialog**
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Logout", style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to log out?"),
          actions: [
            // ❌ FIXED: "Cancel" should only close the dialog, not log out
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Closes the dialog
              },
              child: Text("Cancel", style: TextStyle(color: MyColors.red)),
            ),

            // ✅ "Logout" should clear navigation and go to LoginScreen
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog first
                Get.offAll(() => LoginScreen()); // ✅ Now properly navigates to LoginScreen
              },
              child: Text("Logout", style: TextStyle(color: MyColors.orange, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }


  /// **🔹 Custom Button Builder**
  Widget buildButton(String text, Color textColor, Color borderColor, VoidCallback onPressed) {
    return Container(
      width: double.infinity, // Make buttons full-width
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16), // Increased padding
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderColor, width: 2),
          ),
        ),
        child: Text(text, style: TextStyle(fontSize: 18, color: textColor, fontWeight: FontWeight.bold)), // Increased text size
      ),
    );
  }
}
