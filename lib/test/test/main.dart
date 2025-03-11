import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'utils/firebase_options.dart';
import 'services/webrtc_service.dart';
import 'pages/homePage/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      name: "WebRTC Video Call",
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Initialize the WebRtcService using GetX
  Get.put(WebRtcService());

  runApp(const MyApp2());
}

class MyApp2 extends StatelessWidget {
  const MyApp2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WebRTC Video Call',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage2(),
    );
  }
}
