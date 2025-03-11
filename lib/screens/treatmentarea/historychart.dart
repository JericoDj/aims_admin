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
      Set<String> uniqueCategories = {}; // ✅ Track unique categories to prevent duplicates

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String category = data["Category"] ?? "Uncategorized";
        int quantity = int.tryParse(data["Quantity"].toString()) ?? 0;
        String itemName = data["Item Name"] ?? "Unknown";
        String action = data["Action"] ?? "Unknown";

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

        // ✅ Ensure "All" is added only once at the start
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
                  return _buildMedicineItem(
                    item["Item Name"],
                    item["Quantity"], // ✅ Used "Quantity" instead of "Stock"
                    item["Category"],
                    item["Action"],
                    item["Date"],
                  );
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

  /// **Build Medicine Usage Item**
  Widget _buildMedicineItem(String name, String quantity, String category, String action, String date) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: MyColors.red, width: 1),
      ),
      child: ListTile(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Quantity: $quantity | Category: $category\nAction: $action | Date: $date"),
        trailing: Icon(Icons.history, color: MyColors.red),
      ),
    );
  }
}
