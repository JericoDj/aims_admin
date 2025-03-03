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
    checkFirestoreData(); // Ensure data exists before fetching
    fetchRootCollections();

  }

  Future<void> fetchRootCollections() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("metadata") // Fetch collections from a known document
          .doc("root_collections")
          .get();

      if (doc.exists) {
        List<dynamic> collections = doc["collections"];
        print("📌 Root Collections Found: ${collections.length}");
        for (var collectionName in collections) {
          print("📌 Collection: $collectionName");
        }
      } else {
        print("❌ No root collections metadata found.");
      }
    } catch (e) {
      print("❌ Error fetching root collections: $e");
    }
  }





  /// ✅ Step 1: Check if Firestore contains data
  Future<void> checkFirestoreData() async {
    try {
      QuerySnapshot categoriesSnapshot =
      await FirebaseFirestore.instance.collection("categories").get();

      if (categoriesSnapshot.docs.isEmpty) {
        print("❌ No categories found in Firestore.");
        return;
      }

      print("📌 Found Categories: ${categoriesSnapshot.docs.length}");
      fetchInventory(); // If categories exist, fetch items
    } catch (e) {
      print("❌ Firestore Check Error: $e");
    }
  }

  /// ✅ Step 2: Fetch Inventory Items from Firestore
  Future<void> fetchInventory() async {
    try {
      List<Map<String, dynamic>> fetchedItems = [];

      QuerySnapshot categoriesSnapshot =
      await FirebaseFirestore.instance.collection("categories").get();

      for (var categoryDoc in categoriesSnapshot.docs) {
        String categoryName = categoryDoc.id;
        QuerySnapshot itemsSnapshot =
        await categoryDoc.reference.collection("items").get();

        for (var itemDoc in itemsSnapshot.docs) {
          fetchedItems.add({
            "id": itemDoc.id,
            "serial": itemDoc["serial_no"] ?? "N/A",
            "name": itemDoc["item_name"] ?? "Unknown Item",
            "stock": itemDoc["stock"] ?? "0",
            "unit": itemDoc["unit_measurement"] ?? "Unit",
            "category": categoryName,
          });
        }
      }

      setState(() {
        allItems = fetchedItems;
        filteredItems = fetchedItems;
      });

      print("✅ Inventory Fetched Successfully! Total Items: ${allItems.length}");
    } catch (e) {
      print("❌ Error fetching inventory: $e");
      Get.snackbar("Error", "Failed to load inventory.");
    }
  }

  /// ✅ Step 3: Search Filter
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
