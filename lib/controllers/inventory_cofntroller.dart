import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable list for storing inventory items
  var allItems = <Map<String, dynamic>>[].obs;
  var filteredItems = <Map<String, dynamic>>[].obs;

  // Text editing controller for search
  var searchController = TextEditingController();

  // List of categories to fetch
  final List<String> categories = [
    "Medical_Equipments",
    "Medical_Supplies",
    "Medical_Drugs",
    "Dental",
    "Miscellaneous",
    "Office Equipment",
    "Office Supplies"
  ];

  @override
  void onInit() {
    super.onInit();
    fetchInventory(); // Fetch data when the controller initializes
  }

  /// Fetch inventory data from Firestore (Only from predefined categories)
  Future<void> fetchInventory() async {
    try {
      List<Map<String, dynamic>> fetchedItems = [];

      print("Fetching inventory from selected categories...");

      for (String category in categories) {
        print("Fetching items for category: $category");

        // Fetch items inside the selected category's "items" subcollection
        QuerySnapshot itemsSnapshot = await _firestore
            .collection("stock")
            .doc(category) // Specific category document
            .collection("items") // Access the "items" subcollection
            .get();

        print("Items found in $category: ${itemsSnapshot.size}");

        for (var itemDoc in itemsSnapshot.docs) {
          print("Item Data: ${itemDoc.data()}"); // Debugging log

          fetchedItems.add({
            "id": itemDoc.id,
            "name": itemDoc["item_name"] ?? "Unknown Item",
            "brand": itemDoc["brand"] ?? "Unknown",
            "quantity": itemDoc["quantity"] ?? 0,
            "category": category, // Use category from list
            "expiration_date": itemDoc["expiration_date"] ?? "N/A",
            "qr_code_url": itemDoc["qr_code_url"] ?? "",
          });
        }
      }

      // Update the observable lists
      allItems.assignAll(fetchedItems);
      filteredItems.assignAll(fetchedItems);

      print("✅ Inventory Fetched Successfully! Total Items: ${allItems.length}");
    } catch (e) {
      print("❌ Error fetching inventory: $e");
      Get.snackbar("Error", "Failed to load inventory.");
    }
  }

  /// Filter items based on search query
  void filterSearch(String query) {
    if (query.isEmpty) {
      filteredItems.assignAll(allItems); // Reset to all items
    } else {
      filteredItems.assignAll(allItems.where((item) {
        return item["name"].toString().toLowerCase().contains(query.toLowerCase()) ||
            item["brand"].toString().toLowerCase().contains(query.toLowerCase()) ||
            item["category"].toString().toLowerCase().contains(query.toLowerCase());
      }).toList());
    }
  }

  /// Function to confirm and delete item from Firestore and Firebase Storage

  /// Function to confirm deletion before proceeding
  Future<void> confirmDeleteItem(BuildContext context, String category, String itemId, String itemName) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Confirm Deletion", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete this item? This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext), // Close the confirmation dialog
              child: Text("Cancel", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext); // Close confirmation dialog before deleting
                Navigator.pop(dialogContext); // Close confirmation dialog before deleting
                await deleteItem(category, itemId, itemName);
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// Function to delete item from Firestore and its QR code from Firebase Storage
  /// Function to delete item from Firestore and its corresponding QR code image from Firebase Storage
  Future<void> deleteItem(String category, String itemId, String itemName) async {
    try {
      // Convert category and itemName to correct format
      String formattedCategory = category.replaceAll(" ", "_");
      String formattedItemName = itemName.replaceAll(" ", "_");
      String qrCodePath = "qr_codes/$formattedCategory/qr_$formattedItemName.png";

      // Delete Firestore document
      await FirebaseFirestore.instance
          .collection("stock")
          .doc(category)
          .collection("items")
          .doc(itemId)
          .delete();

      print("✅ Firestore document deleted successfully");

      // Delete from Firebase Storage
      try {
        await FirebaseStorage.instance.ref(qrCodePath).delete();
        print("✅ QR Code deleted from Storage: $qrCodePath");
      } catch (e) {
        print("⚠️ QR Code not found in Storage: $qrCodePath");
      }

      // Show success notification
      Get.snackbar(
        "Success",
        "Item and QR Code deleted successfully",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      refreshInventory(); // Refresh inventory list after deletion
    } catch (e) {
      print("❌ Error deleting item: $e");
      Get.snackbar(
        "Error",
        "Failed to delete item: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }


  /// Refresh inventory data
  void refreshInventory() {
    fetchInventory(); // Refresh all categories
  }
}
