import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../widgets/create_account_dialog.dart';
import 'package:dio/dio.dart' as dio; // Rename Dio's Response class

class ManageAccounts extends StatefulWidget {
  const ManageAccounts({Key? key}) : super(key: key);

  @override
  _ManageAccountsState createState() => _ManageAccountsState();
}

class _ManageAccountsState extends State<ManageAccounts> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Manage Accounts", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: MyColors.red,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection("users").orderBy(
            "createdAt", descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: MyColors.red));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No accounts found.",
                style: TextStyle(fontSize: 16,
                    color: MyColors.red,
                    fontWeight: FontWeight.w500),
              ),
            );
          }

          var users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: MyColors.orange, width: 1.5),
                ),
                elevation: 3,
                child: ListTile(
                  leading: Icon(
                    user["role"] == "Admin" ? Icons.admin_panel_settings : Icons
                        .person,
                    color: MyColors.orange,
                  ),
                  title: Text(
                    user["name"],
                    style: const TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  subtitle: Text(
                    user["role"],
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () =>
                        _showAccountDeletionDialog(
                            user["uid"], user.id, user["name"], user["role"]),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.dialog(CreateAccountDialog());
        },
        backgroundColor: MyColors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// **Step 1: Show "Account Deletion" Dialog**
  void _showAccountDeletionDialog(String uid, String docId, String fullName,
      String role) {
    Get.dialog(
      AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Account Deletion", style: TextStyle(
                color: MyColors.red, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => Get.back(),
              child: Icon(Icons.close, color: Colors.red),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                "Are you sure you want to delete", textAlign: TextAlign.center),
            Text("\"$fullName\"?", textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18,
                    color: MyColors.red,
                    fontWeight: FontWeight.bold)),
            Text("'$role' account", textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text("Cancel",
                    style: TextStyle(color: MyColors.red, fontSize: 16)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: MyColors.red),
                onPressed: () {
                  Get.back();
                  _showSlideToConfirmDialog(uid, docId, fullName, role);
                },
                child: Text("Confirm",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// **Step 2: Show "Slide to Confirm Deletion" Dialog**
  void _showSlideToConfirmDialog(String uid, String docId, String fullName,
      String role) {
    Get.dialog(
      AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Slide to Confirm Deletion", style: TextStyle(
                color: MyColors.red,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
            GestureDetector(
              onTap: () => Get.back(),
              child: Icon(Icons.close, color: Colors.red),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "This action cannot be undone.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              "Are you sure you want to permanently delete:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              "\"$fullName\"",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18,
                  color: MyColors.red,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "'$role' account",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            _buildSlideToDelete(uid, docId, fullName, role), // Slide button
          ],
        ),
      ),
    );
  }

  /// **Step 3: Slide to Confirm Delete**
  Widget _buildSlideToDelete(String uid, String docId, String fullName,
      String role) {
    double buttonWidth = 280.0;
    double draggableSize = 50.0;
    double dragPosition = 0.0;
    bool dragReachedEnd = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
          children: [
            Container(
              width: buttonWidth,
              height: 50,
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15)),
              alignment: Alignment.center,
              child: const Text("Slide to Confirm Delete", style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
            ),
            Positioned(
              left: dragPosition,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    dragPosition += details.delta.dx;
                    if (dragPosition < 0) dragPosition = 0;
                    if (dragPosition > buttonWidth - draggableSize) {
                      dragPosition = buttonWidth - draggableSize;
                      dragReachedEnd = true;
                    } else {
                      dragReachedEnd = false;
                    }
                  });
                },
                onHorizontalDragEnd: (_) {
                  if (dragReachedEnd) {
                    _deleteUser(uid, docId);
                    Get.back();
                  } else {
                    setState(() {
                      dragPosition = 0;
                    });
                  }
                },
                child: _buildDraggableIcon(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// **Draggable Icon UI**
  Widget _buildDraggableIcon() {
    return Container(
      height: 50,
      width: 50,
      decoration: const BoxDecoration(color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)]),
      child: const Icon(Icons.arrow_forward, color: Colors.red),
    );
  }


  /// **Delete User from Firebase Authentication via Cloud Function using Dio**
  /// **Delete User from Firebase Authentication via Cloud Function using Dio**
  Future<void> _deleteUser(String uid, String docId) async {
    try {
      // 🔹 Cloud Function URL (Make sure it's correct)
      String functionUrl = "https://deleteuser-eh5kbvz3vq-uc.a.run.app";

      dio.Dio httpClient = dio.Dio();

      debugPrint("📡 Calling Cloud Function: $functionUrl with UID: $uid");

      // Step 1: Call Cloud Function to delete from Firebase Authentication
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
        // Step 2: Delete from Firestore **only if authentication deletion succeeds**
        await FirebaseFirestore.instance.collection("users")
            .doc(docId)
            .delete();

        Get.snackbar("Success", "User deleted successfully!",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar("Error",
            "Failed to delete user from authentication. Response: ${response
                .data}",
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      debugPrint("🔥 Error deleting user: $e");
      Get.snackbar("Error", "Failed to delete user: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }
}