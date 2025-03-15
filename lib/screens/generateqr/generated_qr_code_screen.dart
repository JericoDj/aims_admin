import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';

import '../../utils/colors.dart';

class GeneratedQRCodeScreen extends StatefulWidget {
  final Map<String, String> itemDetails;

  GeneratedQRCodeScreen({required this.itemDetails});

  @override
  _GeneratedQRCodeScreenState createState() => _GeneratedQRCodeScreenState();
}

class _GeneratedQRCodeScreenState extends State<GeneratedQRCodeScreen> {
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isPickingFile = false;

  /// ✅ Save QR Code to User Selected Directory
  Future<void> _saveQRCodeToGallery(BuildContext context) async {
    if (_isPickingFile) return;
    _isPickingFile = true;

    try {
      // ✅ Capture QR Code as Image
      Uint8List? image = await screenshotController.captureFromWidget(
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: QrImageView(
            data: widget.itemDetails.entries.map((e) => "${e.key}: ${e.value}").join("\n"),
            version: QrVersions.auto,
            size: 200,
            gapless: false,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
        ),
        pixelRatio: 4.0,
      );

      // ✅ Ensure Image Captured
      if (image == null) {
        Get.snackbar("Error", "QR Code capture failed.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // ✅ Prompt User for Directory
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
      if (selectedDirectory == null) {
        Get.snackbar("Error", "No folder selected.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // ✅ Save QR Code Image
      final String filePath = "$selectedDirectory/qr_code_${DateTime.now().millisecondsSinceEpoch}.png";
      File file = File(filePath);
      await file.writeAsBytes(image);

      // ✅ Refresh Gallery for Android
      if (Platform.isAndroid) await refreshGallery(filePath);

      // ✅ Success Message
      Get.snackbar("Success", "QR Code saved to: $filePath", backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar("Error", "Failed to save QR Code: $e", backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      _isPickingFile = false; // ✅ Reset Flag
    }
  }

  /// ✅ Refresh Gallery to Show Saved Image on Android
  Future<void> refreshGallery(String filePath) async {
    try {
      if (Platform.isAndroid) {
        await Process.run('am', [
          'broadcast',
          '-a',
          'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
          '-d',
          'file://$filePath'
        ]);
      }
    } catch (e) {
      debugPrint("Gallery refresh failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String itemName = widget.itemDetails['item_name'] ?? "Unknown Item";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.red,
        centerTitle: true,
        title: const Text(
          "Generated QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ QR Code + Item Name in Screenshot Wrapper
              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: MyColors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: widget.itemDetails.entries.map((e) => "${e.key}: ${e.value}").join("\n"),
                        version: QrVersions.auto,
                        size: 200,
                        gapless: false,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        itemName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: MyColors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ✅ Save QR Code Button
              ElevatedButton(
                onPressed: () => _saveQRCodeToGallery(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text(
                  "Save QR Code",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),

              const SizedBox(height: 20),

              // ✅ Item Details Below QR Code
              Column(
                children: widget.itemDetails.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${entry.key}:", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(color: MyColors.red),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
