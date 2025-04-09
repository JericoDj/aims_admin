import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../controllers/qr_code_controller.dart';

class GenerateQRCodeScreen extends StatelessWidget {
  final QRCodeController controller = Get.put(QRCodeController());


  bool _isFormDataTooLong(QRCodeController controller, {int maxChars = 85}) {
    int totalChars = 0;

    List<TextEditingController> fields = [
      controller.storageCodeController,
      controller.serialNoController,
      controller.itemNameController,
      controller.brandController,
      controller.expirationDateController,
      controller.unitMeasurementController,
      controller.specificationController,
      controller.quantityController,
    ];

    for (var ctrl in fields) {
      totalChars += ctrl.text.trim().length;
    }

    print("🔢 Total form characters: $totalChars");
    return totalChars > maxChars;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.red,
        centerTitle: true,
        title: Text(
          "Generate QR Code",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("New Item", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyColors.red)),
                SizedBox(height: 10),

                // Category Dropdown
                Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                Obx(() => DropdownButtonFormField<String>(
                  value: controller.selectedCategory.value,
                  decoration: _inputDecoration(),
                  onChanged: (newValue) => controller.selectedCategory.value = newValue!,
                  items: controller.categories.map((category) {
                    return DropdownMenuItem(value: category, child: Text(category));
                  }).toList(),
                )),
                SizedBox(height: 10),

                // Input Fields
                _buildTextField("Storage Code", controller.storageCodeController),
                _buildTextField("Serial No.", controller.serialNoController),
                _buildTextField("Item Name", controller.itemNameController),
                _buildTextField("Brand", controller.brandController),
                _buildTextField("Expiration Date (YYYY-MM-DD)", controller.expirationDateController),
                _buildTextField("Unit of Measurement", controller.unitMeasurementController),
                _buildTextField("Specifications", controller.specificationController),
                _buildTextField("Quantity", controller.quantityController, isNumeric: true), // ✅ Added Quantity Field

                Obx(() => Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Character Count: ${controller.totalCharacterCount.value} / 85",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: controller.totalCharacterCount.value > 85 ? Colors.red : Colors.grey[700],
                    ),
                  ),
                )),
                SizedBox(height: 10),



                SizedBox(height: 20),

                // Create Item Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_isFormDataTooLong(controller)) {
                        Get.snackbar(
                          "Character Limit Exceeded",
                          "Total character count must not exceed 85 characters.",
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                        return;
                      }
                      controller.generateQRCode();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyColors.orange,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      "CREATE ITEM",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: _inputDecoration(label),
        validator: (value) => value == null || value.isEmpty ? "This field is required" : null,
        onChanged: (_) => this.controller.updateCharacterCount(),
      ),
    );
  }

  InputDecoration _inputDecoration([String hintText = ""]) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}
