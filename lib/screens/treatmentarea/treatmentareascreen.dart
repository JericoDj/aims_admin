import 'package:aims_admin/screens/treatmentarea/itemMonthlyUsageScreen.dart';
import 'package:aims_admin/screens/treatmentarea/treatment_area_qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/colors.dart';
import 'historychart.dart';

class TreatmentAreaScreen extends StatelessWidget {
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
                icon: Icon(Icons.arrow_back, color: MyColors.white, size: 28),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
                onPressed: () {
                  Get.back();
                },
              ),
            ),
          ),
          title: Text(
            "TREATMENT AREA",
            style: TextStyle(
              color: MyColors.red,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),

            // QR Scanner Button
            Center(
              child: GestureDetector(
                onTap: () {
                  Get.to(() => TreatmentQRScannerScreen());
                },
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: MyColors.darkRed, width: 3),
                        color: MyColors.darkRed,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 100,
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "QR SCANNER",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // History Chart Button
            Center(
              child: GestureDetector(
                onTap: () {
                  Get.to(() => ItemMonthlyUsageScreen());
                },
                child: Column(
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: MyColors.orange, width: 3),
                        color: MyColors.orange,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.event_note,
                          color: Colors.white,
                          size: 100,
                        ),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      "HISTORY CHART",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
