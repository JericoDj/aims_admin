import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../screens/generateqr/generated_qr_code_screen.dart';
import '../utils/notification_controller.dart';
import '../utils/notification_service.dart';


class QRCodeController extends GetxController {


  final formKey = GlobalKey<FormState>();


  // Controllers for input fields
  final TextEditingController storageCodeController = TextEditingController();
  final TextEditingController serialNoController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController expirationDateController = TextEditingController();
  final TextEditingController unitMeasurementController = TextEditingController();
  final TextEditingController specificationController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(); // ✅ Added Quantity Controller

  // Category Dropdown List
  final RxString selectedCategory = "Medical Equipments".obs;
  final List<String> categories = [
    "Medical Equipments",
    "Medical Supplies",
    "Medical Drugs",
    "Dental",
    "Miscellaneous",
    "Office Equipment",
    "Office Supplies"
  ];

  /// **Generate QR Code, Upload to Firebase Storage, Save to Firestore, and Send Notification**
  Future<void> generateQRCode({String? itemId}) async {
    if (formKey.currentState!.validate()) {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Format item name for Firestore & Storage
      String rawItemName = itemNameController.text.trim();
      String brand = brandController.text.trim();
      String formattedItemName = _sanitizeString(rawItemName); // Clean item name
      String formattedBrand = _sanitizeString(brand);

      // Combine item name and brand
      String uniqueDocId = "${formattedItemName}_${formattedBrand}";


      // Format category for Firestore & Storage
      String categoryFolder = _sanitizeCategory(selectedCategory.value); // Prevent double underscores

      // Get current date and time
      String dateGenerated = DateTime.now().toIso8601String();

      // Collect item details
      Map<String, dynamic> itemDetails = {
        "storage_code": storageCodeController.text,
        "serial_no": serialNoController.text,
        "item_name": rawItemName,
        "brand": brandController.text,
        "expiration_date": expirationDateController.text,
        "unit_measurement": unitMeasurementController.text,
        "specifications": specificationController.text,
        "quantity": quantityController.text.trim(), // ✅ Store quantity as STRING
        "category": selectedCategory.value
      };

      try {
        print("📸 Generating QR Code...");
        Uint8List qrImage = await _generateQRImage(itemDetails);

        if (qrImage.isEmpty) {
          print("❌ QR Code generation failed!");
          Get.back();
          Get.snackbar("Error", "QR Code generation failed.");
          return;
        }

        print("✅ QR Code generated successfully!");

        // **Use item name for the QR code filename in Firebase Storage**
        String formattedBrand = _sanitizeString(brandController.text.trim());
        String uniqueDocId = "${formattedBrand}_${formattedItemName}";
        String fileName = "qr_$uniqueDocId.png";
        String filePath = "qr_codes/$categoryFolder/$fileName";

        print("📂 Storing QR Code in: $filePath");

        Reference ref = FirebaseStorage.instance.ref().child(filePath);
        UploadTask uploadTask = ref.putData(qrImage);
        TaskSnapshot snapshot = await uploadTask;

        // Get Download URL
        String qrCodeUrl = await snapshot.ref.getDownloadURL();
        print("🌍 QR Code URL: $qrCodeUrl");

        // **Store QR Code URL in Firestore under the specific category**
        itemDetails["qr_code_url"] = qrCodeUrl;

        String categoryCollection = "stock/$categoryFolder/items";

        // Use item name as document ID in Firestore
        DocumentReference itemRef = FirebaseFirestore.instance.collection(categoryCollection).doc(uniqueDocId);

        if (itemId == null) {
          print("📦 Creating new item in Firestore under category: $categoryFolder...");
          await itemRef.set(itemDetails);
          print("✅ Item successfully added with ID: $formattedItemName");
        } else {
          print("✏️ Updating existing item in Firestore under category: $categoryFolder...");
          await itemRef.update(itemDetails);
          print("✅ Item successfully updated!");
        }

        // **✅ Save to History Collection**
        await FirebaseFirestore.instance.collection("history").add({
          "Item Name": rawItemName,
          "Quantity": quantityController.text.trim(),
          "Category": selectedCategory.value, // ✅ Added Category
          "Date Generated": dateGenerated,
          "Action": "Generate QR Code",
        });

        print("📜 ✅ History Log Added: $rawItemName - $dateGenerated");

        // **Send Notification to All Users**
        NotificationController notificationController = Get.find(); // Get the controller instance
        await notificationController.sendNotificationToAllUsers(
            "New Item Added: $rawItemName",
            "A new item has been added to the inventory: $rawItemName. Check it out!"
        );

        print("📲 ✅ Notification sent to all users!");

        Get.back();
        Get.to(() => GeneratedQRCodeScreen(itemDetails: {...itemDetails, "QR Code": qrCodeUrl}));

      } catch (e) {
        Get.back();
        print("❌ Error occurred: $e");
        Get.snackbar("Error", "QR Code generation failed: $e");
      }
    }
  }

  @override
  void onClose() {
    storageCodeController.dispose();
    serialNoController.dispose();
    itemNameController.dispose();
    brandController.dispose();
    expirationDateController.dispose();
    unitMeasurementController.dispose();
    specificationController.dispose();
    quantityController.dispose(); // ✅ Dispose Quantity Controller
    super.onClose();
  }
}

String _sanitizeString(String input) {
  return input
      .trim()
      .replaceAll(RegExp(r'[^\w]'), "_") // Replace non-word characters (except letters/numbers) with "_"
      .replaceAll(RegExp(r'_+'), "_"); // Remove consecutive "__"
}

String _sanitizeCategory(String category) {
  return category
      .replaceAll(":", "") // Remove colons
      .replaceAll(" ", "_") // Replace spaces with a single underscore
      .replaceAll(RegExp(r'_+'), "_") // Remove consecutive "__"
      .trim();
}

Future<Uint8List> _generateQRImage(Map<String, dynamic> itemDetails) async {
  try {
    String qrData = itemDetails.entries.map((e) => "${e.key}: ${e.value}").join("\n");

    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      gapless: true,
    );

    final ByteData? byteData = await qrPainter.toImageData(300);
    if (byteData == null) return Uint8List(0);

    return byteData.buffer.asUint8List();
  } catch (e) {
    print("❌ QR Code Image Generation Failed: $e");
    return Uint8List(0);
  }
}
