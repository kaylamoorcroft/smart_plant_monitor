import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  //Ask for permission to send notifications
  Future<void> initFCM() async {
    // Notifications don't work on web, exit so app doesn't crash
    if (kIsWeb) {
      print("Push notifications not available for web version of app");
      return;
    }

    await messaging.requestPermission();

    // Also doesn't work on mac / ios. Prevent crash here too
    if (Platform.isMacOS || Platform.isIOS) {
      // Free developer accounts will always get 'null' here
      String? apnsToken = await messaging.getAPNSToken();

      if (apnsToken == null) {
        print(
          'Running with a free Developer account: Push notifications are disabled.',
        );
        return; // Exit to prevent the getToken() crash
      }
    }

    final fcmToken = await messaging.getToken();
    print('FCM Token: $fcmToken');

    await messaging.subscribeToTopic('plant_alerts');
  }
}
