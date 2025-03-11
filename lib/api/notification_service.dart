import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static const String _fcmUrl = 'https://fcm.googleapis.com/v1/projects/aims-5d185/messages:send';

  /// Loads the service account JSON file and returns the OAuth 2.0 access token
  static Future<String> getAccessToken() async {
    final serviceAccount = await rootBundle.loadString('assets/generated.json');
    final serviceAccountJson = json.decode(serviceAccount);

    final accountCredentials = ServiceAccountCredentials.fromJson(serviceAccountJson);

    // Generate an OAuth 2.0 access token
    final authClient = await clientViaServiceAccount(
      accountCredentials,
      ['https://www.googleapis.com/auth/firebase.messaging'],
    );

    return authClient.credentials.accessToken.data;
  }

  /// Sends a push notification using the FCM V1 API
  static Future<void> sendPushNotification({
    required String fcmToken,
    required String title,
    required String body,
    required String receiverName,
    required String receiverEmail,
  }) async {
    try {
      final accessToken = await getAccessToken();

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken, // Send to the receiver's FCM token
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'receiverFullName': receiverName, // Pass receiver's full name
              'receiverEmail': receiverEmail, // Pass receiver's email
            },
          },
        }),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print(
            'Failed to send notification. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}