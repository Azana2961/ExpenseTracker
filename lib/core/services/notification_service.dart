import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_notification');
    
    // For iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse notificationResponse) async {
        // Handle notification tap
      },
    );
  }

  Future<void> requestPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'expense_tracker_test',
      'Test Notifications',
      channelDescription: 'Testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    // Pick a random message for the test
    final messages = [
      "Subah ho gayi, kharcha shuru? Log it before you forget it! ☕",
      "Lunch break! Khana kha liya, ab kharcha bhi record kar lo. 🍛",
      "Shaam ki chai aur snacks? Unka hisaab kaun likhega? ☕",
      "Raat ke 9 baj gaye! Aaj ka pura hisaab clear karo jaldi. ⏰",
    ];
    final randomMsg = messages[Random().nextInt(messages.length)];

    await flutterLocalNotificationsPlugin.show(
      id: 99,
      title: 'Kharcha Yar',
      body: randomMsg,
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> scheduleDailyNotifications() async {
    // Cancel any existing notifications so we don't spam
    await flutterLocalNotificationsPlugin.cancelAll();

    // Morning: Random time between 8:00 AM and 11:00 AM
    _scheduleRandomNotification(
      id: 1,
      startHour: 8,
      endHour: 11,
      messages: [
        "Subah ho gayi, kharcha shuru? Log it before you forget it! ☕",
        "Chai pi li? Ab thoda hisaab bhi likh lo boss. 📝",
        "Good morning! Paise toh udd gaye honge, entry kahan hai? 💸",
      ],
    );

    // Afternoon: Random time between 1:00 PM (13:00) and 4:00 PM (16:00)
    _scheduleRandomNotification(
      id: 2,
      startHour: 13,
      endHour: 16,
      messages: [
        "Lunch break! Khana kha liya, ab kharcha bhi record kar lo. 🍛",
        "Zindagi mein tension aur kharche dono log karne padte hain. Do it now! 😅",
        "Bhai, wallet check kar aur bata aaj kitna udaaya? 🍔",
      ],
    );

    // Evening: Random time between 5:00 PM (17:00) and 8:00 PM (20:00)
    _scheduleRandomNotification(
      id: 3,
      startHour: 17,
      endHour: 20,
      messages: [
        "Shaam ki chai aur snacks? Unka hisaab kaun likhega? ☕",
        "Din khatam hone wala hai, kharche ka meter abhi bhi chalu hai kya? 🚕",
        "Samosa khaya? Toh app mein entry bhi laga do fatafat! 🥟",
      ],
    );

    // Night Fixed: 9:00 PM (21:00)
    _scheduleFixedNotification(
      id: 4,
      hour: 21,
      minute: 0,
      messages: [
        "Raat ke 9 baj gaye! Aaj ka pura hisaab clear karo jaldi. ⏰",
        "Sone se pehle ek nek kaam, din bhar ka kharcha log karo! 🌙",
        "Wallet khali, app bhi khali? Aise kaise chalega, log your expenses now! 📉",
      ],
    );
  }

  void _scheduleRandomNotification({
    required int id,
    required int startHour,
    required int endHour,
    required List<String> messages,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final random = Random();
    
    // Pick random hour and minute
    int hour = startHour + random.nextInt(endHour - startHour);
    int minute = random.nextInt(60);

    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final message = messages[random.nextInt(messages.length)];

    _schedule(id: id, title: 'Kharcha Yar', body: message, scheduledDate: scheduledDate);
  }

  void _scheduleFixedNotification({
    required int id,
    required int hour,
    required int minute,
    required List<String> messages,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final random = Random();
    final message = messages[random.nextInt(messages.length)];

    _schedule(id: id, title: 'Reminder', body: message, scheduledDate: scheduledDate);
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'expense_tracker_daily',
      'Daily Reminders',
      channelDescription: 'Daily reminders to log your expenses',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }
}
