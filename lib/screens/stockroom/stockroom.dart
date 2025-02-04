
import 'package:aims_admin/screens/stockroom/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';


import '../../utils/colors.dart';
import 'inventory_screen.dart';

class StockRoomScreen extends StatelessWidget {
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
            "STOCK ROOM",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold, fontSize: 28),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1), // Adjust the distance from the top

            // QR Scanner Container
            Center(
              child: GestureDetector(
                onTap: () {
                  Get.to(() => QRScannerScreen());
                },
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: MyColors.darkRed, width: 3),
                        color: MyColors.darkRed,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 100,
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "QR SCANNER",
                      style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20), // Space between buttons

            // Inventory Container
            Center(
              child: GestureDetector(
                onTap: () {
                  Get.to(() => InventoryScreen());
                },
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: MyColors.orange, width: 3),
                        color: MyColors.orange,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.library_books_sharp,
                          color: Colors.white,
                          size: 100,
                        ),

                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "INVENTORY",
                      style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
