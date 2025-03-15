import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/notification_controller.dart';

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

      // **Send Notification to All Users**
      NotificationController notificationController = Get.find(); // Get the controller instance
      await notificationController.sendNotificationToAllUsers(
          "Update from: $itemName",
          "${quantityController.text}, Expiration: ${expirationController.text}. Check it out!"
      );

      // Fetch the updated document and print it
      DocumentSnapshot updatedSnapshot = await itemRef.get();
      print("✅ Firestore update successful! New Data:");
      print("📌 Item: $itemName");
      print("📦 Available Stock: ${updatedSnapshot.get("available_stock")}");
      print("📅 Expiration Date: ${updatedSnapshot.get("expiration_date")}");

      Get.snackbar("Success", "Item updated successfully.");

    } catch (e) {
      print("❌ Error updating Firestore: $e");
      Get.snackbar("Error", "Failed to update item: $e");
    }
  }
}
