import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> showTestNotification({required String title, required String body}) async {
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

    await _notifications.show(
      0,
      'Guidelight Alert',
      'Dangerous object detected nearby!',
      notificationDetails,
    );
  }
}