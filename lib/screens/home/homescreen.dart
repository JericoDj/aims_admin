import 'package:aims_admin/screens/manage_account/manage_accounts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/firebase_api.dart';
import '../../utils/colors.dart';
import '../../utils/local_storage.dart';
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
  void initState() {
    super.initState();
    _initFirebaseNotifications();
  }



  /// **Initializes Firebase Notifications only for logged-in users**
  Future<void> _initFirebaseNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("User logged in: ${user.uid}");

      // Initialize Firebase Messaging
      await FirebaseAPI().initNotifications(user.uid);

      // Handle background FCM notifications
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });
    } else {
      print("No user found. Skipping notifications.");
    }
  }

  /// **Handles notification click and navigates to the correct screen**
  void _handleNotificationClick(RemoteMessage message) {
    if (message.data.containsKey('receiverFullName') && message.data.containsKey('receiverEmail')) {


      // Navigate to the chat screen
      Get.to(() => HomeScreen(
      ));
    }
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Scaffold(
        backgroundColor: MyColors.white,
        body: Stack(
          children: [
            // Background Image
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/login_background/homepage_background.png',
                fit: BoxFit.fitWidth,
              ),
            ),

            // Main Content
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/logo/logo.png',
                          height: 165,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "AIMS",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        buildButton("STOCK ROOM", MyColors.white, MyColors.red,
                                () => Get.to(() => StockRoomScreen())),
                        SizedBox(height: 20),
                        buildButton("TREATMENT AREA", MyColors.white, MyColors.red,
                                () => Get.to(() => TreatmentAreaScreen())),
                        SizedBox(height: 20),
                        buildButton("GENERATE QR CODE", MyColors.white, MyColors.red,
                                () => Get.to(() => GenerateQRCodeScreen())),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bottom Buttons (Fixed Position)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 80),
                    child: GestureDetector(
                      onTap: () => Get.to(() => ManageAccounts()),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: MyColors.orange,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black),
                        ),
                        child: Center(
                          child: Text(
                            "MANAGE ACCOUNTS",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Version: ${AppVersion.version} (Build: ${AppVersion.build})",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                ],
              ),
            ),

            // Notification Drawer
            if (isNotificationDrawerOpen) _buildNotificationDrawer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: MyColors.white,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications, color: Colors.black, size: 36),
                onPressed: () => setState(() {
                  isNotificationDrawerOpen = !isNotificationDrawerOpen;
                  hasNotification = false;
                }),
              ),
              if (hasNotification)
                Positioned(
                  right: 11,
                  top: 12,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.redAccent),
                      color: MyColors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black, size: 28),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationDrawer() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Material(

        elevation: 5,
        child: Container(
          height: 250,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MyColors.white,
            border: Border.all(color: MyColors.red),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
          ),
          child: Column(
            children: [
              Text(
                "🔔 Notifications",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MyColors.red,
                ),
              ),
              Divider(color: MyColors.red),
              ListTile(
                leading: Icon(Icons.info, color: MyColors.orange),
                title: Text("New update available!",
                    style: TextStyle(color: MyColors.red)),
                subtitle: Text("Tap to update"),
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: MyColors.orange),
                title: Text("Backup Completed",
                    style: TextStyle(color: MyColors.red)),
                subtitle: Text("Your inventory is safe"),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: MyColors.red)),
          ),
          TextButton(
            onPressed: () async {
              // Remove FCM token and UID from local storage
              await LocalStorage.deleteFCMToken();
              await LocalStorage.deleteUserId();

              // Pop the logout dialog
              Navigator.pop(context);

              // Navigate to LoginScreen
              Get.offAll(() => LoginScreen());
            },
            child: Text("Logout",
                style: TextStyle(color: MyColors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }



  Widget buildButton(String text, Color textColor, Color borderColor, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.red,
          padding: EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: borderColor, width: 2),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 20,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}