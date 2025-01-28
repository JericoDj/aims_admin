
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
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: MyColors.red,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Get.back();
            },
          ),
          title: Text(
            "STOCK ROOM",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                        border: Border.all(color: MyColors.red, width: 3),
                        color: MyColors.orange,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 100,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "QR SCANNER",
                      style: TextStyle(fontSize: 16, color: MyColors.red, fontWeight: FontWeight.bold),
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
                        border: Border.all(color: MyColors.red, width: 3),
                        color: MyColors.orange,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.inventory,
                          color: Colors.white,
                          size: 100,
                        ),

                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "INVENTORY",
                      style: TextStyle(fontSize: 16, color: MyColors.red, fontWeight: FontWeight.bold),
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
