import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationController extends GetxController {
  static const String _fcmUrl = 'https://fcm.googleapis.com/v1/projects/aims-5d185/messages:send';

  // **Generate an OAuth 2.0 access token for Firebase Cloud Messaging**
  Future<String?> getAccessToken() async {
    try {
      // Load service account credentials from assets
      final serviceAccount = await rootBundle.loadString('assets/generated.json');
      final serviceAccountJson = json.decode(serviceAccount);
      final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

      final authClient = await clientViaServiceAccount(
        accountCredentials,
        ['https://www.googleapis.com/auth/firebase.messaging'],
      );

      return authClient.credentials.accessToken.data;
    } catch (e) {
      print("❌ Error getting access token: $e");
      return null;
    }
  }

  // **Fetch all FCM tokens from Firestore**
  Future<List<String>> getAllFcmTokens() async {
    List<String> fcmTokens = [];
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey('fcmToken') && data['fcmToken'] != null) {
          String fcmToken = data['fcmToken'];
          fcmTokens.add(fcmToken);
          print("✅ FCM Token found for user ${doc.id}: $fcmToken");
        } else {
          print("⚠️ No valid FCM token for user ${doc.id}, skipping...");
        }
      }
    } catch (e) {
      print('❌ Error fetching FCM tokens: $e');
    }
    return fcmTokens;
  }

  // **Send notification to a single FCM token**
  Future<void> sendNotificationToToken(String fcmToken, String title, String body) async {
    // Prepare the message data
    final message = {
      'message': {
        'token': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
      },
    };

    try {
      // Get access token
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        print("❌ Failed to get access token. Aborting notification.");
        return;
      }

      // Send the notification to the specified FCM token
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(message),
      );

      // Handle the response
      if (response.statusCode == 200) {
        print("✅ Notification sent to $fcmToken");
      } else {
        print("❌ Failed to send notification to $fcmToken: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending notification to $fcmToken: $e");
    }
  }

  // **Send notification to all users**
  Future<void> sendNotificationToAllUsers(String title, String body) async {
    try {
      List<String> fcmTokens = await getAllFcmTokens();

      if (fcmTokens.isEmpty) {
        print("⚠️ No valid FCM tokens found. Skipping notifications.");
        return;
      }

      // Send notifications to each token
      for (String token in fcmTokens) {
        await sendNotificationToToken(token, title, body);
      }

      print('📲 ✅ Notifications sent to all users!');
    } catch (e) {
      print('❌ Error sending notifications: $e');
    }
  }
}
