import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../../utils/local_storage.dart';

class ConnectToOfflineController extends GetxController {
  final RxList<Map<String, dynamic>> serverData = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString serverStatus = ''.obs;
  final RxBool isConnected = false.obs;

  // Server IP Controller
  final TextEditingController serverIpController = TextEditingController();

  // Form Controllers
  final TextEditingController storageCodeController = TextEditingController();
  final TextEditingController serialNoController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController expirationDateController = TextEditingController();
  final TextEditingController unitMeasurementController = TextEditingController();
  final TextEditingController specificationController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  void clearFormFields() {
    storageCodeController.clear();
    serialNoController.clear();
    itemNameController.clear();
    brandController.clear();
    expirationDateController.clear();
    unitMeasurementController.clear();
    specificationController.clear();
    quantityController.clear();
  }



  // function in aims add
  Future<void> addData(Map<String, dynamic> newData) async {
    final serverIp = serverIpController.text;
    if (serverIp.isEmpty) {
      serverStatus.value = "❌ Please enter server IP";
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://$serverIp:8080/items'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newData),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        serverStatus.value = "✅ Data added successfully";
        await fetchData();
      } else {
        serverStatus.value = "❌ Server error: ${response.statusCode}";
      }
    } on SocketException {
      serverStatus.value = "❌ No network connection";
    } on TimeoutException {
      serverStatus.value = "❌ Request timed out";
    } catch (e) {
      serverStatus.value = "❌ Error: ${e.toString()}";
    }
  }
  // function for aims if
  Future<void> deleteData(int id) async {
    print("okay");
    final serverIp = serverIpController.text;
    if (serverIp.isEmpty) {
      serverStatus.value = "❌ Please enter server IP";
      return;
    }

    try {
      final response = await http.delete(

        Uri.parse('http://$serverIp:8080/items/$id'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        serverStatus.value = "✅ Item deleted successfully";
        await fetchData();
      } else {
        serverStatus.value = "❌ Delete failed: ${response.statusCode}";
      }
    } on SocketException {
      serverStatus.value = "❌ No network connection";
    } on TimeoutException {
      serverStatus.value = "❌ Request timed out";
    } catch (e) {
      serverStatus.value = "❌ Error: ${e.toString()}";
    }
  }


  // function in aims update but upon entering we need to save it to local storage the ip.. okay?
  Future<bool> updateItemQuantity(int id, int newQuantity) async {
    print("🚀 Starting updateItemQuantity()");

    // ✅ Get the saved IP from local storage
    final serverIp = LocalStorage.getServerIp();
    print('🌐 Retrieved Server IP: ${serverIp ?? "null"}');

    if (serverIp == null || serverIp.trim().isEmpty) {
      serverStatus.value = "❌ Server IP not found in local storage";
      print("❌ No server IP saved.");
      return false;
    }

    try {
      final url = 'http://$serverIp:8080/items/$id';
      final body = jsonEncode({'quantity': newQuantity});

      print('🔄 Attempting quantity update...');
      print('📤 URL: $url');
      print('📦 Request Body: $body');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 5));

      print('📥 Received response:');
      print('🎚️ Status Code: ${response.statusCode}');
      print('📭 Response Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        serverStatus.value = "✅ Quantity updated successfully";
        await fetchData();
        return true;
      }

      final errorMessage = switch (response.statusCode) {
        400 => 'Invalid request format',
        404 => 'Item not found',
        500 => 'Server internal error',
        _ => 'Unknown error',
      };

      serverStatus.value = "❌ Update failed: $errorMessage (${response.statusCode})";
      return false;

    } catch (e, stackTrace) {
      print('💥 Unexpected error: $e');
      print('🔍 Stack trace: $stackTrace');
      serverStatus.value = "❌ Unexpected error: ${e.toString()}";
      return false;
    }
  }



  Future<void> connectToOfflineServer() async {
    final serverIp = serverIpController.text;
    if (serverIp.isEmpty) {
      serverStatus.value = "❌ Please enter server IP";
      return;
    }

    isLoading.value = true;
    serverStatus.value = "Connecting...";

    try {
      final response = await http.get(
        Uri.parse('http://$serverIp:8080/items'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        serverData.value = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        serverStatus.value = "✅ Connected to server";
        isConnected.value = true;
      } else {
        serverStatus.value = "❌ Connection failed: ${response.statusCode}";
      }
    } on SocketException {
      serverStatus.value = "❌ No network connection";
    } on TimeoutException {
      serverStatus.value = "❌ Connection timed out";
    } catch (e) {
      serverStatus.value = "❌ Error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchData() async {
    final serverIp = serverIpController.text;
    if (serverIp.isEmpty) return;

    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse('http://$serverIp:8080/items'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        serverData.value = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
    } catch (e) {
      serverStatus.value = "❌ Fetch error: ${e.toString()}";
    } finally {
      isLoading.value = false;
    }
  }

  void stopConnection() {
    serverData.clear();
    serverStatus.value = "🛑 Disconnected from server";
    isConnected.value = false;
  }
}