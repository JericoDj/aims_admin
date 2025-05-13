import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/notification_controller.dart';

class EditItemController extends GetxController {
  TextEditingController quantityController = TextEditingController();
  TextEditingController expirationController = TextEditingController();

  /// ✅ Helper to sanitize Firestore IDs (matches your QR generator)
  String generateDocumentId(String brand, String itemName) {
    return brand.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), "_") +
        "_" +
        itemName.trim().toLowerCase().replaceAll(RegExp(r'[^\w]'), "_");
  }


  /// ✅ Main Firestore Update Logic
  void updateItemInFirestore(String category, String itemName, String brand) async {
    try {
      if (category.isEmpty || itemName.isEmpty || brand.isEmpty) {
        Get.snackbar("Error", "Category, Item Name, or Brand is missing!");
        return;
      }

      final String documentId = generateDocumentId(brand, itemName);
      final String sanitizedCategory = category.replaceAll(" ", "_");

      print("🛠️ Updating Firestore at:");
      print("→ stock/$sanitizedCategory/items/$documentId");
      print("→ Quantity to add: ${quantityController.text}");
      print("→ Expiration: ${expirationController.text}");

      final itemRef = FirebaseFirestore.instance
          .collection("stock")
          .doc(sanitizedCategory)
          .collection("items")
          .doc(documentId);

      final itemSnapshot = await itemRef.get();

      if (!itemSnapshot.exists) {
        print("❌ Error: Document does not exist at the expected path.");
        Get.snackbar("Error", "Item not found in Firestore.");
        return;
      }

      final currentQuantity = int.tryParse(itemSnapshot.get("quantity").toString()) ?? 0;
      final addedQuantity = int.tryParse(quantityController.text.trim()) ?? 0;

      final updatedQuantity = currentQuantity + addedQuantity;

      // 🔄 Update Firestore document
      await itemRef.update({
        "quantity": updatedQuantity,
        "expiration_date":
        expirationController.text.trim().isNotEmpty ? expirationController.text.trim() : "N/A",
      });

      print("✅ Updated successfully: New Quantity = $updatedQuantity");

      // 🔔 Send notification
      final NotificationController notificationController = Get.find();
      await notificationController.sendNotificationToAllUsers(
        "Stock Updated: $itemName",
        "Added $addedQuantity units → Total: $updatedQuantity",
      );

      Get.snackbar("Success", "$itemName stock updated!", snackPosition: SnackPosition.BOTTOM);

    } catch (e) {
      print("❌ Error updating Firestore: $e");
      Get.snackbar("Error", "Failed to update item: $e");
    }
  }
}
