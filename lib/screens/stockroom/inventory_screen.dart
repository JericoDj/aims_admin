import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/colors.dart';

class InventoryScreen extends StatefulWidget {
  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> allItems = []; // Stores Firestore data
  List<Map<String, dynamic>> filteredItems = []; // Filtered data

  @override
  void initState() {
    super.initState();
    fetchInventory(); // Fetch Firestore data
  }

  /// **Fetch Inventory Items from Firestore**
  Future<void> fetchInventory() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection("items").get();

      List<Map<String, dynamic>> fetchedItems = querySnapshot.docs.map((doc) {
        return {
          "id": doc.id, // Store document ID for reference
          "serial": doc["serial_no"] ?? "N/A",
          "name": doc["item_name"] ?? "Unknown Item",
          "stock": doc["stock"] ?? "0",
          "unit": doc["unit_measurement"] ?? "Unit",
          "category": doc["category"] ?? "Uncategorized",
        };
      }).toList();

      setState(() {
        allItems = fetchedItems;
        filteredItems = fetchedItems;
      });
    } catch (e) {
      print("❌ Error fetching inventory: $e");
      Get.snackbar("Error", "Failed to load inventory.");
    }
  }

  /// **Search Filter**
  void filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredItems = List.from(allItems);
      } else {
        filteredItems = allItems.where((item) {
          return item["name"].toString().toLowerCase().contains(query.toLowerCase()) ||
              item["serial"].toString().toLowerCase().contains(query.toLowerCase()) ||
              item["category"].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
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
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MyColors.darkRed,
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: MyColors.white, size: 36),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
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
              onPressed: fetchInventory, // Refresh inventory data
            )
          ],
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

            // Inventory List
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                child: Text(
                  "No items found.",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MyColors.red),
                ),
              )
                  : ListView.builder(
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
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: MyColors.red),
                          ),
                          Text("Serial No.: ${item['serial']}", style: TextStyle(fontSize: 18)),
                          Text("Available Stock: ${item['stock']}", style: TextStyle(fontSize: 18)),
                          Text("Unit: ${item['unit']}", style: TextStyle(fontSize: 18)),
                          Text("Category: ${item['category']}", style: TextStyle(fontSize: 18)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
