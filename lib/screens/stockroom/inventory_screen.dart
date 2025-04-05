import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:aims_admin/controllers/inventory_cofntroller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:screenshot/screenshot.dart';
import '../../utils/colors.dart';

class InventoryScreen extends StatelessWidget {
  final InventoryController _controller = Get.put(InventoryController());
  final ScreenshotController screenshotController = ScreenshotController();
  bool _isSaving = false;

  Future<bool> _checkPermissions() async {
    print("Checking permissions...");

    if (Platform.isAndroid) {
      print("Android platform detected");
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      print("Android SDK version: ${androidInfo.version.sdkInt}");

      if (androidInfo.version.sdkInt >= 33) {
        print("Checking PHOTOS permission");
        final status = await Permission.photos.status;
        print("Photos permission status: $status");
        return status.isGranted;
      } else {
        print("Checking STORAGE permission");
        final status = await Permission.storage.status;
        print("Storage permission status: $status");
        return status.isGranted;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.status;
      print('iOS PhotosAddOnly Status: $status');
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
      final status = await Permission.photosAddOnly.request();
      print('Requested iOS PhotosAddOnly: $status');
    }
  }

  Future<void> _saveQRCodeToGallery(BuildContext context, String qrUrl, String itemName) async {
    if (_isSaving) return;
    _isSaving = true;

    Get.dialog(
      Center(child: CircularProgressIndicator(color: MyColors.red)),
      barrierDismissible: false,
    );

    try {
      bool hasPermission = await _checkPermissions();

      if (!hasPermission) {
        // Check if permission was permanently denied (iOS specific)
        if (Platform.isIOS) {
          final status = await Permission.photosAddOnly.status;
          if (status.isPermanentlyDenied) {
            Get.back();
            _showSettingsDialog("Please enable photo add permissions in settings");
            return;
          }
        }

        await _requestPermissions();
        hasPermission = await _checkPermissions();

        if (!hasPermission) {
          Get.back();
          _showSettingsDialog(Platform.isAndroid
              ? "Please enable storage permissions in app settings"
              : "Please enable photo add permissions in settings");
          return;
        }
      }

      final rawName = itemName;
      final sanitized = rawName
          .replaceAll(RegExp(r'[^\w\\s-]'), '')
          .replaceAll(' ', '_');

      final rawImage = await screenshotController.captureFromWidget(
        RepaintBoundary(
          child: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  qrUrl,
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    return progress == null
                        ? child
                        : CircularProgressIndicator();
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image, size: 150, color: Colors.red);
                  },
                ),
                SizedBox(height: 10),
                Text(
                  rawName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        pixelRatio: 3.0,
      );

      if (rawImage.isEmpty) throw Exception("Failed to generate QR image");

      final result = await SaverGallery.saveImage(
        rawImage,
        fileName: "${sanitized}_${DateTime.now().millisecondsSinceEpoch}",
        quality: 95,
        androidRelativePath: "Pictures/YourAppName",

        skipIfExists: false,
      );

      if (!result.isSuccess) throw Exception("Failed to save to gallery");

      Get.back();
      Get.snackbar(
        "Success!",
        "QR Code saved successfully!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();
      Get.snackbar(
        "Error",
        e.toString().replaceAll("Exception: ", ""),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isSaving = false;
    }
  }
  void _showSettingsDialog(String message) {
    Get.defaultDialog(
      title: "Permission Required",
      middleText: message,
      textConfirm: "Open Settings",
      confirmTextColor: Colors.white,
      onConfirm: () async {
        await openAppSettings();
        Get.back();
      },
      textCancel: "Cancel",
    );
  }



  bool _isOutOfStock(Map<String, dynamic> item) {
    final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
    return quantity == 0;
  }

  bool _isLowStock(Map<String, dynamic> item) {
    final quantity = int.tryParse(item['quantity'].toString()) ?? 0;
    final rawThreshold = item['low_stock_threshold'];
    final threshold = int.tryParse(rawThreshold.toString()) ?? -1;

    return quantity > 0 && threshold >= 0 && quantity <= threshold;
  }



  bool _isNearExpiry(Map<String, dynamic> item) {
    try {
      final rawDays = item['expiry_alert_days'];
      final alertDays = int.tryParse(rawDays.toString()) ?? -1;

      if (alertDays <= 0) return false;

      final expiryRaw = item['expiration_date'];
      DateTime expiryDate;

      if (expiryRaw is Timestamp) {
        expiryDate = expiryRaw.toDate();
      } else if (expiryRaw is String) {
        expiryDate = DateTime.tryParse(expiryRaw) ?? DateTime(2100);
      } else {
        return false;
      }

      final alertDate = expiryDate.subtract(Duration(days: alertDays));
      return DateTime.now().isAfter(alertDate) || DateTime.now().isAtSameMomentAs(alertDate);
    } catch (_) {
      return false;
    }
  }



  Widget _buildTag(String text, Color color) {
    return Container(
      margin: EdgeInsets.only(left: 6),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
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
              height: 40, // Adjusted container size (small but fits icon)
              width: 40,  // Ensure it's a perfect square
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyColors.darkRed,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: MyColors.white, size: 28), // Increased icon size
                padding: EdgeInsets.zero, // Removes extra padding inside the button
                constraints: BoxConstraints(), // Prevents extra spacing issues
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ),
          title: Text(
            "INVENTORY",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold, fontSize: 28),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: MyColors.red),
              onPressed: _controller.refreshInventory,
            )
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: TextField(
                controller: _controller.searchController,
                onChanged: _controller.filterSearch,
                decoration: InputDecoration(
                  hintText: "Search item...",
                  hintStyle: TextStyle(fontSize: 20),
                  prefixIcon: Icon(Icons.search, color: MyColors.red, size: 24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: MyColors.red),
                  ),
                ),
                style: TextStyle(fontSize: 18),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_controller.filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      "No items found.",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.red),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: _controller.filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _controller.filteredItems[index];
                    final itemName = item['name'] ?? "Unknown Item";
                    final category = item['category'] ?? "Unknown Category";
                    final qrData = item['qr_code_url'] ?? "";

                    return GestureDetector(
                      onTap: () => _showItemDetails(context, item),
                      child: Card(
                        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: MyColors.red, width: 1),
                        ),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  itemName,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.red),
                                ),
                              ),
                              if (_isOutOfStock(item)) ...[
                                _buildTag("Out of Stock", Colors.red),
                              ] else ...[
                                if (_isLowStock(item)) _buildTag("Low Stock", Colors.orange),
                                if (_isNearExpiry(item)) _buildTag("Nearly Expiring", Colors.redAccent),
                              ],

                            ],
                          ),
                          subtitle: Text("Category: $category"),
                          trailing: Image.network(
                            qrData,
                            height: 50,
                            width: 50,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              return progress == null
                                  ? child
                                  : SizedBox(
                                  height: 50,
                                  width: 50,
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.broken_image, size: 50, color: Colors.red);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    final itemName = item['name'] ?? "Unknown Item";
    final category = item['category'] ?? "Unknown Category";
    final quantity = item['quantity']?.toString() ?? "N/A";
    final unit = item['unit_measurement']?.toString() ?? "N/A";
    final expirationDate = item['expiration_date']?.toString() ?? "N/A";
    final qrData = item['qr_code_url'] ?? "";
    final lowStockValue = item['low_stock_threshold']?.toString() ?? "N/A";
    final nearlyExpiryDays = item['expiry_alert_days']?.toString() ?? "N/A";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Item Details",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                _buildDetailRow("Name:", itemName),
                _buildDetailRow("Category:", category),
                _buildDetailRow("Stock:", quantity),
                _buildDetailRow("Unit", unit),
                _buildDetailRow("Expiry:", expirationDate),
                _buildDetailRow("Low Stock Threshold:", lowStockValue),
                _buildDetailRow("Expiry Alert (Days):", nearlyExpiryDays),

                SizedBox(height: 16),
                Center(
                  child: Screenshot(
                    controller: screenshotController,
                    child: Image.network(
                      qrData,
                      height: 200,
                      width: 200,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        return progress == null
                            ? child
                            : CircularProgressIndicator();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image, size: 200, color: Colors.red);
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _setLowStockValue(context, item),
                      child: Text("Set Low Stock", style: TextStyle(color: MyColors.red)),
                    ),
                    // New Button: Set Nearly Expiry Date
                    TextButton(
                      onPressed: () => _setNearlyExpiryDate(context, item),
                      child: Text("Set Expiry Alert", style: TextStyle(color: MyColors.red)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => _saveQRCodeToGallery(context, qrData, itemName),
                      child: Text("Save QR", style: TextStyle(color: MyColors.red)),
                    ),
                    TextButton(
                      onPressed: () => _controller.confirmDeleteItem(context, category, item['id'], itemName),
                      child: Text("Delete", style: TextStyle(color: Colors.red)),
                    ),
                    TextButton(
                      onPressed: Get.back,
                      child: Text("Close", style: TextStyle(color: MyColors.red)),
                    ),
                    // New Button: Set Low Stock Value

                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setNearlyExpiryDate(BuildContext context, Map<String, dynamic> item) {
    final TextEditingController expiryDaysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Expiry Alert"),
        content: TextField(
          controller: expiryDaysController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Enter days before expiry to alert"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final input = expiryDaysController.text.trim();
              if (input.isEmpty || int.tryParse(input) == null) {
                Get.snackbar("Invalid Input", "Please enter a valid number",
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              final value = int.parse(input);
              final itemId = item['id'].toString();

              await _controller.updateItemField(itemId, 'expiry_alert_days', value);
              Navigator.of(context, rootNavigator: true).pop(); // Close outer dialog

              Get.back();
              Get.snackbar("Updated", "Expiry alert set to $value days before expiration",
                  backgroundColor: Colors.green, colorText: Colors.white);
            },
            child: Text("Set Alert"),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }
  void _setLowStockValue(BuildContext context, Map<String, dynamic> item) {
    final TextEditingController lowStockController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Set Low Stock Threshold"),
        content: TextField(
          controller: lowStockController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: "Enter low stock value"),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final input = lowStockController.text.trim();
              if (input.isEmpty || int.tryParse(input) == null) {
                Get.snackbar("Invalid Input", "Please enter a valid number",
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              final value = int.parse(input);
              final itemId = item['id'].toString();

              await _controller.updateItemField(itemId, 'low_stock_threshold', value);
              Navigator.of(context, rootNavigator: true).pop(); // Close outer dialog

              Get.back(); // Close dialog
              Get.snackbar("Updated", "Low stock threshold set to $value",
                  backgroundColor: Colors.green, colorText: Colors.white);
            },
            child: Text("Set"),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Cancel"),
          ),
        ],
      ),
    );
  }


  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}