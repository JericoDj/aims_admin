import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/colors.dart';


class QRScannerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: MyColors.red,
          centerTitle: true,
          title: Text(
            "QR SCANNER",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), // White back button
            onPressed: () {
              Get.back(); // Navigates back
            },
          ),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              // Simulate QR Scan & Show Dialog
              showItemDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.red,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text("Simulate Scan", style: TextStyle(color: Colors.white,fontSize: 18)),
          ),
        ),
      ),
    );
  }

  // Function to Show Dialog After Scanning
  void showItemDialog(BuildContext context) {
    TextEditingController quantityController = TextEditingController();
    TextEditingController expirationController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "ADD ITEM",
            style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.red),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                itemDetail("Storage Code", "STG-001"),
                itemDetail("Serial No.", "SN12345678"),
                itemDetail("Available On Hand", "25"),
                itemDetail("Item Name", "Medical Syringe"),
                itemDetail("Brand", "MediTech"),
                itemDetail("Unit of Measurement", "Box"),
                itemDetail("Specifications", "Sterile, 10ml"),
                itemDetail("Category", "Medical Supplies"),

                SizedBox(height: 10),

                // Quantity Input Field
                Text("Enter Quantity", style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter quantity",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                ),

                SizedBox(height: 10),

                // Expiration Date Input Field
                Text("Enter Expiration Date", style: TextStyle(fontWeight: FontWeight.bold)),
                TextField(
                  controller: expirationController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            // Save Button
            TextButton(
              onPressed: () {
                String quantity = quantityController.text;
                String expiration = expirationController.text;

                if (quantity.isEmpty || expiration.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter both Quantity and Expiration Date")),
                  );
                  return;
                }

                // Process input data
                print("Quantity: $quantity, Expiration: $expiration");

                Navigator.pop(context); // Close dialog
              },
              child: Text("ADD", style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
            ),

            // Close Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text("CLOSE", style: TextStyle(color: MyColors.red)),
            ),
          ],
        );
      },
    );
  }


  // Helper Function for Item Detail Row
  Widget itemDetail(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: MyColors.red)),
        ],
      ),
    );
  }
}
