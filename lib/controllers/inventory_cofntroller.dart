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

  @override
  void onInit() {
    super.onInit();
    fetchInventory("Miscellaneous");
    // Fetch data when the controller is initialized
  }

  /// Fetch inventory data from Firestore
  Future<void> fetchInventory(String category) async {
    try {
      List<Map<String, dynamic>> fetchedItems = [];

      // Fetch all items inside the selected category's "items" subcollection
      QuerySnapshot itemsSnapshot = await _firestore
          .collection("stock")
          .doc(category) // Specific category document
          .collection("items") // Access the "items" subcollection
          .get();

      print("Total items found: ${itemsSnapshot.size}"); // Debugging count

      for (var itemDoc in itemsSnapshot.docs) {
        fetchedItems.add({
          "id": itemDoc.id,
          "name": itemDoc["item_name"] ?? "Unknown Item",
          "brand": itemDoc["brand"] ?? "Unknown",
          "category": itemDoc["category"] ?? "No Category",
          "expiration_date": itemDoc["expiration_date"] ?? "N/A",
          "qr_code_url": itemDoc["qr_code_url"] ?? "",
        });
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
            item["serial"].toString().toLowerCase().contains(query.toLowerCase()) ||
            item["category"].toString().toLowerCase().contains(query.toLowerCase());
      }).toList());
    }
  }

  /// Refresh inventory data
  void refreshInventory() {
    fetchInventory("Miscellaneous");

  }
}
