import 'package:aims_admin/screens/manage_account/manage_accounts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:sqflite/sqflite.dart';
import '../../api/firebase_api.dart';
import '../../utils/colors.dart';
import '../../utils/local_storage.dart';
import '../../utils/version.dart';
import '../authentication/loginscreen.dart';
import '../generateqr/genearateqrscreen.dart';
import '../stockroom/stockroom.dart';
import '../treatmentarea/treatmentareascreen.dart';
import 'offline_data_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {


  bool isOnline = true; // 🔄 Switchable online/offline mode
  Database? localDatabase; // ✅ Local database instance

  bool hasNotification = true;
  bool isNotificationDrawerOpen = false;

  // 🔥 Pagination variables for Firestore
  List<DocumentSnapshot> notificationDocs = [];
  bool isLoading = false;
  bool hasMoreNotifications = true;
  int notificationLimit = 5;
  DocumentSnapshot? lastNotification;


  final PageController _pageController = PageController();
  final List<String> images = [
    // Replace these with your actual image paths
    'assets/images/tutorial/aims.png',
    'assets/images/tutorial/aims2.png',
    'assets/images/tutorial/aims3.png',
  ];




  @override
  void initState() {
    super.initState();
    _initFirebaseNotifications();
    _fetchNotifications();
  }





  Future<void> _initFirebaseNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print("User logged in: ${user.uid}");
      await FirebaseAPI().initNotifications(user.uid);

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleNotificationClick(message);
      });
    } else {
      print("No user found. Skipping notifications.");
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    if (message.data.containsKey('receiverFullName') &&
        message.data.containsKey('receiverEmail')) {
      Get.to(() => HomeScreen());
    }
  }


  /// 🚀 Fetch initial notifications from Firestore
  Future<void> _fetchNotifications() async {
    if (isLoading || !hasMoreNotifications) return;

    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('history')
        .orderBy('Date Updated', descending: true)
        .limit(notificationLimit);

    if (lastNotification != null) {
      query = query.startAfterDocument(lastNotification!);
    }

    QuerySnapshot snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        notificationDocs.addAll(snapshot.docs);
        lastNotification = snapshot.docs.last;
        if (snapshot.docs.length < notificationLimit) {
          hasMoreNotifications = false;
        }
      });
    } else {
      setState(() => hasMoreNotifications = false);
    }

    setState(() => isLoading = false);
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

                        Text(
                          "ADMIN APP",

                          style: TextStyle(color: MyColors.red, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        SizedBox(height: 20),


                        buildButton("STOCK ROOM", MyColors.white, MyColors.red,
                                () => Get.to(() => StockRoomScreen())),
                        SizedBox(height: 20),
                        buildButton("TREATMENT AREA", MyColors.white,
                            MyColors.red, () => Get.to(() => TreatmentAreaScreen())),
                        SizedBox(height: 20),
                        buildButton("GENERATE QR CODE", MyColors.white,
                            MyColors.red, () => Get.to(() => GenerateQRCodeScreen())),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [


                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 80),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Version: 2.0.0 (Build: 1.0.0)",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      // Info icon next to version text
                      IconButton(
                        icon: Icon(Icons.info_outline),
                        onPressed: () => _showTutorialDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                icon: Icon(Icons.notifications, size: 36),
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
          Row(
            children: [
              IconButton(
                icon: Icon(
                  isOnline ? Icons.cloud_done : Icons.cloud_off,
                  color: isOnline ? MyColors.orange : Colors.red,
                  size: 28,
                ),
                onPressed: _showDatabaseSwitchDialog, // Open switch dialog
              ),

              IconButton(
                icon: Icon(Icons.logout, size: 28),
                onPressed: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ✅ Switchable Database Mode Dialog
  void _showDatabaseSwitchDialog() {
    showDialog(
      context: this.context,
      builder: (context) => AlertDialog(
        title: Text("Database Settings",textAlign: TextAlign.center,),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Use Offline Database."),
            SizedBox(height: 10),

            // ✅ New Button: View Offline Data
            GestureDetector(
              onTap: () {
                Navigator.pop(context); // Close the dialog
                Get.to(() => OfflineDataScreen());
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: MyColors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.storage, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "View Offline Data",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )

          ],
        ),


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
          height: 350,
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
              Expanded(
                child: ListView.builder(
                  itemCount: notificationDocs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == notificationDocs.length) {
                      return _buildLoadMoreButton();
                    }
                    final data = notificationDocs[index];
                    return ListTile(
                      leading: Icon(Icons.history, color: MyColors.orange),
                      title: Text(
                        data["Item Name"],
                        style: TextStyle(
                            color: MyColors.red, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${data["Action"]}: ${data["Quantity"]} (${data["Category"]})",
                      ),
                      trailing: Text(
                        _formatTimestamp(data["Date Updated"]),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () {
                        final historyData = data.data() as Map<String, dynamic>?;
                        if (historyData != null) {
                          _showHistoryDetailsDialog(historyData);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryDetailsDialog(Map<String, dynamic> historyData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("History Details",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...historyData.entries.map((entry) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${entry.key}:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MyColors.red)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                          entry.key == "Date Updated"
                              ? _formatTimestamp(entry.value)
                              : entry.value.toString(),
                          style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              )).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: MyColors.red)),
          ),
        ],
      ),
    );
  }

// Updated timestamp formatter to handle Firestore Timestamp
  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;

      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return "Invalid date";
      }

      return "${date.year}-${date.month.toString().padLeft(2, '0')}-"
          "${date.day.toString().padLeft(2, '0')} "
          "${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "Invalid date";
    }
  }
  Widget _buildLoadMoreButton() {
    if (!hasMoreNotifications) {
      return Center(child: Text("No more notifications."));
    }
    return TextButton(
      onPressed: _fetchNotifications,
      child: isLoading
          ? CircularProgressIndicator()
          : Text("Load More", style: TextStyle(color: MyColors.red)),
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
              // await LocalStorage.deleteFCMToken();
              await LocalStorage.deleteUserId();
              Navigator.pop(context);
              Get.offAll(() => LoginScreen());
            },
            child: Text("Logout",
                style: TextStyle(color: MyColors.orange)),
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

  // Show the tutorial dialog with images and page indicator
  void _showTutorialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PageView for images
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: images.length,
                      itemBuilder: (context, index) {
                        return Image.asset(
                          images[index],
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                  // Page indicator to show current page
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: images.length,
                      effect: ExpandingDotsEffect(
                        dotWidth: 8,
                        dotHeight: 8,
                        dotColor: Colors.grey,
                        activeDotColor: Colors.blue,
                      ),
                    ),
                  ),
                  // Close button (X) to exit the dialog
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: Colors.red,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }




}

