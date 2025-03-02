import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/qr_scanner_controller.dart';
import '../../utils/colors.dart';

class QRScannerScreen extends StatelessWidget {
  final QRScannerController controller = Get.put(QRScannerController());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: MyColors.white,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: MyColors.red, size: 28),
            onPressed: () => Get.back(),
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
                controller: controller.scannerController,
                onDetect: (capture) {
                  if (capture.barcodes.isNotEmpty && controller.isScanning.value) {
                    controller.isScanning.value = false;
                    String scannedData = capture.barcodes.first.rawValue ?? "";
                    print("📌 Scanned Data: $scannedData");
                    controller.fetchItemDetails(scannedData, context);
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            // Centering buttons properly
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: controller.restartScanning,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.darkRed,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: Text("Start Scanning", style: TextStyle(color: Colors.white, fontSize: 20)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickFile,
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

  // Function to pick a file from iOS/Android
  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any, // Can change to FileType.image for images only
    );

    if (result != null) {
      String filePath = result.files.single.path!;
      print("📂 Selected File Path: $filePath");
      Get.snackbar("File Selected", "Path: $filePath", snackPosition: SnackPosition.BOTTOM);
    } else {
      print("❌ No file selected");
    }
  }
}
