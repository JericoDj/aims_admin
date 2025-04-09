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
import '../../utils/notification_controller.dart';
import '../../utils/version.dart';
import '../authentication/loginscreen.dart';
import '../generateqr/genearateqrscreen.dart';
import '../stockroom/stockroom.dart';
import '../treatmentarea/treatmentareascreen.dart';
import 'offline_data_screen.dart';
import 'package:intl/intl.dart'; // For formatting date

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();

}

class _HomeScreenState extends State<HomeScreen> {


  bool isOnline = true; // 🔄 Switchable online/offline mode
  Database? localDatabase; // ✅ Local database instance

  final hasNotification = false.obs; // Using RxBool from GetX
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
    _initializeNotificationCheck();
    checkLowStockAndNearExpiry();  // Call the function on init

  }




// Function to check low stock and near-expiry items
  Future<void> checkLowStockAndNearExpiry() async {
    try {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(now);

      final lowStockDoc = await FirebaseFirestore.instance
          .collection('indicators')
          .doc('lowStock')
          .get();

      final nearExpiryDoc = await FirebaseFirestore.instance
          .collection('indicators')
          .doc('nearExpiry')
          .get();

      DateTime lastLowStockCheck = DateTime(2000);
      DateTime lastNearExpiryCheck = DateTime(2000);

      final lowStockData = lowStockDoc.data();
      final nearExpiryData = nearExpiryDoc.data();

      if (lowStockData != null) {
        final rawDate = lowStockData['dateTime'];
        if (rawDate is Timestamp) {
          lastLowStockCheck = rawDate.toDate();
        } else if (rawDate is String) {
          lastLowStockCheck = DateTime.tryParse(rawDate) ?? DateTime(2000);
        }
      }

      if (nearExpiryData != null) {
        final rawDate = nearExpiryData['dateTime'];
        if (rawDate is Timestamp) {
          lastNearExpiryCheck = rawDate.toDate();
        } else if (rawDate is String) {
          lastNearExpiryCheck = DateTime.tryParse(rawDate) ?? DateTime(2000);
        }
      }

      print("🧪 Last Low Stock Check: $lastLowStockCheck");
      print("🧪 Last Near Expiry Check: $lastNearExpiryCheck");

      final shouldRunCheck = now.difference(lastLowStockCheck).inDays >= 1 ||
          now.difference(lastNearExpiryCheck).inDays >= 1;

      if (shouldRunCheck) {
        print("🚀 Starting low stock and expiry checks...");

        // === 🔔 Near Expiry Check ===
        final stockSnapshot = await FirebaseFirestore.instance
            .collectionGroup('items')
            .where('expiry_alert_days', isGreaterThan: 0)
            .get();

        List<Map<String, dynamic>> nearlyExpiringItems = [];

        for (var doc in stockSnapshot.docs) {
          final itemData = doc.data();

          DateTime expirationDate;
          final expiryRaw = itemData['expiration_date'];
          if (expiryRaw is Timestamp) {
            expirationDate = expiryRaw.toDate();
          } else if (expiryRaw is String) {
            expirationDate = DateTime.tryParse(expiryRaw) ?? DateTime(2000);
          } else {
            expirationDate = DateTime(2000);
          }

          final expiryAlertDays = itemData['expiry_alert_days'] ?? 0;
          final alertDate = expirationDate.subtract(Duration(days: expiryAlertDays));

          if (alertDate.isBefore(now) || alertDate.isAtSameMomentAs(now)) {
            final itemName = itemData['item_name'] ?? 'Unnamed';
            final brand = itemData['brand'] ?? '';
            nearlyExpiringItems.add({
              'name': itemName,
              'brand': brand,
              'expiry': expirationDate.toIso8601String(),
              'alertFrom': alertDate.toIso8601String(),
            });
          }
        }

        if (nearlyExpiringItems.isNotEmpty) {
          print("📋 NEARLY EXPIRING ITEMS:");
          for (var item in nearlyExpiringItems) {
            print("🔸 ${item['name']} (${item['brand']}) - "
                "Expires: ${item['expiry']} | Alert From: ${item['alertFrom']}");
          }
        } else {
          print("✅ No items are nearing expiry today.");
        }

        // === 📉 Low Stock Check ===
        // Add your low stock check logic here if needed...

        // ✅ Send notification
        NotificationController notificationController = Get.find();
        await notificationController.sendNotificationToAllUsers(
          "Stock Alert: Low Stock & Near Expiry",
          "Some items are low or near expiry. Check inventory!",
        );

        // ✅ Update indicators
        await FirebaseFirestore.instance
            .collection('indicators')
            .doc('lowStock')
            .set({'dateTime': now, 'haveChecked': true});

        await FirebaseFirestore.instance
            .collection('indicators')
            .doc('nearExpiry')
            .set({'dateTime': now, 'haveChecked': true});

        print("✅ Stock check and notification sent.");
      } else {
        print("⏳ Already checked today. Skipping.");
      }
    } catch (e) {
      print("❌ Error checking stock or expiry: $e");
    }
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



  void _initializeNotificationCheck() async {
    try {
      final lastSeen = LocalStorage.getLastSeenNotification();
      print("ℹ️ Local Last Seen: ${lastSeen?.toIso8601String() ?? 'Never'}");

      // 🔍 Fetch a limited number of recent history documents
      final allNotifications = await FirebaseFirestore.instance
          .collection('history')
          .orderBy('Date Updated', descending: true)
          .limit(10)
          .get();

      bool hasNew = false;

      print("📋 All 'Date Updated' values from Firestore:");
      for (final doc in allNotifications.docs) {
        final dateData = doc['Date Updated'];
        DateTime? docDate = dateData is String ? DateTime.tryParse(dateData) : null;

        final isNew = lastSeen == null || (docDate != null && docDate.isAfter(lastSeen));
        print("• ${docDate?.toIso8601String() ?? 'Invalid'} ${isNew ? '[NEW]' : '[OLD]'}");

        if (isNew) hasNew = true;
      }

      // ✅ Final result
      print("⚖️ Initial Check Result: ${hasNew ? 'NEW' : 'NO NEW'} notifications");
      hasNotification(hasNew);

      // 🔁 Realtime listener
      FirebaseFirestore.instance
          .collection('history')
          .orderBy('Date Updated', descending: true)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final latest = snapshot.docs.first;
          final dateData = latest['Date Updated'];
          DateTime? newDate = dateData is String ? DateTime.tryParse(dateData) : null;

          if (newDate != null) {
            final currentLastSeen = LocalStorage.getLastSeenNotification();
            final isNewRealtime = currentLastSeen == null || newDate.isAfter(currentLastSeen);

            print("🔥 Realtime Update: Latest Firestore Date: ${newDate.toIso8601String()}");
            print("🆚 Local Last Seen: ${currentLastSeen?.toIso8601String() ?? 'Never'}");
            print("➡️ ${isNewRealtime ? 'NEW NOTIFICATION' : 'NO NEW NOTIFICATION'}");

            hasNotification(isNewRealtime);
          }
        }
      });
    } catch (e) {
      print("❌ Error in notification check: $e");
      hasNotification(false);
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

            // Main UI
            Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Transform.scale(
                                scale: 1.3, // Increase to zoom in
                                child: Image.asset('assets/images/logo/AIMS LOGO.jpg', height:180),
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
                                style: TextStyle(
                                  color: MyColors.red,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              SizedBox(height: 20),
                              buildButton("STOCK ROOM", MyColors.white, MyColors.red, () => Get.to(() => StockRoomScreen())),
                              SizedBox(height: 20),
                              buildButton("TREATMENT AREA", MyColors.white, MyColors.red, () => Get.to(() => TreatmentAreaScreen())),
                              SizedBox(height: 20),
                              buildButton("GENERATE QR CODE", MyColors.white, MyColors.red, () => Get.to(() => GenerateQRCodeScreen())),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 30),
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
                                  "Version: ${AppVersion.version} (Build: ${AppVersion.build})",
                                  style: TextStyle(color: Colors.white, fontSize: 16),
                                ),
                                IconButton(
                                  icon: Icon(Icons.info_outline, color: Colors.white,),
                                  onPressed: () => _showTutorialDialog(context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🔔 Notification Drawer (keep it last so it's on top)
            if (isNotificationDrawerOpen) _buildNotificationDrawer(),
          ],
        ),
      ),
    );
  }






  Widget _buildAppBar() {
    return Obx(() => Container(
      color: MyColors.white,
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications,
                    size: 36,
                    ),
                onPressed: () async {
                  LocalStorage.saveLastSeenNotification(DateTime.now());
                  hasNotification(false);

                  setState(() {
                    isNotificationDrawerOpen = !isNotificationDrawerOpen;
                  });

                  if (isNotificationDrawerOpen) {
                    // 🔄 Always refresh notifications on open
                    notificationDocs.clear();
                    lastNotification = null;
                    hasMoreNotifications = true;
                    await _fetchNotifications();
                  }
                },
              ),
              if (hasNotification.value)
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
                onPressed: _showDatabaseSwitchDialog,
              ),
              IconButton(
                icon: Icon(Icons.logout, size: 28),
                onPressed: _showLogoutDialog,
              ),
            ],
          ),
        ],
      ),
    ));
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
                    final docData = data.data() as Map<String, dynamic>? ?? {}; // Add null check

                    return ListTile(
                      leading: Icon(Icons.history, color: MyColors.orange),
                      title: Text(
                        docData["Item Name"]?.toString() ?? "No Item Name", // Safe access
                        style: TextStyle(
                            color: MyColors.red, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${docData["Action"]?.toString() ?? "Action"}: "
                            "${docData["Quantity"] != null && docData["Quantity"] != 0 ? docData["Quantity"].toString() : docData["Quantity Added"]?.toString() ?? "N/A"} "
                            "(${docData["Category"]?.toString() ?? "Uncategorized"})",
                      ),
                      trailing: Text(
                        _formatTimestamp(docData["Date Updated"]),
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      onTap: () {
                        _showHistoryDetailsDialog(docData);
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
                          (entry.key == "Date Updated"
                              ? _formatTimestamp(entry.value)
                              : entry.value?.toString() ?? "N/A"), // Add null check
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
  void _showTutorialDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.8,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10,50,10,20),
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
                              fit: BoxFit.contain,
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
                            activeDotColor: MyColors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button positioned top right
                Positioned(
                  right: 8,
                  top: 8,
                  child: IconButton(
                    icon: Icon(Icons.close, color: MyColors.red),
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

