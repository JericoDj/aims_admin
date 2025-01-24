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
  late ScreenshotController screenshotController; // ✅ Declare `late`

  @override
  void initState() {
    super.initState();
    screenshotController = ScreenshotController(); // ✅ Initialize in initState()
  }

  // Function to Let User Choose Save Location
  Future<void> _saveQRCodeToGallery(BuildContext context) async {
    if (await _requestStoragePermission()) {
      screenshotController.capture().then((Uint8List? image) async {
        if (image != null) {
          try {
            // Let user select the folder
            String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
            if (selectedDirectory == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No folder selected.")),
              );
              return;
            }

            // Create the file path in selected folder
            final String filePath = "$selectedDirectory/qr_code_${DateTime.now().millisecondsSinceEpoch}.png";
            File file = File(filePath);
            await file.writeAsBytes(image);

            // Refresh gallery so it appears
            await refreshGallery(filePath);

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("QR Code saved to: $filePath")),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to save QR Code: $e")),
            );
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Storage permission denied.")),
      );
    }
  }

  /// **✅ Request Storage Permission**
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
    }
    return false;
  }

  /// **✅ Refresh Gallery to Show Saved Image**
  Future<void> refreshGallery(String filePath) async {
    try {
      await Process.run('am', ['broadcast', '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE', '-d', 'file://$filePath']);
    } catch (e) {
      debugPrint("Gallery refresh failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    String qrData = widget.itemDetails.entries.map((e) => "${e.key}: ${e.value}").join("\n");

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.red,
        centerTitle: true,
        title: Text(
          "GENERATE QR CODE",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
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
                controller: screenshotController, // ✅ No more LateInitializationError
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: MyColors.red, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: QrImageView(
                    data: qrData,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Tap to Save QR Code
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
                  onPressed: () {
                    Get.back();
                  },
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

              SizedBox(height: 80 ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.back();
        },
        backgroundColor: MyColors.red,
        child: Icon(Icons.arrow_back, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
