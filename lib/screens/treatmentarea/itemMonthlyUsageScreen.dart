import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';

class ItemMonthlyUsageScreen extends StatefulWidget {
  @override
  _ItemMonthlyUsageScreenState createState() => _ItemMonthlyUsageScreenState();
}

class _ItemMonthlyUsageScreenState extends State<ItemMonthlyUsageScreen> {
  Map<String, Map<String, int>> usageByItem = {}; // Key: "Item Name | Brand"
  String? selectedKey;

  final List<String> allMonths = const [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  @override
  void initState() {
    super.initState();
    fetchMonthlyUsageData();
  }

  Future<void> fetchMonthlyUsageData() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection("history")
          .where("Action", isEqualTo: "Treatment Use")
          .get();

      Map<String, Map<String, int>> tempData = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        String itemName = data["Item Name"] ?? "Unknown";
        String brand = data["Brand"] ?? "Unknown";
        String key = "$itemName | $brand";

        int quantity = (data["Quantity"] is num)
            ? (data["Quantity"] as num).toInt()
            : int.tryParse(data["Quantity"]?.toString() ?? '0') ?? 0;

        DateTime date = DateTime.tryParse(data["Date Updated"] ?? "") ?? DateTime.now();
        String month = allMonths[date.month - 1];

        if (!tempData.containsKey(key)) tempData[key] = {};
        tempData[key]![month] = (tempData[key]![month] ?? 0) + quantity;
      }

      setState(() {
        usageByItem = tempData;
        selectedKey = tempData.keys.isNotEmpty ? tempData.keys.first : null;
      });
    } catch (e) {
      print("❌ Error fetching usage data: $e");
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
          onPressed: () => Get.back(),
        ),
      ),
      body: usageByItem.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Title
            Text(
              selectedKey ?? '',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: MyColors.red),
            ),
            SizedBox(height: 10),

            // Chart
            SizedBox(
              height: chartHeight,
              child: BarChart(
                BarChartData(
                  barGroups: _buildBarChartData(usageByItem[selectedKey] ?? {}),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= allMonths.length) return SizedBox();
                          return Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(allMonths[value.toInt()], style: TextStyle(fontSize: 12)),
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

            // List of Items with Brands
            Text(
              "Select Item",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyColors.red),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: usageByItem.keys.length,
                itemBuilder: (context, index) {
                  String key = usageByItem.keys.elementAt(index);
                  List<String> parts = key.split('|');
                  String itemName = parts[0].trim();
                  String brand = parts.length > 1 ? parts[1].trim() : "N/A";

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: MyColors.red, width: 1),
                    ),
                    child: ListTile(
                      title: Text(itemName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Brand: $brand"),
                      trailing: Icon(Icons.bar_chart, color: MyColors.red),
                      onTap: () {
                        setState(() {
                          selectedKey = key;
                        });
                      },
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

  List<BarChartGroupData> _buildBarChartData(Map<String, int> monthlyData) {
    return List.generate(allMonths.length, (index) {
      final month = allMonths[index];
      final value = monthlyData[month] ?? 0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: MyColors.orange,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
