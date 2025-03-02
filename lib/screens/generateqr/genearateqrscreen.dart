import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import '../../controllers/qr_code_controller.dart';

class GenerateQRCodeScreen extends StatelessWidget {
  final QRCodeController controller = Get.put(QRCodeController());

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

                SizedBox(height: 20),

                // Create Item Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: controller.generateQRCode,
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        validator: (value) => value == null || value.isEmpty ? "This field is required" : null,
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
