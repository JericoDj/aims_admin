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

  @override
  void initState() {
    super.initState();
    screenshotController = ScreenshotController();
  }

  // Function to Let User Choose Save Location
  Future<void> _saveQRCodeToGallery(BuildContext context) async {
    if (await _requestStoragePermission()) {
      screenshotController.capture().then((Uint8List? image) async {
        if (image != null) {
          try {
            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
            if (selectedDirectory == null) {
              _showSnackBar("No folder selected.");
              return;
            }

            // Create the file path in selected folder
            final String filePath = "$selectedDirectory/qr_code_${DateTime.now().millisecondsSinceEpoch}.png";
            File file = File(filePath);
            await file.writeAsBytes(image);

            // Refresh gallery so it appears
            await refreshGallery(filePath);

            // Show success message
            _showSnackBar("QR Code saved to: $filePath");
          } catch (e) {
            _showSnackBar("Failed to save QR Code: $e");
          }
        }
      });
    } else {
      _showSnackBar("Storage permission denied.");
    }
  }

  /// ✅ Request Storage Permission (Handles Android 13+)
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
        await Process.run('am', ['broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://$filePath']);
      }
    } catch (e) {
      debugPrint("Gallery refresh failed: $e");
    }
  }

  /// ✅ Show Snack Bar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    String? qrCodeUrl = widget.itemDetails["QR Code"];
    String qrData = widget.itemDetails.entries.map((e) => "${e.key}: ${e.value}").join("\n");

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
              // QR Code Display
              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: MyColors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: qrCodeUrl != null && qrCodeUrl.isNotEmpty
                      ? Image.network(
                    qrCodeUrl,
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.error, color: Colors.red, size: 50);
                    },
                  )
                      : QrImageView(
                    data: qrData,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Save QR Code Button
              TextButton(
                onPressed: () => _saveQRCodeToGallery(context),
                child: Text(
                  "Tap to Choose Folder & Save",
                  style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold),
                ),
              ),

              SizedBox(height: 20),

              // Item Details Below QR Code
              Column(
                children: widget.itemDetails.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${entry.key}:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(entry.value, style: TextStyle(color: MyColors.red), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              SizedBox(height: 20),

              // Edit Details Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.orange,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(
                    "EDIT DETAILS",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),

              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.back(),
        backgroundColor: MyColors.red,
        child: Icon(Icons.arrow_back, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
