import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../utils/colors.dart';
import 'offline/DataBaseHelper.dart';
import 'offline/connect_to_offline_controller.dart';
import 'offline/local_server.dart';


class OfflineDataScreen extends StatefulWidget {
  @override
  _OfflineDataScreenState createState() => _OfflineDataScreenState();
}

class _OfflineDataScreenState extends State<OfflineDataScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final LocalServer _localServer = LocalServer(); // Initialize Server
  List<Map<String, dynamic>> _offlineData = [];
  final RxBool _isServerRunning = false.obs;
  final RxString _serverIp = ''.obs;


  // ✅ Controllers for Adding and Editing Data
  final TextEditingController _storageCodeController = TextEditingController();
  final TextEditingController _serialNoController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  final TextEditingController _unitMeasurementController = TextEditingController();
  final TextEditingController _specificationController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadOfflineData();
  }


  @override
  void dispose() {
    // ✅ Dispose Controllers to Prevent Memory Leaks
    _storageCodeController.dispose();
    _serialNoController.dispose();
    _itemNameController.dispose();
    _brandController.dispose();
    _expirationDateController.dispose();
    _unitMeasurementController.dispose();
    _specificationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }


  /// ✅ Load Offline Data from SQLite
  Future<void> _loadOfflineData() async {
    final data = await _databaseHelper.getAllData();
    setState(() {
      _offlineData = data;
    });
  }

  void _stopServer() async {
    if (_localServer.isServerRunning()) {
      await _localServer.stopServer();
      _isServerRunning.value = false;
      _serverIp.value = '';
      Get.snackbar("Success", "Server stopped successfully",
          backgroundColor: Colors.orange, colorText: Colors.white);
    } else {
      Get.snackbar("Info", "No active server to stop.",
          backgroundColor: Colors.blue, colorText: Colors.white);
    }
  }


  /// 🚀 Start Local Network Server
  void _startServer() async {
    try {
      if (_isServerRunning.value) {
        Get.snackbar("Info", "Server is already running.",
            backgroundColor: Colors.blue, colorText: Colors.white);
        return;
      }

      final interfaces = await NetworkInterface.list();
      final wifiInterface = interfaces.firstWhere(
            (interface) => interface.name == 'wlan0' || interface.name == 'en0',
        orElse: () => interfaces.first,
      );

      final ip = wifiInterface.addresses
          .firstWhere((addr) => addr.type == InternetAddressType.IPv4)
          .address;

      await _localServer.startServer();

      _isServerRunning.value = true;
      _serverIp.value = ip;

      Get.snackbar(
        "Server Started",
        "Connect to IP: $ip:8080",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      _isServerRunning.value = false;
      _serverIp.value = '';
      Get.snackbar("Error", "Failed to start server: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


  /// ✅ Add New Data to Offline Database
  Future<void> _addNewData() async {
    // Debug: Print form values
    print("Form Values:");
    print("Storage Code: ${_storageCodeController.text}");
    print("Serial No: ${_serialNoController.text}");
    print("Item Name: ${_itemNameController.text}");
    print("Brand: ${_brandController.text}");
    print("Exp Date: ${_expirationDateController.text}");
    print("Unit: ${_unitMeasurementController.text}");
    print("Spec: ${_specificationController.text}");
    print("Qty: ${_quantityController.text}");

    // Validate fields
    if (_storageCodeController.text.trim().isEmpty ||
        _serialNoController.text.trim().isEmpty ||
        _itemNameController.text.trim().isEmpty ||
        _brandController.text.trim().isEmpty ||
        _expirationDateController.text.trim().isEmpty ||
        _unitMeasurementController.text.trim().isEmpty ||
        _specificationController.text.trim().isEmpty ||
        _quantityController.text.trim().isEmpty) {

      Get.snackbar("Error", "Please fill all required fields",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    try {
      // Get server IP
      final serverIp = await _getCurrentServerIp();
      print("🌐 Attempting connection to: $serverIp");
      print("Adding to server");

      // Create payload (server will add timestamp)
      final newData = {
        'storageCode': _storageCodeController.text,
        'serialNo': _serialNoController.text,
        'itemName': _itemNameController.text,
        'brand': _brandController.text,
        'expirationDate': _expirationDateController.text,
        'unitMeasurement': _unitMeasurementController.text,
        'specification': _specificationController.text,
        'quantity': int.tryParse(_quantityController.text) ?? 0,
      };

      // Make HTTP request
      final response = await http.post(
        Uri.parse('http://$serverIp:8080/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newData),
      ).timeout(Duration(seconds: 5));

      print("🔄 Server response: ${response.statusCode}");
      print("📦 Response body: ${response.body}");

      if (response.statusCode == 201) {
        Get.snackbar("Success", "Data saved to server!",
            backgroundColor: Colors.green, colorText: Colors.white);
        await _loadFromServer(); // Refresh from server
      } else {
        Get.snackbar("Error", "Server error: ${response.body}",
            backgroundColor: Colors.red, colorText: Colors.white);
        return;
      }
    } on SocketException catch (e) {
      Get.snackbar("Error", "No network connection: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    } on TimeoutException catch (e) {
      Get.snackbar("Error", "Server timeout: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    } catch (e) {
      Get.snackbar("Error", "Unexpected error: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Only clear if successful
    _clearFormFields();
    Get.back();
    Navigator.pop(context);
  }

  /// 🌐 Get Current Server IP Address
  Future<String> _getCurrentServerIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print("⚠️ Error getting IP: $e");
    }
    return '10.0.2.2'; // Fallback for emulators
  }

  /// 🔄 Load Data from Server
  Future<void> _loadFromServer() async {
    try {
      final serverIp = await _getCurrentServerIp();
      final response = await http.get(Uri.parse('http://$serverIp:8080/items'));

      if (response.statusCode == 200) {
        setState(() {
          _offlineData = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to refresh data: ${e.toString()}",
          backgroundColor: Colors.red);
    }
  }


  /// ✅ Clear All Form Fields
  void _clearFormFields() {
    _storageCodeController.clear();
    _serialNoController.clear();
    _itemNameController.clear();
    _brandController.clear();
    _expirationDateController.clear();
    _unitMeasurementController.clear();
    _specificationController.clear();
    _quantityController.clear();
  }

  /// ☁️ Upload Data to Online Database
  Future<void> _uploadToOnline() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      final localData = await _databaseHelper.getAllData();

      for (var item in localData) {
        final String itemName = item['itemName'];
        final String serialNo = item['serialNo'];
        final String brand = item['brand'];
        final String storageCode = item['storageCode'];
        final String expirationDate = item['expirationDate'];
        final int quantity = item['quantity'];

        // 🔍 Find matching item in Firebase
        final querySnapshot = await firestore
            .collection('stock')
            .doc('Medical_Equipments')
            .collection('items') // Change this to your actual Firebase collection name
            .where('itemName', isEqualTo: itemName)
            .where('serialNo', isEqualTo: serialNo)
            .where('brand', isEqualTo: brand)
            .where('storageCode', isEqualTo: storageCode)
            .where('expirationDate', isEqualTo: expirationDate)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          final existingData = doc.data();
          final existingQty = existingData['quantity'] ?? 0;

          // ✅ Update quantity and expiration date
          await firestore.collection('items').doc(doc.id).update({
            'quantity': existingQty + quantity,
            'expirationDate': expirationDate, // Optional: can be skipped if not needed
          });

          // ✅ Delete locally after successful sync
          await _databaseHelper.deleteDataById(item['id']);

          print("✅ Synced and deleted local item: ${item['itemName']}");
        } else {
          print("⚠️ No match found for: ${item['itemName']} (${item['serialNo']})");
        }
      }

      await _loadOfflineData(); // Refresh list
      Get.snackbar("Success", "Offline data uploaded to Firebase",
          backgroundColor: Colors.green, colorText: Colors.white);

    } catch (e) {
      print("❌ Upload error: $e");
      Get.snackbar("Error", "Upload failed: ${e.toString()}",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }


  /// ✅ Use Item Dialog
  void _showUseItemDialog(Map<String, dynamic> item) {
    final int id = item['id'];
    final int currentQuantity = int.tryParse(item['quantity'].toString()) ?? 0;
    final TextEditingController _quantityUsedController = TextEditingController();
    final controller = Get.find<ConnectToOfflineController>();

    showDialog(
      context: Get.context!,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔴 Title with Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "🧰 Use Item",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: MyColors.red,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.grey[700]),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  Divider(),

                  // 🔹 Item Details
                  _buildInfoRow("Item Name", item['itemName']),
                  _buildInfoRow("Serial No", item['serialNo']),
                  _buildInfoRow("Brand", item['brand']),
                  _buildInfoRow("Storage Code", item['storageCode']),
                  _buildInfoRow("Expiration Date", item['expirationDate']),
                  _buildInfoRow("Unit", item['unitMeasurement']),
                  _buildInfoRow("Specification", item['specification']),
                  SizedBox(height: 10),

                  Text(
                    "Current Quantity: $currentQuantity",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: MyColors.orange,
                    ),
                  ),

                  SizedBox(height: 16),

                  _buildTextField("Quantity to Use", _quantityUsedController, isNumeric: true),

                  SizedBox(height: 20),

                  // ✅ Update Button
                  GestureDetector(
                    onTap: () async {
                      final quantityUsed = int.tryParse(_quantityUsedController.text) ?? 0;

                      if (quantityUsed <= 0) {
                        Get.snackbar("Error", "Please enter a valid quantity.",
                            backgroundColor: Colors.red, colorText: Colors.white);
                        return;
                      }

                      final newQuantity = currentQuantity - quantityUsed;

                      if (newQuantity < 0) {
                        Get.snackbar("Error", "Insufficient stock.",
                            backgroundColor: Colors.red, colorText: Colors.white);
                        return;
                      }

                      final success = await controller.updateItemQuantity(id, newQuantity);

                      if (success) {
                        await _loadOfflineData();
                        Navigator.of(context).pop();
                        Get.snackbar("Success", "Quantity updated successfully!",
                            backgroundColor: Colors.green, colorText: Colors.white);
                      } else {
                        Get.snackbar("Error", "Failed to update quantity",
                            backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: MyColors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text("Update",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // ❌ Cancel Button
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        "$label: $value",
        style: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600,fontSize: 16)),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade500),
            borderRadius: BorderRadius.circular(5),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }




  void _confirmDeleteOfflineData(int id) {
    showDialog(
      context: Get.context!,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            "Confirm Delete",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: MyColors.red,
            ),
          ),
          content: Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("No", style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              onPressed: () async {
                await _databaseHelper.deleteDataById(id);
                await _loadOfflineData(); // Refresh list
                Navigator.of(context).pop(); // Close dialog
                Get.snackbar(
                  "Deleted",
                  "Item deleted successfully",
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              },
              child: Text("Yes", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }



  /// ✅ Add New Data Dialog
  void _showAddDataDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Container(
          height: 500,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔴 Custom Title Row with "X" Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add New Data",
                    style: TextStyle(
                      color: MyColors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey[700]),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),

              Divider(),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField("Storage Code", _storageCodeController),
                      _buildTextField("Serial No.", _serialNoController),
                      _buildTextField("Item Name", _itemNameController),
                      _buildTextField("Brand", _brandController),
                      _buildTextField("Expiration Date (YYYY-MM-DD)", _expirationDateController),
                      _buildTextField("Unit of Measurement", _unitMeasurementController),
                      _buildTextField("Specifications", _specificationController),
                      _buildTextField("Quantity", _quantityController, isNumeric: true),

                      SizedBox(height: 20),

                      GestureDetector(
                        onTap: _addNewData,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: MyColors.red,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Center(
                            child: Text("Add Data", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),

                      SizedBox(height: 12),

                      Center(
                        child: TextButton(
                          onPressed: () => Get.back(),
                          child: Text("Cancel", style: TextStyle(color: Colors.grey[700])),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }


  Widget _buildGridButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offline Database", style: TextStyle(color: Colors.white)),
        backgroundColor: MyColors.red,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        elevation: 4,
        shadowColor: Colors.blue.shade200,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3, // Adjust this for button height
                physics: NeverScrollableScrollPhysics(), // Prevent scroll
                children: [
                  _buildGridButton(
                    icon: Icons.add,
                    label: "Add New Data",
                    color: MyColors.orange,
                    onTap: _showAddDataDialog,
                  ),
                  _buildGridButton(
                    icon: Icons.stop_circle,
                    label: "Stop Server",
                    color: MyColors.red,
                    onTap: _stopServer,
                  ),
                  _buildGridButton(
                    icon: Icons.cloud_upload,
                    label: "Upload to Online",
                    color: MyColors.orange,
                    onTap: _uploadToOnline,
                  ),
                  _buildGridButton(
                    icon: Icons.wifi_tethering,
                    label: "Start Local Server",
                    color: MyColors.red,
                    onTap: _startServer,
                  ),
                ],
              ),
            ),
          ),


          Obx(() => _isServerRunning.value
              ? Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  "Server running at: ${_serverIp.value}:8080",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
              : SizedBox.shrink()),



          // ✅ Display Offline Data
          // ✅ Display Offline Data
          Expanded(
            child: _offlineData.isEmpty
                ? Center(child: Text("No offline data available."))
                : ListView.builder(
              itemCount: _offlineData.length,
              itemBuilder: (context, index) {
                final entry = _offlineData[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal:20.0, vertical: 5),
                  child: GestureDetector(
                    onTap: () => _showUseItemDialog(entry), // 👈 Make the card clickable
                    child: Card(

                      child: ListTile(
                        title: Text(entry['itemName'] ?? "Unknown Data"),
                        subtitle: Text("Quantity: ${entry['quantity']}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red), // "Delete" Button
                          onPressed: () => _confirmDeleteOfflineData(entry['id']),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        ],
      ),
    );


  }
}