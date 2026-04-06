import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Future<void> requestPermission() async{
    //     NotificationSettings settings = await messaging.requestPermission(
    //     alert: true,
    //     badge: true,
    //     sound: true,
    //     );

//Ask for permission to send notifications
    Future<void> initFCM() async{
        await messaging.requestPermission();

        final fcmToken = await messaging.getToken();
        print('FCM Token: $fcmToken');

        //when app is opened but not in the foreground
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            print('Message: ${message.notification?.title}');
        });

        //send notif in app when app is active
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
            print('Message: ${message.notification?.title}');
        });
    }
}
