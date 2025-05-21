import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notifications.initialize(initSettings);
  }

  // Test notification method
  Future<void> showTestNotification() async {
    final androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Bildirimleri',
      channelDescription: 'Test bildirimleri için kanal',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails();
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      999, // Unique ID for test notification
      'Test Bildirimi',
      'Bildirim sistemi çalışıyor!',
      notificationDetails,
    );
  }

  Future<void> schedulePrayerNotification({
    required String prayerName,
    required DateTime prayerTime,
  }) async {
    // Schedule notification 15 minutes before prayer time
    final notificationTime = prayerTime.subtract(const Duration(minutes: 15));
    
    final androidDetails = AndroidNotificationDetails(
      'prayer_times_channel',
      'Namaz Vakitleri',
      channelDescription: 'Namaz vakitleri bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails();
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      0,
      'Namaz Vakti',
      '$prayerName vakti için 15 dakika var',
      tz.TZDateTime.from(notificationTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
} 