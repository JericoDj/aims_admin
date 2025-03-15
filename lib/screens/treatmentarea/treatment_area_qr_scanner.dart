import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/colors.dart';
import '../../utils/notification_controller.dart';

class TreatmentQRScannerScreen extends StatefulWidget {
  @override
  _TreatmentQRScannerScreenState createState() => _TreatmentQRScannerScreenState();
}

class _TreatmentQRScannerScreenState extends State<TreatmentQRScannerScreen> {
  final MobileScannerController scannerController = MobileScannerController(
    autoStart: false,  // Prevent auto-start issues
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    scannerController.start();  // ✅ Ensures camera starts
  }


  bool _isDialogOpen = false; // ✅ Prevent multiple scans

  Map<String, String> scannedItem = {}; // Stores scanned item data
  TextEditingController usedQuantityController = TextEditingController(); // Input field for used items

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
            "TREATMENT QR SCANNER",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  if (_isDialogOpen) return; // ✅ Prevent duplicate scans while dialog is open

                  if (capture.barcodes.isNotEmpty) {
                    String scannedData = capture.barcodes.first.rawValue ?? "";
                    print("📌 Raw Scanned Data: $scannedData");

                    setState(() {
                      scannedItem = _parseScannedData(scannedData);
                    });

                    print("📌 Scanned Data Map: $scannedItem");
                    print("📌 Category: ${scannedItem['category']}");

                    usedQuantityController.clear(); // Reset input field

                    showUsedItemsDialog(context);
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text("Start Scanning", style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickAndDecodeQRFile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text("Select File", style: TextStyle(color: Colors.white, fontSize: 20)),
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
      List<String> parts = line.split(":");
      if (parts.length >= 2) {
        parsedData[parts[0].trim()] = parts.sublist(1).join(":").trim();
      }
    }
    return parsedData;
  }

  /// ✅ Function to Show Dialog for Used Items
  void showUsedItemsDialog(BuildContext context) {
    _isDialogOpen = true; // ✅ Prevent re-scanning

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Center(
            child: Text(
              "Log Used Items",
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

                Text("Quantity Used", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: MyColors.red)),
                SizedBox(height: 5),
                TextField(
                  controller: usedQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter quantity used",
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
                _logUsedItems();
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
                _isDialogOpen = false;
                Navigator.pop(context);
              },
              child: Text("CLOSE", style: TextStyle(color: MyColors.red, fontSize: 18)),
            ),
          ],
        );
      },
    );
  }

  /// ✅ Function to Log Used Items and Update Firestore
  /// ✅ Function to Log Used Items, Update Firestore, and Save to History

  void _logUsedItems() async {
    if (scannedItem.isEmpty) return;

    String category = scannedItem['category'] ?? "";
    String itemName = scannedItem['item_name'] ?? "";
    String usedQuantityStr = usedQuantityController.text.trim();
    String dateUpdated = DateTime.now().toIso8601String(); // Capture timestamp

    category = category.replaceAll(" ", "_").replaceAll(":", "_");
    itemName = itemName.replaceAll(" ", "_").replaceAll(":", "_");

    if (itemName.isEmpty || category.isEmpty || usedQuantityStr.isEmpty) {
      print("❌ Error: Invalid input.");
      return;
    }

    int usedQuantity = int.tryParse(usedQuantityStr) ?? 0;

    if (usedQuantity <= 0) {
      print("❌ Error: Invalid quantity input.");
      Get.snackbar("Error", "Please enter a valid quantity.", backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    print("📌 Logging used items in Firestore: $category -> $itemName ($usedQuantity used)");

    try {
      DocumentReference itemRef = FirebaseFirestore.instance
          .collection('stock')
          .doc(category)
          .collection('items')
          .doc(itemName);

      // ✅ Fetch the current quantity from Firestore first
      DocumentSnapshot snapshot = await itemRef.get();

      if (!snapshot.exists || snapshot.data() == null) {
        print("❌ Error: Item does not exist or 'quantity' field is missing.");
        Get.snackbar("Error", "Item not found or missing 'quantity' field", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      Map<String, dynamic> itemData = snapshot.data() as Map<String, dynamic>;

      // ✅ Convert quantity from string to int
      int currentQuantity = int.tryParse(itemData['quantity'].toString()) ?? 0; // Ensure it's an integer

      if (currentQuantity < usedQuantity) {
        print("❌ Error: Insufficient stock. Cannot use more than available.");
        Get.snackbar("Error", "Insufficient stock. Only $currentQuantity available.", backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }

      // ✅ Subtract used quantity from stock and save as string
      await itemRef.update({
        'quantity': (currentQuantity - usedQuantity).toString(), // Store as string
      });

      print("✅ Successfully logged used items!");

      // ✅ Save usage history in Firestore with Category
      await FirebaseFirestore.instance.collection("history").add({
        "Item Name": scannedItem['item_name'] ?? "Unknown",
        "Quantity": usedQuantityStr,
        "Category": scannedItem['category'] ?? "Unknown", // ✅ Added Category
        "Action": "Treatment Use",
        "Date Updated": dateUpdated,
      });

      print("✅ Usage history saved!");

      // ✅ Send notification to all users
      NotificationController notificationController = Get.find(); // Get the notification controller
      await notificationController.sendNotificationToAllUsers(
          "Item Used: $itemName",
          "$usedQuantity used from stock. Remaining stock: ${(currentQuantity - usedQuantity)}"
      );

      print("📢 Notification sent successfully!");

      // Show a success message

    } catch (e) {
      print("❌ Firestore Update Error: $e");
      Get.snackbar(
        "Error",
        "Failed to log usage: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
  /// ✅ Function to Pick and Decode QR Code from an Image
  Future<void> _pickAndDecodeQRFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return; // If user cancels selection, do nothing

      File selectedFile = File(image.path);
      print("📌 Selected file: ${selectedFile.path}");

      await _decodeQRCode(selectedFile); // Process the image file
    } catch (e) {
      print("⚠️ Error selecting file: $e");
    }
  }

  /// ✅ Function to Decode QR Code from an Image
  Future<void> _decodeQRCode(File file) async {
    final BarcodeCapture? capture = await scannerController.analyzeImage(file.path);

    if (capture != null && capture.barcodes.isNotEmpty) {
      setState(() {
        scannedItem = _parseScannedData(capture.barcodes.first.rawValue ?? "");
      });

      print("✅ QR Code Data Decoded: $scannedItem");

      if (!_isDialogOpen) {
        showUsedItemsDialog(context);
      }
    } else {
      print("❌ No QR Code found in the image.");
    }
  }

}

