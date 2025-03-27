import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:aims_admin/controllers/inventory_cofntroller.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screenshot/screenshot.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../utils/colors.dart';

class InventoryScreen extends StatelessWidget {
  final InventoryController _controller = Get.put(InventoryController());
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        final status = await Permission.photos.status;
        return status.isGranted;
      } else {
        final status = await Permission.storage.status;
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.status;
      return status.isGranted;
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

  Future<void> _saveQRCodeToGallery(BuildContext context, String qrData, String itemName) async {
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
          .replaceAll(' ', '_')
          .substring(0, min(rawName.length, 50));

      // Capture the widget as image bytes
      final rawImage = await screenshotController.captureFromWidget(
        RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(


              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    gapless: false,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rawName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,

                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
        pixelRatio: 3.0,
      );

      if (rawImage.isEmpty) throw Exception("Failed to generate QR image");

      // Decode → Rotate → Flip
      final decoded = img.decodeImage(rawImage);
      if (decoded == null) throw Exception("Failed to decode image");
      final rotated = img.copyRotate(decoded, angle: 180);
      final flipped = img.flipHorizontal(rotated);
      final finalBytes = Uint8List.fromList(img.encodePng(flipped));

      final result = await SaverGallery.saveImage(
        finalBytes,
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
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyColors.darkRed,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: MyColors.white, size: 28),
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
                  prefixIcon: Icon(Icons.search, color: MyColors.red),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: MyColors.red),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_controller.filteredItems.isEmpty) {
                  return Center(child: Text("No items found.", style: TextStyle(color: MyColors.red)));
                }
                return ListView.builder(
                  itemCount: _controller.filteredItems.length,
                  itemBuilder: (context, index) {
                    var item = _controller.filteredItems[index];
                    String itemName = item['name'] ?? "Unknown Item";
                    String category = item['category'] ?? "Unknown Category";
                    String qrData = item['qr_code_url'] ?? "";

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: MyColors.red),
                      ),
                      child: ListTile(
                        title: Text(itemName, style: TextStyle(color: MyColors.red)),
                        subtitle: Text("Category: $category"),
                        trailing: QrImageView(
                          data: qrData,
                          size: 50,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        onTap: () => _showItemDetails(context, item),
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
    String itemName = item['name'] ?? "Unknown Item";
    String category = item['category'] ?? "Unknown Category";
    String quantity = item['quantity']?.toString() ?? "N/A";
    String expirationDate = item['expiration_date']?.toString() ?? "N/A";
    String qrData = item['qr_code_url'] ?? "";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Item Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _buildDetailRow("Name:", itemName),
                _buildDetailRow("Category:", category),
                _buildDetailRow("Stock:", quantity),
                _buildDetailRow("Expiry:", expirationDate),
                SizedBox(height: 16),
                Center(
                  child: Screenshot(
                    controller: screenshotController,
                    child: QrImageView(
                      data: qrData,
                      size: 150,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
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
          Text(value),
        ],
      ),
    );
  }
}