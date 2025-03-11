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
  late ScreenshotController screenshotController;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    screenshotController = ScreenshotController();
  }

  /// ✅ Function to Capture and Save QR Code with Item Name
  Future<void> _saveQRCodeToGallery(BuildContext context) async {
    if (_isPickingFile) return;
    _isPickingFile = true;

    if (await _requestStoragePermission()) {
      try {
        Uint8List? image = await screenshotController.capture(
          pixelRatio: 4.0, // ✅ High DPI for clear image
        );

        if (image == null) {
          _showSnackBar("QR Code capture failed.");
          return;
        }

        String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory == null) {
          _showSnackBar("No folder selected.");
          return;
        }

        // ✅ Use item name in the file name
        String itemName = widget.itemDetails['item_name'] ?? "QR_Code";
        final String filePath = "$selectedDirectory/qr_${itemName.replaceAll(' ', '_')}.png";
        File file = File(filePath);
        await file.writeAsBytes(image);

        // ✅ Refresh Gallery
        await refreshGallery(filePath);
        _showSnackBar("✅ QR Code saved to: $filePath");
      } catch (e) {
        _showSnackBar("❌ Failed to save QR Code: $e");
      }
    } else {
      _showSnackBar("❌ Storage permission denied.");
    }
    _isPickingFile = false;
  }

  /// ✅ Request Storage Permission (Android 13+)
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    }
    return true;
  }

  /// ✅ Refresh Gallery to Show Saved Image
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

  /// ✅ Show Snack Bar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    String qrData = widget.itemDetails.entries
        .map((e) => "${e.key}: ${e.value}")
        .join("\n");
    String itemName = widget.itemDetails['item_name'] ?? "Unknown Item";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.red,
        centerTitle: true,
        title: Text(
          "Generated QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ✅ Screenshot Wrapper (QR Code + Item Name)
              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white, // ✅ Ensure white background
                    border: Border.all(color: MyColors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200, // ✅ Higher resolution
                        gapless: false,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black, // ✅ Ensure black QR code
                      ),

                      Text(
                        itemName, // ✅ Item Name Below QR Code
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
              SizedBox(height: 20),

              // ✅ Save QR Code Button
              ElevatedButton(
                onPressed: () => _saveQRCodeToGallery(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.red,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text(

                  "Save QR Code",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),

              SizedBox(height: 20),

              // ✅ Item Details Below QR Code
              Column(
                children: widget.itemDetails.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${entry.key}:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(entry.value,
                              style: TextStyle(color: MyColors.red),
                              textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 20),

              // ✅ Edit Details Button


              SizedBox(height: 80),
            ],
          ),
        ),
      ),

    );
  }
}
