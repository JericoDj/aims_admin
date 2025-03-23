import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      // Check if the server is already running
      if (_localServer.isServerRunning()) {
        Get.snackbar("Info", "Server is already running.",
            backgroundColor: Colors.blue, colorText: Colors.white);
        return; // Exit if the server is already running
      }

      // Fetch the network interface and the device's local IP
      final interfaces = await NetworkInterface.list();
      final wifiInterface = interfaces.firstWhere(
            (interface) => interface.name == 'wlan0' || interface.name == 'en0',
        orElse: () => interfaces.first, // Fallback if interface name differs
      );

      final serverIp = wifiInterface.addresses
          .firstWhere((addr) => addr.type == InternetAddressType.IPv4)
          .address;

      // Start the server if it's not already running
      await _localServer.startServer();

      Get.snackbar(
        "Server Started",
        "Connect to IP: $serverIp:8080",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      print('✅ Server started at: http://$serverIp:8080');
    } catch (e) {
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
    // Ensure quantity is parsed correctly
    final int id = item['id'];
    final int currentQuantity = int.tryParse(item['quantity'].toString()) ?? 0;
    final TextEditingController _quantityUsedController = TextEditingController();
    final controller = Get.find<ConnectToOfflineController>();


    Get.defaultDialog(
      title: "Use Item",
      content: Container(
        height: 380,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Item Name: ${item['itemName']}"),
              Text("Serial No: ${item['serialNo']}"),
              Text("Brand: ${item['brand']}"),
              Text("Storage Code: ${item['storageCode']}"),
              Text("Expiration Date: ${item['expirationDate']}"),
              Text("Unit: ${item['unitMeasurement']}"),
              Text("Specification: ${item['specification']}"),
              SizedBox(height: 8),
              Text("Current Quantity: $currentQuantity", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              _buildTextField("Quantity to Use", _quantityUsedController, isNumeric: true),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      print("🟢 Update button pressed!");
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
                      print("📬 Update success? $success");

                      if (success) {
                        await _loadOfflineData();
                        Get.back();
                        Get.snackbar("Success", "Quantity updated successfully!",
                            backgroundColor: Colors.green, colorText: Colors.white);
                      } else {
                        Get.snackbar("Error", "Failed to update quantity",
                            backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    } catch (e, stack) {
                      print("💥 Unexpected error: $e");
                      Get.snackbar("Error", "Update failed: ${e.toString()}",
                          backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  },
                  child: Text("Update"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

  }



  void _confirmDeleteOfflineData(int id) {
    Get.defaultDialog(
      title: "Confirm Delete",
      middleText: "Are you sure you want to delete this item?",
      backgroundColor: Colors.white,
      titleStyle: TextStyle(fontWeight: FontWeight.bold),
      textConfirm: "Yes",
      textCancel: "No",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        await _databaseHelper.deleteDataById(id);
        await _loadOfflineData(); // Refresh list
        Get.back(); // Close dialog
        Get.snackbar("Deleted", "Item deleted successfully",
            backgroundColor: Colors.red, colorText: Colors.white);
      },
      onCancel: () {
        Get.back(); // Close dialog if cancelled
      },
    );
  }


  /// ✅ Add New Data Dialog
  void _showAddDataDialog() {
    Get.defaultDialog(
      title: "Add New Data",
      content: Container(
        height: 370,  // Set the height of the dialog to 400
        child: SingleChildScrollView(  // Make the content scrollable
          child: Column(
            children: [
              _buildTextField("Storage Code", _storageCodeController),
              _buildTextField("Serial No.", _serialNoController),
              _buildTextField("Item Name", _itemNameController),
              _buildTextField("Brand", _brandController),
              _buildTextField("Expiration Date (YYYY-MM-DD)", _expirationDateController),
              _buildTextField("Unit of Measurement", _unitMeasurementController),
              _buildTextField("Specifications", _specificationController),
              _buildTextField("Quantity", _quantityController, isNumeric: true),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ElevatedButton(
                  onPressed: _addNewData,  // Add data on button press
                  child: Text("Add Data"),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: TextButton(
                  onPressed: () => Get.back(),  // Close the dialog
                  child: Text("Cancel"),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,  // Prevent dialog from being dismissed outside
    );
  }





  /// ✅ Build TextFields for Input
  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offline Database"),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // ✅ Add New Data Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add, color: Colors.white),
              label: Text("Add New Data"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _showAddDataDialog,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.stop_circle, color: Colors.white),
              label: Text("Stop Server"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _stopServer,
            ),
          ),


          // 🚀 Start Server Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.wifi_tethering, color: Colors.white),
              label: Text("Start Local Network Server"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _startServer,
            ),
          ),

          // ☁️ Upload to Online Button
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload, color: Colors.white),
              label: Text("Upload to Online"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () async {
                final FirebaseFirestore firestore = FirebaseFirestore.instance;
                final localData = await _databaseHelper.getAllData();

                List<Map<String, dynamic>> matched = [];
                List<Map<String, dynamic>> unmatched = [];

                for (var item in localData) {
                  final querySnapshot = await firestore
                      .collection('stock')
                      .doc('Medical_Equipments')
                      .collection('items')
                      .where('item_name', isEqualTo: item['itemName'])
                      .where('serial_no', isEqualTo: item['serialNo'])
                      .where('brand', isEqualTo: item['brand'])
                      .where('storage_code', isEqualTo: item['storageCode'])
                      .where('expiration_date', isEqualTo: item['expirationDate'])
                      .get();

                  if (querySnapshot.docs.isNotEmpty) {
                    matched.add({...item, 'docId': querySnapshot.docs.first.id});

                    // 🔍 Debug log for matched item
                    print("✅ MATCHED:");
                    print("📦 item_name: ${item['itemName']}");
                    print("🔢 serial_no: ${item['serialNo']}");
                    print("🏷️ brand: ${item['brand']}");
                    print("📦 storage_code: ${item['storageCode']}");
                    print("🗓️ expiration_date: ${item['expirationDate']}");
                    print("📦 quantity: ${item['quantity']}");
                    print("📄 Firestore Doc ID: ${querySnapshot.docs.first.id}");
                    print("--------------");
                  } else {
                    unmatched.add(item);
                    print("⚠️ UNMATCHED: ${item['itemName']} (${item['serialNo']})");
                  }
                }

                if (matched.isEmpty && unmatched.isEmpty) {
                  Get.snackbar("Info", "No local data found.",
                      backgroundColor: Colors.grey);
                  return;
                }

                Get.bottomSheet(
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    height: 500,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Matched Items", style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: ListView.builder(
                            itemCount: matched.length,
                            itemBuilder: (context, index) {
                              final item = matched[index];
                              return ListTile(
                                  title: Text(item['itemName']),
                                  subtitle: Text("Qty: ${item['quantity']} | Serial: ${item['serialNo']}"),
                                  trailing: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final existingQty = item['quantity'];
                                        final docId = item['docId'];

                                        // ✅ Correct Firestore path based on your structure
                                        final doc = await firestore
                                            .collection('stock')
                                            .doc('Medical_Equipments')
                                            .collection('items')
                                            .doc(docId)
                                            .get();

                                        if (!doc.exists) {
                                          print("❌ Document does not exist: $docId");
                                          Get.snackbar("Error", "Document not found in Firestore.",
                                              backgroundColor: Colors.red, colorText: Colors.white);
                                          return;
                                        }

                                        // ✅ Safely parse quantity even if stored as string
                                        final prevQty = int.tryParse(doc['quantity'].toString()) ?? 0;

                                        // ✅ Update the document in the correct path
                                        await firestore
                                            .collection('stock')
                                            .doc('Medical_Equipments')
                                            .collection('items')
                                            .doc(docId)
                                            .update({
                                          'quantity': prevQty + existingQty,
                                          'expiration_date': item['expirationDate'], // make sure field name matches Firestore
                                        });

                                        // ✅ Delete from local SQLite
                                        await _databaseHelper.deleteDataById(item['id']);

                                        // ✅ Update UI
                                        matched.removeAt(index);
                                        _offlineData.removeWhere((e) => e['id'] == item['id']);
                                        setState(() {});

                                        Get.snackbar("Uploaded", "${item['itemName']} uploaded successfully",

                                            backgroundColor: Colors.green, colorText: Colors.white);
                                        Get.back();
                                      } catch (e) {
                                        print("❌ Upload error: $e");
                                        Get.snackbar("Error", "Failed to upload item: ${e.toString()}",
                                            backgroundColor: Colors.red, colorText: Colors.white);
                                      }
                                    },
                                    child: Text("Upload"),
                                  )

                              );
                            },
                          ),
                        ),
                        Divider(),
                        Text("Unmatched Items", style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: ListView.builder(
                            itemCount: unmatched.length,
                            itemBuilder: (context, index) {
                              final item = unmatched[index];
                              return ListTile(
                                title: Text(item['itemName']),
                                subtitle: Text("Qty: ${item['quantity']} | Serial: ${item['serialNo']}"),
                                trailing: Icon(Icons.warning, color: Colors.orange),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  isScrollControlled: true,
                );
              },
            ),
          ),

          // ✅ Display Offline Data
          Expanded(
            child: _offlineData.isEmpty
                ? Center(child: Text("No offline data available."))
                : ListView.builder(
              itemCount: _offlineData.length,
              itemBuilder: (context, index) {
                final entry = _offlineData[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text(entry['itemName'] ?? "Unknown Data"),
                    subtitle: Text("Quantity: ${entry['quantity']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.handyman, color: Colors.green), // "Use Item" Button
                          onPressed: () => _showUseItemDialog(entry),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red), // "Delete" Button
                          onPressed: () => _confirmDeleteOfflineData(entry['id']),
                        ),
                      ],
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