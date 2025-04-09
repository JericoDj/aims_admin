import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/edit_item_dialog_controller.dart';

class EditItemDialog extends StatelessWidget {
  final String category;
  final String itemName;
  final String brand;
  final Map<String, String> itemData;

  EditItemDialog({
    required this.category,
    required this.itemName,
    required this.itemData,
    required this.brand,
  });

  @override
  Widget build(BuildContext context) {
    final EditItemController controller = Get.put(EditItemController());

    // Pre-fill text fields with data
    controller.quantityController.text = itemData["available_stock"] ?? "0";
    controller.expirationController.text = itemData["expiration_date"] ?? "";

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
            _itemDetail("Category", category), // ✅ Display category
            _itemDetail("Item Name", itemName), // ✅ Display item name
            _itemDetail("Brand", itemData["brand"] ?? "N/A"),
            _itemDetail("Serial No.", itemData["serial_no"] ?? "N/A"),
            _itemDetail("Available Stock", itemData["available_stock"] ?? "0"),
            _itemDetail("Unit of Measurement", itemData["unit_measurement"] ?? "N/A"),
            _itemDetail("Specifications", itemData["specifications"] ?? "N/A"),
            _itemDetail("Storage Code", itemData["storage_code"] ?? "N/A"),

            SizedBox(height: 10),

            // Editable Quantity Field
            Text("Enter Quantity to Add", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            TextField(
              controller: controller.quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter quantity to add",
              ),
            ),

            SizedBox(height: 10),

            // Editable Expiration Date Field
            Text("Enter Expiration Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            TextField(
              controller: controller.expirationController,
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
            controller.updateItemInFirestore(category, itemName, brand);
            Get.back();
          },
          child: Text("UPDATE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: () => Get.back(),
          child: Text("CLOSE", style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  /// **Reusable UI Widget for Item Details**
  Widget _itemDetail(String label, String value) {
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
