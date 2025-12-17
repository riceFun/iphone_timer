import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showTimerNotification({
    required String timeRemaining,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'timer_channel',
      'Timer',
      channelDescription: 'Timer notifications',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      playSound: false,
      enableVibration: false,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      '倒计时进行中',
      timeRemaining,
      notificationDetails,
    );
  }

  static Future<void> showTimerCompleteNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'timer_complete_channel',
      'Timer Complete',
      channelDescription: 'Timer completion notifications',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await _notifications.show(
      1,
      '倒计时结束',
      '时间到!',
      notificationDetails,
    );
  }

  static Future<void> cancelTimerNotification() async {
    await _notifications.cancel(0);
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}
