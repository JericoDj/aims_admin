import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/colors.dart';
import '../../utils/notification_controller.dart';

class QRScannerScreen extends StatefulWidget {
  @override
  _QRScannerScreenState createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController();


  bool _isDialogOpen = false; // ✅ Flag to prevent multiple scans

  Map<String, String> scannedItem = {}; // Stores scanned item data
  TextEditingController quantityController = TextEditingController();
  TextEditingController expirationController = TextEditingController();



  @override
  void dispose() {
    scannerController.stop();
    scannerController.dispose();
    super.dispose();
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
                  if (_isDialogOpen) return; // ✅ Prevent scanning again when the dialog is open
                  if (capture.barcodes.isNotEmpty) {
                    String scannedData = capture.barcodes.first.rawValue ?? "";
                    print("📌 Raw Scanned Data: $scannedData");  // Debug scanned string

                    setState(() {
                      scannedItem = _parseScannedData(scannedData);
                    });

                    // Debugging output
                    print("📌 Scanned Data Map: $scannedItem");
                    print("📌 Category: ${scannedItem['category']}");

                    // Populate text fields if data is available
                    quantityController.text = scannedItem['quantity'] ?? "";
                    expirationController.text = scannedItem['expiration_date'] ?? "";

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

    // Required fields check
    bool hasRequiredFields = lines.any((line) => line.startsWith("brand:"));

    if (!hasRequiredFields) {
      Get.snackbar("Invalid QR", "Missing brand information",
          backgroundColor: Colors.red);
      throw FormatException("Brand field is required");
    }

    for (String line in lines) {
      List<String> parts = line.split(":");
      if (parts.length >= 2) {
        parsedData[parts[0].trim().toLowerCase()] = parts.sublist(1).join(":").trim();
      }
    }
    return parsedData;
  }

  /// ✅ Function to Show Editable Dialog
  void showEditDialog(BuildContext context) {

    _isDialogOpen = true; // ✅ Set flag to true to prevent re-scanning
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Center(
            child: Text(
              "Add Item Quanity",
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
                _buildDetailRow("Unit", scannedItem['unit_measurement'] ?? "N/A"),


                SizedBox(height: 15),


                Text("Enter Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MyColors.red)),
                SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter quantity",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(width: 10),

                  ],
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

  void _saveUpdatedData() async {
    if (scannedItem.isEmpty) return;

    String itemName = scannedItem['item_name'] ?? "";
    String brand = scannedItem['brand'] ?? "";
    String category = scannedItem['category'] ?? "";
    String newQuantityInput = quantityController.text.trim();
    String expirationDate = expirationController.text.trim();
    String dateUpdated = DateTime.now().toIso8601String();

    // Sanitize names for Firestore path, but preserve case
    category = category.replaceAll(" ", "_").replaceAll(":", "_");
    itemName = itemName.replaceAll(" ", "_").replaceAll(":", "_");

    if (itemName.isEmpty || category.isEmpty || newQuantityInput.isEmpty) {
      Get.snackbar("Error", "Item name, category, or quantity is missing",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    if (brand.isEmpty) {
      Get.snackbar("Error", "Brand information is missing", backgroundColor: Colors.red);
      return;
    }

    int newQuantity = int.tryParse(newQuantityInput) ?? 0;
    if (newQuantity <= 0) {
      Get.snackbar("Error", "Quantity must be a positive number",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Print Firestore Path for debugging
    print("📌 Firestore Path: stock/$category/items/$itemName");

    try {
      // Use a single document ID generation method but preserve case for itemName and brand
      String documentId = _generateDocumentId(brand, itemName);

      DocumentReference itemRef = FirebaseFirestore.instance
          .collection('stock')
          .doc(category)
          .collection('items')
          .doc(documentId); // Use sanitized and consistent ID

      // Print the full Firestore path where it is trying to save
      print("📌 Trying to access Firestore Path: ${itemRef.path}");

      DocumentSnapshot itemSnapshot = await itemRef.get();

      if (!itemSnapshot.exists) {
        Get.snackbar("Error", "Item does not exist in Firestore",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // Improved quantity handling
      final existingData = itemSnapshot.data() as Map<String, dynamic>? ?? {};
      int existingQuantity = (existingData['quantity'] is num)
          ? (existingData['quantity'] as num).toInt()
          : int.tryParse(existingData['quantity']?.toString() ?? '0') ?? 0;

      int updatedQuantity = existingQuantity + newQuantity;

      // Debug prints
      print("🔄 Quantity Update:");
      print("└ Existing: $existingQuantity");
      print("└ Added: $newQuantity");
      print("└ New Total: $updatedQuantity");

      // Build update map
      Map<String, dynamic> updateData = {
        'quantity': updatedQuantity,  // Store as number instead of string
      };

      if (expirationDate.isNotEmpty) {
        updateData['expiration_date'] = expirationDate;
      }

      // Update Firestore with merged data
      await itemRef.update(updateData);  // Use update() to update fields only

      setState(() {
        scannedItem['quantity'] = updatedQuantity.toString();
        if (expirationDate.isNotEmpty) {
          scannedItem['expiration_date'] = expirationDate;
        }
      });

      print("✅ Quantity Added: $newQuantity → Total: $updatedQuantity");

      // Save to history
      await FirebaseFirestore.instance.collection("history").add({
        "Item Name": scannedItem['item_name'] ?? "Unknown",
        "Brand": brand,
        "Quantity Added": newQuantity.toString(),
        "New Total": updatedQuantity.toString(),
        "Category": scannedItem['category'] ?? "Unknown",
        "Action": "Add Stock",
        "Date Updated": dateUpdated,
      });

      print("✅ History saved.");

      // Send notification
      NotificationController notificationController = Get.find();
      await notificationController.sendNotificationToAllUsers(
          "Stock Added: $itemName",
          "Added $newQuantity → Total: $updatedQuantity"
      );

      print("📢 Notification sent!");

    } catch (e) {
      print("❌ Firestore Update Error: $e");
      Get.snackbar("Error", "Failed to update item: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  /// ✅ Helper function to generate Document ID without changing case
  String _generateDocumentId(String brand, String itemName) {
    return brand.trim().replaceAll(RegExp(r'[^\w]'), "_") +
        "_" +
        itemName.trim().replaceAll(RegExp(r'[^\w]'), "_");
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