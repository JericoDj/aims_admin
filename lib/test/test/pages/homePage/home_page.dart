import "package:flutter/material.dart";
import '../callPage/call_page.dart';
import '../callPage/components/join_room_bottom_sheet.dart';
import 'components/custom_button.dart';

class HomePage2 extends StatefulWidget {
  const HomePage2({super.key});

  @override
  State<HomePage2> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage2> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        elevation: 2.0,
        centerTitle: true,
        title: const Text(
          "WebRTC Video Call",
          style: TextStyle(
            fontSize: 17.0,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          Row(
            children: [
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: "New Room",
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CallPage(
                          roomId: null,
                          isCaller: true,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Expanded(
                flex: 1,
                child: CustomButton(
                  text: "Join Room",
                  buttonColor: Colors.white,
                  textColor: Colors.blue.shade600,
                  onTap: () {
                    joinRoomBottomSheet(context);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          Image.network(
            "https://i.imgur.com/B44EzJM.png",
            fit: BoxFit.contain,
            width: size.width / 2,
            height: size.width / 2,
          ),
          const SizedBox(height: 50),
          const Text(
            "Click 'New Room' above to create a new call.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0),
          ),
          const SizedBox(height: 20),
          const Text(
            "To join the call, click 'Join Room' and enter the room id.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0),
          ),
        ],
      ),
    );
  }
}
