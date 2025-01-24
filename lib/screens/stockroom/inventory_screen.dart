import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/colors.dart';
class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, String>> allItems = [
    {"serial": "SN1001", "name": "Medical Syringe", "stock": "25", "unit": "Box", "category": "Medical Supplies"},
    {"serial": "SN1002", "name": "Gloves", "stock": "50", "unit": "Pack", "category": "Safety Equipment"},
    {"serial": "SN1003", "name": "Face Mask", "stock": "100", "unit": "Box", "category": "Safety Equipment"},
    {"serial": "SN1004", "name": "Alcohol", "stock": "75", "unit": "Bottle", "category": "Sanitation"},
    {"serial": "SN1005", "name": "Bandage", "stock": "40", "unit": "Roll", "category": "First Aid"},
  ];

  List<Map<String, String>> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = List.from(allItems);
  }

  void filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = List.from(allItems);
      } else {
        filteredItems = allItems.where((item) {
          return item["name"]!.toLowerCase().contains(query.toLowerCase()) ||
              item["serial"]!.toLowerCase().contains(query.toLowerCase()) ||
              item["category"]!.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.red,
        centerTitle: true,
        title: Text(
          "INVENTORY",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: EdgeInsets.all(10.0),
            child: TextField(
              controller: searchController,
              onChanged: filterSearch,
              decoration: InputDecoration(
                hintText: "Search item...",
                prefixIcon: Icon(Icons.search, color: MyColors.red),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: MyColors.red),
                ),
              ),
            ),
          ),

          // List of Inventory Items
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                var item = filteredItems[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: MyColors.red, width: 1),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item['name']}",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyColors.red),
                        ),
                        SizedBox(height: 5),
                        Text("Serial No.: ${item['serial']}"),
                        Text("Available Stock: ${item['stock']}"),
                        Text("Unit: ${item['unit']}"),
                        Text("Category: ${item['category']}"),
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
