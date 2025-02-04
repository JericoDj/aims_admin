import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/colors.dart';


class QRScannerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: MyColors.white,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 40, // Adjusted container size (small but fits icon)
              width: 40,  // Ensure it's a perfect square
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyColors.darkRed,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: MyColors.white, size: 28), // Increased icon size
                padding: EdgeInsets.zero, // Removes extra padding inside the button
                constraints: BoxConstraints(), // Prevents extra spacing issues
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ),
          title: Text(
            "QR SCANNER",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold, fontSize: 28),
          ),
        ),
        body: Center(
          child: ElevatedButton(

            onPressed: () {
              // Simulate QR Scan & Show Dialog
              showItemDialog(context);
            },
            style: ElevatedButton.styleFrom(

              backgroundColor: MyColors.darkRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10))
              ),

              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: Text("Simulate Scan", style: TextStyle(color: Colors.white,fontSize: 22)),
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
            style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.red, fontSize: 24),
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
                Text("Enter Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: MyColors.red)),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter quantity",
                    hintStyle: TextStyle(fontSize: 18), // Adjust hint text size
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12), // Adjust padding for field size
                  ),
                  style: TextStyle(fontSize: 18), // Adjust text size inside TextField
                ),

                SizedBox(height: 10),

// Expiration Date Input Field
                Text(
                  "Enter Expiration Date",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: MyColors.red), // Adjust label text size
                ),
                TextField(
                  controller: expirationController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: "YYYY-MM-DD",
                    hintStyle: TextStyle(fontSize: 18), // Adjust hint text size
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12), // Adjust padding for field size
                  ),
                  style: TextStyle(fontSize: 18), // Adjust text size inside TextField
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
              child: Text("ADD", style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold, fontSize: 18)),
            ),

            // Close Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text("CLOSE", style: TextStyle(color: MyColors.red, fontSize: 18)),
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18)),
          Text(value, style: TextStyle(color: MyColors.darkRed, fontSize: 18)),
        ],
      ),
    );
  }
}
