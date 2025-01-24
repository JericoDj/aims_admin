import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:get/get.dart';

import '../../utils/colors.dart';

class HistoryChartScreen extends StatefulWidget {
  @override
  _HistoryChartScreenState createState() => _HistoryChartScreenState();
}

class _HistoryChartScreenState extends State<HistoryChartScreen> {
  String selectedCategory = "All"; // Default category selection
  List<String> categories = ["All", "Antibiotics", "Painkillers", "Vitamins", "First Aid", "Sanitation"];

  Map<String, List<int>> categoryUsageData = {
    "All": [45, 60, 30, 25, 50],
    "Antibiotics": [45],
    "Painkillers": [60],
    "Vitamins": [30],
    "First Aid": [25],
    "Sanitation": [50],
  };

  @override
  Widget build(BuildContext context) {
    double chartHeight = MediaQuery.of(context).size.height / 3; // 1/3 of screen height

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
              child: BarChart(
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
                          const categories = ["Antibiotics", "Painkillers", "Vitamins", "First Aid", "Sanitation"];
                          return Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(categories[value.toInt()], style: TextStyle(fontSize: 12)),
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
              child: ListView(
                children: [
                  _buildMedicineItem("SN1001", "Medical Syringe", "25", "Antibiotics"),
                  _buildMedicineItem("SN1002", "Gloves", "50", "First Aid"),
                  _buildMedicineItem("SN1003", "Face Mask", "100", "Sanitation"),
                  _buildMedicineItem("SN1004", "Alcohol", "75", "Sanitation"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildMedicineItem(String serial, String name, String stock, String category) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: MyColors.red, width: 1),
      ),
      child: ListTile(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Serial No: $serial | Stock: $stock | Category: $category"),
        trailing: Icon(Icons.history, color: MyColors.red),
      ),
    );
  }
}
