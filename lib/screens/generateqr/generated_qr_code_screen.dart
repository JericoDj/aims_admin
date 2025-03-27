import 'dart:io';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screenshot/screenshot.dart';
import '../../utils/colors.dart';

class GeneratedQRCodeScreen extends StatefulWidget {
  final Map<String, String> itemDetails;

  const GeneratedQRCodeScreen({super.key, required this.itemDetails});

  @override
  State<GeneratedQRCodeScreen> createState() => _GeneratedQRCodeScreenState();
}

class _GeneratedQRCodeScreenState extends State<GeneratedQRCodeScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSaving = false;

  // Enhanced permission handling
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

  Future<void> _saveQRCodeToGallery() async {
    if (_isSaving) return;
    _isSaving = true;

    try {
      if (!await _checkPermissions()) {
        await _requestPermissions();
        if (!await _checkPermissions()) {
          Get.snackbar("Error", "Permission required to save files",
              backgroundColor: Colors.red, colorText: Colors.white);
          return;
        }
      }

      final rawName = widget.itemDetails['item_name'] ?? "QR_Item";
      final sanitized = rawName.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');

      final rawImage = await _screenshotController.capture();
      if (rawImage == null) {
        throw Exception("Failed to capture QR code");
      }

// Decode the image
      final decoded = img.decodeImage(rawImage);
      if (decoded == null) throw Exception("Image decode failed");

// Rotate 180 degrees
      final rotated = img.copyRotate(decoded, angle: 180);

// Flip horizontally to undo mirror effect
      final flipped = img.flipHorizontal(rotated);

// Encode as PNG
      final finalBytes = Uint8List.fromList(img.encodePng(flipped));

      final result = await SaverGallery.saveImage(
        finalBytes,
        fileName: "${sanitized}_${DateTime.now().millisecondsSinceEpoch}",
        quality: 100,
        androidRelativePath: "Pictures/YourAppName",
        skipIfExists: false,
      );
      if (result.isSuccess) {
        Get.snackbar("Success", "QR Code saved as $sanitized!",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        throw Exception("Gallery save returned false");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to save QR Code: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      _isSaving = false;
    }
  }


  @override
  Widget build(BuildContext context) {
    final itemName = widget.itemDetails['item_name'] ?? "Unknown Item";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.red,
        title: const Text("Generated QR Code",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: Get.back,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Screenshot(
                controller: _screenshotController,
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
                        data: widget.itemDetails.entries
                            .map((e) => "${e.key}: ${e.value}")
                            .join("\n"),
                        version: QrVersions.auto,
                        size: 200,
                        gapless: false,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                      const SizedBox(height: 10),
                      Text(itemName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: MyColors.red,
                          )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveQRCodeToGallery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 15),
                ),
                child: Text(
                    _isSaving ? "Saving..." : "Save QR Code",
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
              const SizedBox(height: 20),
              ...widget.itemDetails.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${entry.key}:",
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(entry.value,
                          style: TextStyle(color: MyColors.red),
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}