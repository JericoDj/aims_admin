import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:aims_admin/controllers/inventory_cofntroller.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screenshot/screenshot.dart';
import '../../utils/colors.dart';

class InventoryScreen extends StatelessWidget {
  final InventoryController _controller = Get.put(InventoryController());
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.photos.status.isGranted;
      }
      return await Permission.storage.status.isGranted;
    } else if (Platform.isIOS) {
      return await Permission.photosAddOnly.status.isGranted;
    }
    return false;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        await Permission.photos.request();
      } else {
        await Permission.storage.request();
      }
    } else if (Platform.isIOS) {
      await Permission.photosAddOnly.request();
    }
  }

  Future<void> _saveQRCodeToGallery(BuildContext context, String qrUrl, String itemName) async {
    if (_isSaving) return;
    _isSaving = true;

    Get.dialog(
      Center(child: CircularProgressIndicator(color: MyColors.red)),
      barrierDismissible: false,
    );

    try {
      if (!await _checkPermissions()) {
        await _requestPermissions();
        if (!await _checkPermissions()) {
          Get.back();
          Get.defaultDialog(
            title: "Permission Required",
            middleText: "Please enable storage permissions in app settings",
            textConfirm: "Open Settings",
            confirmTextColor: Colors.white,
            onConfirm: () async {
              await openAppSettings();
              Get.back();
            },
            textCancel: "Cancel",
          );
          return;
        }
      }

      final rawName = itemName;
      final sanitized = rawName
          .replaceAll(RegExp(r'[^\w\\s-]'), '')
          .replaceAll(' ', '_');

      final rawImage = await screenshotController.captureFromWidget(
        RepaintBoundary(
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  qrUrl,
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image, size: 150, color: Colors.red);
                  },
                ),
                SizedBox(height: 10),
                Text(
                  rawName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        pixelRatio: 3.0,
      );

      if (rawImage.isEmpty) throw Exception("Failed to generate QR image");

      final result = await SaverGallery.saveImage(
        rawImage,
        fileName: "${sanitized}_${DateTime.now().millisecondsSinceEpoch}",
        quality: 95,
        androidRelativePath: "Pictures/YourAppName",
        skipIfExists: false,
      );

      if (!result.isSuccess) throw Exception("Failed to save to gallery");

      Get.back();
      Get.snackbar(
        "Success!",
        "QR Code saved successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", ""),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSaving = false;
    }
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
                }
                return ListView.builder(
                  itemCount: _controller.filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _controller.filteredItems[index];
                    final itemName = item['name'] ?? "Unknown Item";
                    final category = item['category'] ?? "Unknown Category";
                    final qrData = item['qr_code_url'] ?? "";

                    return GestureDetector(
                      onTap: () => _showItemDetails(context, item),
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: MyColors.red, width: 1),
                        ),
                        child: ListTile(
                          title: Text(itemName,
                              style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.red)),
                          subtitle: Text("Category: $category"),
                          trailing: Image.network(
                            qrData,
                            height: 50,
                            width: 50,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              return progress == null
                                  ? child
                                  : SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.broken_image, size: 50, color: Colors.red);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    final itemName = item['name'] ?? "Unknown Item";
    final category = item['category'] ?? "Unknown Category";
    final quantity = item['quantity']?.toString() ?? "N/A";
    final expirationDate = item['expiration_date']?.toString() ?? "N/A";
    final qrData = item['qr_code_url'] ?? "";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Item Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _buildDetailRow("Name:", itemName),
                _buildDetailRow("Category:", category),
                _buildDetailRow("Stock:", quantity),
                _buildDetailRow("Expiry:", expirationDate),
                SizedBox(height: 16),
                Center(
                  child: Screenshot(
                    controller: screenshotController,
                    child: Image.network(
                      qrData,
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        return progress == null
                            ? child
                            : CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image, size: 200, color: Colors.red);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => _saveQRCodeToGallery(context, qrData, itemName),
                      child: Text("Save QR", style: TextStyle(color: MyColors.red)),
                    ),
                    TextButton(
                      onPressed: () => _controller.confirmDeleteItem(context, category, item['id'], itemName),
                      child: Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: Get.back,
                      child: Text("Close", style: TextStyle(color: MyColors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}