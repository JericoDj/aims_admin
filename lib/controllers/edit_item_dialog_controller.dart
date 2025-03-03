import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditItemController extends GetxController {
  TextEditingController quantityController = TextEditingController();
  TextEditingController expirationController = TextEditingController();

  /// **Update Firestore with new quantity and expiration date**
  void updateItemInFirestore(String category, String itemName) async {
    try {
      if (category.isEmpty || itemName.isEmpty) {
        Get.snackbar("Error", "Category or Item Name is missing!");
        return;
      }

      print("🛠️ Updating Firestore...");
      print("Category: $category, Item: $itemName");
      print("Quantity: ${quantityController.text}, Expiration: ${expirationController.text}");

      // Reference the Firestore document
      DocumentReference itemRef = FirebaseFirestore.instance
          .collection("categories")
          .doc(category)
          .collection("items")
          .doc(itemName);

      DocumentSnapshot itemSnapshot = await itemRef.get();
      if (!itemSnapshot.exists) {
        print("❌ Error: Item does not exist in Firestore.");
        Get.snackbar("Error", "Item does not exist in Firestore.");
        return;
      }

      int currentStock = int.tryParse(itemSnapshot.get("available_stock").toString()) ?? 0;
      int addedQuantity = int.tryParse(quantityController.text) ?? 0;
      int updatedStock = currentStock + addedQuantity;

      // Update Firestore
      await itemRef.update({
        "available_stock": updatedStock,
        "expiration_date": expirationController.text.isNotEmpty ? expirationController.text : "N/A",
      });

      Get.snackbar("Success", "Item updated successfully.");
      print("✅ Firestore update successful! New Stock: $updatedStock");

    } catch (e) {
      print("❌ Error updating Firestore: $e");
      Get.snackbar("Error", "Failed to update item: $e");
    }
  }
}
