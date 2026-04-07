import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

class NotificationService {
  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  //Ask for permission to send notifications
  Future<void> initFCM() async {
    await messaging.requestPermission();

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
