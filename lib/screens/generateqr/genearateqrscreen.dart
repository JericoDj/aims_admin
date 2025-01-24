import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';
import 'generated_qr_code_screen.dart';

class GenerateQRCodeScreen extends StatefulWidget {
  @override
  _GenerateQRCodeScreenState createState() => _GenerateQRCodeScreenState();
}

class _GenerateQRCodeScreenState extends State<GenerateQRCodeScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  TextEditingController storageCodeController = TextEditingController();
  TextEditingController serialNoController = TextEditingController();
  TextEditingController itemNameController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController expirationDateController = TextEditingController();
  TextEditingController unitMeasurementController = TextEditingController();
  TextEditingController specificationController = TextEditingController();

  // Category Dropdown List
  String selectedCategory = "Medical Supplies"; // Default selection
  List<String> categories = [
    "Medical Supplies",
    "Safety Equipment",
    "First Aid",
    "Sanitation",
    "Pharmaceuticals"
  ];

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
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white, // 🔥 Dynamically changes
          ),
          onPressed: () {
            Get.back(); // Navigate back
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New Item",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyColors.red),
                ),
                SizedBox(height: 10),

                // Category Dropdown
                Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: _inputDecoration(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                  items: categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),

                // Input Fields
                _buildTextField("Storage Code", storageCodeController),
                _buildTextField("Serial No.", serialNoController),
                _buildTextField("Item Name", itemNameController),
                _buildTextField("Brand", brandController),
                _buildTextField("Expiration Date (YYYY-MM-DD)", expirationDateController),
                _buildTextField("Unit of Measurement", unitMeasurementController),
                _buildTextField("Specifications", specificationController),

                SizedBox(height: 20),

                // Create Item Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateQRCode,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.back();
        },
        backgroundColor: MyColors.red,
        child: Icon(Icons.arrow_back, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Function to Generate QR Code (Placeholder for Now)
  void _generateQRCode() {
    if (_formKey.currentState!.validate()) {
      // Collect item details
      Map<String, String> itemDetails = {
        "Storage Code": storageCodeController.text,
        "Serial No": serialNoController.text,
        "Item Name": itemNameController.text,
        "Brand": brandController.text,
        "Expiration Date": expirationDateController.text,
        "Unit of Measurement": unitMeasurementController.text,
        "Specifications": specificationController.text,
        "Category": selectedCategory
      };

      // Navigate to Generated QR Screen
      Get.to(() => GeneratedQRCodeScreen(itemDetails: itemDetails));
    }
  }


  // Function to Build Text Fields
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "This field is required";
          }
          return null;
        },
      ),
    );
  }

  // Input Field Styling
  InputDecoration _inputDecoration([String hintText = ""]) {
    return InputDecoration(
      hintText: hintText,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    );
  }
}
