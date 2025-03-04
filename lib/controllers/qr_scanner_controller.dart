import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerController extends GetxController {
  final MobileScannerController scannerController = MobileScannerController();
  var isScanning = true.obs;

  /// **Fetch item details from Firestore using scanned QR data**
  void fetchItemDetails(String scannedData, BuildContext context) async {
    try {
      String category = extractCategoryFromQR(scannedData);
      String itemName = extractItemNameFromQR(scannedData);

      print("🔍 Fetching from Firestore: Category - $category | Item - $itemName");

      DocumentSnapshot itemDoc = await FirebaseFirestore.instance
          .collection("stock/category/$category/items")
          .doc(itemName)
          .get();

      if (itemDoc.exists) {
        Map<String, dynamic> itemData = itemDoc.data() as Map<String, dynamic>;
        showItemDialog(context, itemData, category, itemName);
      } else {
        Get.snackbar("Not Found", "Item does not exist in the database.");
        restartScanning();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch item details: $e");
      restartScanning();
    }
  }

  /// **Show dialog to edit quantity and expiration date**
  void showItemDialog(BuildContext context, Map<String, dynamic> itemData, String category, String itemName) {
    TextEditingController quantityController = TextEditingController(text: itemData["available_stock"]?.toString() ?? "0");
    TextEditingController expirationController = TextEditingController(text: itemData["expiration_date"] ?? "");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "EDIT ITEM",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 24),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                itemDetail("Storage Code", itemData["storage_code"] ?? "N/A"),
                itemDetail("Serial No.", itemData["serial_no"] ?? "N/A"),
                itemDetail("Available Stock", itemData["available_stock"]?.toString() ?? "0"),
                itemDetail("Item Name", itemData["item_name"] ?? "N/A"),
                itemDetail("Brand", itemData["brand"] ?? "N/A"),
                itemDetail("Unit of Measurement", itemData["unit_measurement"] ?? "N/A"),
                itemDetail("Specifications", itemData["specifications"] ?? "N/A"),
                itemDetail("Category", itemData["category"] ?? "N/A"),

                SizedBox(height: 10),

                Text("Enter Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),

                SizedBox(height: 10),

                Text("Enter Expiration Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                TextField(
                  controller: expirationController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                updateItemInFirestore(category, itemName, quantityController.text, expirationController.text);
                Navigator.pop(context);
              },
              child: Text("UPDATE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("CLOSE", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  /// **Update Firestore with new quantity and expiration date**
  void updateItemInFirestore(String category, String itemName, String quantity, String expiration) async {
    try {
      await FirebaseFirestore.instance.collection("stock/$category/items").doc(itemName).update({
        "available_stock": int.parse(quantity),
        "expiration_date": expiration,
      });

      Get.snackbar("Success", "Item updated successfully.");
      restartScanning();
    } catch (e) {
      Get.snackbar("Error", "Failed to update item: $e");
    }
  }

  /// **Extract category from scanned QR data**
  String extractCategoryFromQR(String qrData) {
    return qrData.split("\n").firstWhere((line) => line.startsWith("Category:")).split(":")[1].trim();
  }

  /// **Extract item name from scanned QR data**
  String extractItemNameFromQR(String qrData) {
    return qrData.split("\n").firstWhere((line) => line.startsWith("Item Name:")).split(":")[1].trim();
  }

  /// **Restart scanner after an action**
  void restartScanning() {
    scannerController.start();
    isScanning.value = true;
  }

  /// **Reusable UI Widget for Item Details**
  Widget itemDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
