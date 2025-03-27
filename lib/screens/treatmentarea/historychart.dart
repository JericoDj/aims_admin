import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/colors.dart';

class HistoryChartScreen extends StatefulWidget {
  @override
  _HistoryChartScreenState createState() => _HistoryChartScreenState();
}

class _HistoryChartScreenState extends State<HistoryChartScreen> {
  String selectedCategory = "All"; // Default category selection
  List<String> categories = ["All"];
  Map<String, List<int>> categoryUsageData = {};
  List<Map<String, dynamic>> recentUsage = []; // List to store recent medicine usage

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  /// **Fetch history data from Firestore**
  Future<void> _fetchHistoryData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection("history").get();

      Map<String, List<int>> usageData = {};
      List<Map<String, dynamic>> usageList = [];
      Set<String> uniqueCategories = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String category = data["Category"] ?? "Uncategorized";
        String itemName = data["Item Name"] ?? "Unknown";
        String action = data["Action"] ?? "Unknown";
        // Handle different quantity fields based on action
        // Fixed quantity parsing
        int quantity = 0;
        if (action == "Add Stock") {
          quantity = (data["Quantity Added"] is num)
              ? (data["Quantity Added"] as num).toInt()
              : int.tryParse(data["Quantity Added"]?.toString() ?? '0') ?? 0;
        } else {
          quantity = (data["Quantity"] is num)
              ? (data["Quantity"] as num).toInt()
              : int.tryParse(data["Quantity"]?.toString() ?? '0') ?? 0;
        }

        // ✅ Ensure correct date field is used
        String date = action == "Generate QR Code"
            ? data["Date Generated"] ?? "No Date"
            : data["Date Updated"] ?? "No Date";

        // ✅ Store in recent usage list
        usageList.add({
          "Item Name": itemName,
          "Quantity": quantity.toString(), // ✅ Renamed from "Stock" to "Quantity"
          "Category": category,
          "Action": action,
          "Date": date,
        });

        // Add category to set (avoiding duplicates)
        uniqueCategories.add(category);

        // Add to category usage count
        if (!usageData.containsKey(category)) {
          usageData[category] = [];
        }
        usageData[category]!.add(quantity);
      }

      // Ensure "All" category includes all values
      usageData["All"] = usageData.values.expand((list) => list).toList();

      setState(() {
        categoryUsageData = usageData;
        recentUsage = usageList;
        categories = ["All", ...uniqueCategories.toList()];
      });
    } catch (e) {
      print("❌ Error fetching history data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double chartHeight = MediaQuery.of(context).size.height / 3;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyColors.red,
        centerTitle: true,
        title: Text(
          "Usage History",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Filter Dropdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter by Category:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyColors.red),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: MyColors.red),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    icon: Icon(Icons.arrow_drop_down, color: MyColors.red),
                    underline: SizedBox(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                    items: categories.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: MyColors.red)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),

            SizedBox(height: 10),

            // Chart takes only 1/3 of the screen height
            SizedBox(
              height: chartHeight,
              child: categoryUsageData.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : BarChart(
                BarChartData(
                  barGroups: _generateChartData(selectedCategory),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          List<String> keys = categoryUsageData.keys.toList();
                          if (value.toInt() >= keys.length) return SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(keys[value.toInt()], style: TextStyle(fontSize: 12)),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  barTouchData: BarTouchData(enabled: true),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Recent Medicine Usage List
            Text(
              "Recent Medicine Usage",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyColors.red),
            ),
            Expanded(
              child: recentUsage.isEmpty
                  ? Center(child: Text("No usage history found.", style: TextStyle(color: MyColors.red)))
                  : ListView.builder(
                itemCount: recentUsage.length,
                itemBuilder: (context, index) {
                  var item = recentUsage[index];
                  return _buildMedicineItem(item); // Pass full item map
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// **Generate Chart Data from Firestore**
  List<BarChartGroupData> _generateChartData(String category) {
    final data = categoryUsageData[category] ?? [];

    return List.generate(data.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].toDouble(),
            color: MyColors.orange,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  // Updated _buildMedicineItem to handle full item data
  Widget _buildMedicineItem(Map<String, dynamic> item) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: MyColors.red, width: 1),
      ),
      child: ListTile(
        title: Text(item["Item Name"], style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item["Action"] == "Add Stock"
                  ? "Quantity Added: ${item["Quantity Added"] ?? item["Quantity"]}"
                  : "Quantity: ${item["Quantity"]}",
              style: TextStyle(color: MyColors.red),
            ),
            Text("Category: ${item["Category"]}"),
            Text("Action: ${item["Action"]}"),
            Text("Date: ${item["Date"]}"),
          ],
        ),
        trailing: Icon(Icons.history, color: MyColors.red),
        onTap: () => _showItemDetailsDialog(item),
      ),
    );
  }

// New dialog showing detailed information
  void _showItemDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Item Details",
            style: TextStyle(color: MyColors.red, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Item Name:", item["Item Name"]),
              _buildDetailRow("Action:", item["Action"]),
              _buildDetailRow("Category:", item["Category"]),
              if (item["Action"] == "Add Stock") ...[
                _buildDetailRow("Quantity Added:", item["Quantity Added"]),
                _buildDetailRow("New Total:", item["New Total"]),
              ],
              _buildDetailRow("Date:", item["Date"]),
              if (item.containsKey("Notes"))
                _buildDetailRow("Notes:", item["Notes"]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text("Close", style: TextStyle(color: MyColors.red)),
          ),
        ],
      ),
    );
  }

// Reusable detail row widget
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: MyColors.red)),
          SizedBox(width: 8),
          Expanded(child: Text(value, style: TextStyle(color: Colors.black))),
        ],
      ),
    );
  }
}