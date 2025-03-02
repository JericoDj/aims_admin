import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/colors.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();

  Map<String, String> scannedItem = {}; // Stores scanned item data
  TextEditingController quantityController = TextEditingController();
  TextEditingController expirationController = TextEditingController();

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
            "QR SCANNER",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold, fontSize: 28),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  if (capture.barcodes.isNotEmpty) {
                    String scannedData = capture.barcodes.first.rawValue ?? "";
                    print("📌 Scanned Data: $scannedData");

                    setState(() {
                      scannedItem = _parseScannedData(scannedData);
                      quantityController.text = scannedItem['quantity'] ?? "";
                      expirationController.text = scannedItem['expiration_date'] ?? "";
                    });

                    // Show dialog to edit details
                    showEditDialog(context);
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () => scannerController.start(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.darkRed,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text("Start Scanning",
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickAndDecodeQRFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text("Select File",
                        style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Function to Parse Scanned Data
  Map<String, String> _parseScannedData(String data) {
    Map<String, String> parsedData = {};
    List<String> lines = data.split("\n");
    for (String line in lines) {
      List<String> parts = line.split(": ");
      if (parts.length == 2) {
        parsedData[parts[0].trim()] = parts[1].trim();
      }
    }
    return parsedData;
  }

  /// ✅ Function to Show Editable Dialog
  void showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Center(
            child: Text(
              "Edit Item Details",
              style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.red, fontSize: 24),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow("Item Name", scannedItem['item_name'] ?? "N/A"),
                _buildDetailRow("Brand", scannedItem['brand'] ?? "N/A"),
                _buildDetailRow("Category", scannedItem['category'] ?? "N/A"),

                SizedBox(height: 15),

                Text("Enter Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MyColors.red)),
                SizedBox(height: 5),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter quantity",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(fontSize: 18),
                ),

                SizedBox(height: 15),

                Text("Enter Expiration Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MyColors.red)),
                SizedBox(height: 5),
                TextField(
                  controller: expirationController,
                  keyboardType: TextInputType.datetime,
                  decoration: InputDecoration(
                    hintText: "YYYY-MM-DD",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _saveUpdatedData();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.red,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: Text("SAVE", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("CLOSE", style: TextStyle(color: MyColors.red, fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Function to Save Updated Data
  void _saveUpdatedData() {
    setState(() {
      scannedItem['quantity'] = quantityController.text;
      scannedItem['expiration_date'] = expirationController.text;
    });

    print("✅ Updated Quantity: ${scannedItem['quantity']}");
    print("✅ Updated Expiration Date: ${scannedItem['expiration_date']}");
  }

  /// ✅ Function to Pick and Decode QR Code from an Image
  Future<void> _pickAndDecodeQRFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      File selectedFile = File(image.path);
      print("📌 Selected file: ${selectedFile.path}");

      await _decodeQRCode(selectedFile);
    } catch (e) {
      print("⚠️ Error selecting file: $e");
    }
  }

  /// ✅ Function to Decode QR Code from an Image
  Future<void> _decodeQRCode(File file) async {
    final BarcodeCapture? capture = await scannerController.analyzeImage(file.path);

    if (capture != null && capture.barcodes.isNotEmpty) {
      scannedItem = _parseScannedData(capture.barcodes.first.rawValue ?? "");
      showEditDialog(context);
    } else {
      print("❌ No QR Code found in the image.");
    }
  }

  /// ✅ Helper Function to Display Item Details
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(value, style: TextStyle(color: MyColors.darkRed, fontSize: 18)),
        ],
      ),
    );
  }
}
