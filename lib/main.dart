import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/splash_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showTestNotification() async {
  const DarwinNotificationDetails iosDetails =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  const NotificationDetails notificationDetails =
      NotificationDetails(
    iOS: iosDetails,
  );

  await flutterLocalNotificationsPlugin.show(
    0,
    '🚨 Guidelight Alert',
    'Dangerous object detected nearby!',
    notificationDetails,
  );
}



void main() async {
  WidgetsFlutterBinding.ensureInitialized();


print('1️⃣ Flutter started');

  await Firebase.initializeApp();

  print('2️⃣ Firebase initialized');

  runApp(const GuidelightApp());


final messaging = FirebaseMessaging.instance;

await messaging.requestPermission(
  alert: true,
  badge: true,
  sound: true,
);

// Wait for APNs token
String? apnsToken;

for (int i = 0; i < 10; i++) {
  apnsToken = await messaging.getAPNSToken();

  if (apnsToken != null) {
    break;
  }

  await Future.delayed(const Duration(seconds: 1));
}

print('🍎 APNs Token: $apnsToken');

if (apnsToken != null) {
  final fcmToken = await messaging.getToken();
  print('🔥 FCM TOKEN: $fcmToken');
}

  // تهيئة Local Notifications
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // طلب الإذن على iOS
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  runApp(const GuidelightApp());
}

class GuidelightApp extends StatelessWidget {
  const GuidelightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Guidelight',
      home: const SplashScreen(),
    );
  }
}