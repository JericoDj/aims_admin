import 'dart:io';
import 'dart:typed_data';
import 'package:aims_admin/controllers/inventory_cofntroller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import '../../utils/colors.dart';

class InventoryScreen extends StatelessWidget {
  final InventoryController _controller = Get.put(InventoryController());
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isPickingFile = false;

  Future<void> _saveQRCodeToGallery(BuildContext context, String imageUrl, String itemName) async {
    if (_isPickingFile) return;
    _isPickingFile = true;

    try {
      Uint8List? image = await screenshotController.captureFromWidget(
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white, // Ensures the background is white
            border: Border.all(color: Colors.black, width: 2), // Adds border
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                imageUrl,
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 10),
              Text(
                itemName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        pixelRatio: 4.0,
      );

      if (image == null) {
        Get.snackbar("Error", "QR Code capture failed.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        Get.snackbar("Error", "No folder selected.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      final String filePath = "$selectedDirectory/qr_code_${DateTime.now().millisecondsSinceEpoch}.png";
      File file = File(filePath);
      await file.writeAsBytes(image);

      Get.snackbar("Success", "QR Code saved to: $filePath", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to save QR Code: $e", backgroundColor: Colors.red, colorText: Colors.white);
    }
    _isPickingFile = false;
  }


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
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyColors.darkRed,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: MyColors.white, size: 36),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ),
          title: Text(
            "INVENTORY",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold, fontSize: 28),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: MyColors.red),
              onPressed: _controller.refreshInventory,
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: _controller.searchController,
                onChanged: _controller.filterSearch,
                decoration: InputDecoration(
                  hintText: "Search item...",
                  hintStyle: TextStyle(fontSize: 20),
                  prefixIcon: Icon(Icons.search, color: MyColors.red, size: 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: MyColors.red),
                  ),
                ),
                style: TextStyle(fontSize: 18),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_controller.filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      "No items found.",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.red),
                    ),
                  );
                } else {
                  return ListView.builder(
                    itemCount: _controller.filteredItems.length,
                    itemBuilder: (context, index) {
                      var item = _controller.filteredItems[index];
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text("Item Details", style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Name: ${item['name']}", style: TextStyle(fontSize: 18)),
                                    Text("Category: ${item['category']}", style: TextStyle(fontSize: 18)),
                                    Text("Available Stock: ${item['available_stock']}", style: TextStyle(fontSize: 18)),
                                    Text("Expiration Date: ${item['expiration_date']}", style: TextStyle(fontSize: 18)),
                                    SizedBox(height: 10),
                                    Center(
                                      child: Screenshot(
                                        controller: screenshotController,
                                        child: Image.network(
                                          "${item['qr_code_url']}",
                                          height: 100,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => _saveQRCodeToGallery(context, item['qr_code_url'], item['name']),
                                    child: Text("Save QR Code", style: TextStyle(color: MyColors.red)),
                                  ),

                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Close", style: TextStyle(color: MyColors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Card(
                          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: MyColors.red, width: 1),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${item['name']}",
                                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MyColors.red),
                                    ),
                                    Text("Category: ${item['category']}", style: TextStyle(fontSize: 18)),
                                    Text("Available Stock: ${item['available_stock']}", style: TextStyle(fontSize: 18)),
                                    Text("Expiration Date: ${item['expiration_date']}", style: TextStyle(fontSize: 18)),
                                  ],
                                ),
                                Container(
                                  height: 50,
                                  child: Image.network("${item['qr_code_url']}"),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}