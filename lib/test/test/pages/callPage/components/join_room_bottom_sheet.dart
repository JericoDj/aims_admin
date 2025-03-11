import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../homePage/components/custom_button.dart';
import '../call_page.dart';

Future<void> joinRoomBottomSheet(BuildContext context) {
  final textEditingController = TextEditingController();

  return showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    ),
    builder: (context) {
      final size = MediaQuery.of(context).size;

      return SingleChildScrollView(
        padding: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 30.0,
            minWidth: size.width,
            maxHeight: size.height - 110,
            maxWidth: size.width,
          ),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 40),
              const Text(
                "Enter the room id.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17.0),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: textEditingController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter Room ID...",
                  labelText: "Enter Room ID...",
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Join Room",
                onTap: () async {
                  try {
                    String roomId = textEditingController.text.trim();

                    // Close the bottom sheet
                    Get.back();

                    // Navigate to CallPage using GetX
                    Get.to(
                      CallPage(
                        roomId: roomId,
                        isCaller: false,
                      ),
                    );
                  } catch (e) {
                    debugPrint("$e");
                  }
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    },
  );
}
