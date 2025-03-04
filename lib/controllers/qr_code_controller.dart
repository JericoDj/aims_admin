import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../screens/generateqr/generated_qr_code_screen.dart';

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

  // Category Dropdown List
  final RxString selectedCategory = "Medical Equipments".obs;
  final List<String> categories = [
    "Medical Equipments",
    "Medical Supplies",
    "Medical Drugs",
    "Dental",
    "Miscellaneous"
  ];

  /// **Generate QR Code, Upload to Firebase Storage, and Save to Firestore**
  Future<void> generateQRCode({String? itemId}) async {
    if (formKey.currentState!.validate()) {
      Get.dialog(
        Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      // Format item name for Firestore & Storage
      String rawItemName = itemNameController.text.trim();
      String formattedItemName = _sanitizeString(rawItemName); // Clean item name

      // Format category for Firestore & Storage
      String categoryFolder = _sanitizeCategory(selectedCategory.value); // Prevent double underscores

      // Collect item details
      Map<String, dynamic> itemDetails = {
        "storage_code": storageCodeController.text,
        "serial_no": serialNoController.text,
        "item_name": rawItemName,
        "brand": brandController.text,
        "expiration_date": expirationDateController.text,
        "unit_measurement": unitMeasurementController.text,
        "specifications": specificationController.text,
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
        String fileName = "qr_${formattedItemName}.png";
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
        DocumentReference itemRef = FirebaseFirestore.instance.collection(categoryCollection).doc(formattedItemName);

        if (itemId == null) {
          print("📦 Creating new item in Firestore under category: $categoryFolder...");
          await itemRef.set(itemDetails);
          print("✅ Item successfully added with ID: $formattedItemName");
        } else {
          print("✏️ Updating existing item in Firestore under category: $categoryFolder...");
          await itemRef.update(itemDetails);
          print("✅ Item successfully updated!");
        }

        Get.back();
        Get.to(() => GeneratedQRCodeScreen(itemDetails: {...itemDetails, "QR Code": qrCodeUrl}));

      } catch (e) {
        Get.back();
        print("❌ Error occurred: $e");
        Get.snackbar("Error", "QR Code generation failed: $e");
      }
    }
  }

  /// **Generate QR Code as an Image (Uint8List)**
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

  /// **Load Item Details from Firestore**
  Future<void> loadItemDetails(String category, String itemName) async {
    String categoryCollection = "categories/${_sanitizeCategory(category)}/items";
    String formattedItemName = _sanitizeString(itemName);

    DocumentSnapshot doc = await FirebaseFirestore.instance.collection(categoryCollection).doc(formattedItemName).get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      storageCodeController.text = data["storage_code"];
      serialNoController.text = data["serial_no"];
      itemNameController.text = data["item_name"];
      brandController.text = data["brand"];
      expirationDateController.text = data["expiration_date"];
      unitMeasurementController.text = data["unit_measurement"];
      specificationController.text = data["specifications"];
      selectedCategory.value = data["category"];
    }
  }

  /// **Sanitize String for Safe Use in Firebase Paths (File Names & Document IDs)**
  String _sanitizeString(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'[^\w]'), "_") // Replace non-word characters (except letters/numbers) with "_"
        .replaceAll(RegExp(r'_+'), "_"); // Remove consecutive "__"
  }

  /// **Sanitize Category to Prevent Double Underscores**
  String _sanitizeCategory(String category) {
    return category
        .replaceAll(":", "") // Remove colons
        .replaceAll(" ", "_") // Replace spaces with a single underscore
        .replaceAll(RegExp(r'_+'), "_") // Remove consecutive "__"
        .trim();
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
    super.onClose();
  }
}
