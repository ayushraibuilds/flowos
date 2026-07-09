import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import '../../../../presentation/navigation/app_router.dart';

/// FlowOS Notification Service — smart, platform-aware notifications.
///
/// Android: 4 notification channels (Focus, Check-in, Report, Streak)
/// iOS: notification categories with actions
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ─── Channel IDs (Android) ────────────────────────────────

  static const _focusChannel = AndroidNotificationChannel(
    'flowos_focus',
    'Focus Sessions',
    description: 'Active focus timer and session notifications',
    importance: Importance.high,
  );

  static const _checkinChannel = AndroidNotificationChannel(
    'flowos_checkin',
    'Energy Check-ins',
    description: 'Reminders to log your energy level',
    importance: Importance.defaultImportance,
  );

  static const _reportChannel = AndroidNotificationChannel(
    'flowos_report',
    'Daily Reports',
    description: 'End-of-day report and weekly review reminders',
    importance: Importance.defaultImportance,
  );

  static const _streakChannel = AndroidNotificationChannel(
    'flowos_streak',
    'Streak Alerts',
    description: 'Streak warnings and celebration',
    importance: Importance.high,
  );

  // ─── Initialization ────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          appRouter.push(payload);
        }
      },
    );

    // Create Android notification channels
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
          _toAndroidChannel(_focusChannel));
      await androidPlugin?.createNotificationChannel(
          _toAndroidChannel(_checkinChannel));
      await androidPlugin?.createNotificationChannel(
          _toAndroidChannel(_reportChannel));
      await androidPlugin?.createNotificationChannel(
          _toAndroidChannel(_streakChannel));
    }

    _initialized = true;
  }

  // ─── Focus Timer Foreground (Android) ──────────────────────

  /// Show persistent notification for active focus timer.
  /// Android only — keeps the timer alive when app is backgrounded.
  static Future<void> showFocusTimer({
    required int remainingMinutes,
    required String sessionType,
  }) async {
    if (!Platform.isAndroid) return;

    final emoji = sessionType == 'deepWork' ? '🧠' : '⏱️';
    await _plugin.show(
      1, // Fixed ID for focus timer
      '$emoji Focus Session Active',
      '${remainingMinutes}m remaining',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _focusChannel.id,
          _focusChannel.name,
          channelDescription: _focusChannel.description,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true, // Can't be swiped away
          autoCancel: false,
          showWhen: false,
          category: AndroidNotificationCategory.service,
        ),
      ),
    );
  }

  /// Cancel focus timer notification
  static Future<void> cancelFocusTimer() async {
    await _plugin.cancel(1);
  }

  // ─── Energy Check-in Reminders ─────────────────────────────

  /// Schedule 3 daily energy check-in reminders
  static Future<void> scheduleEnergyCheckIns({
    int morningHour = 9,
    int afternoonHour = 13,
    int eveningHour = 17,
  }) async {
    final hours = [morningHour, afternoonHour, eveningHour];
    final labels = ['Morning', 'Afternoon', 'Evening'];

    for (int i = 0; i < hours.length; i++) {
      await _scheduleDaily(
        id: 100 + i,
        hour: hours[i],
        title: '⚡ ${labels[i]} Check-in',
        body: 'How\'s your energy right now? (1-5)',
        channelId: _checkinChannel.id,
        channelName: _checkinChannel.name,
        payload: '/energy-checkin',
      );
    }
  }

  // ─── Report Reminder ───────────────────────────────────────

  /// Schedule daily report reminder at 9 PM
  static Future<void> scheduleReportReminder({int hour = 21}) async {
    await _scheduleDaily(
      id: 200,
      hour: hour,
      title: '📊 Daily Report Ready',
      body: 'Your day in review. Tap to see your score.',
      channelId: _reportChannel.id,
      channelName: _reportChannel.name,
      payload: '/daily-report',
    );
  }

  /// Schedule weekly review reminder (Sunday 8 PM)
  static Future<void> scheduleWeeklyReview() async {
    await _scheduleWeekly(
      id: 201,
      weekday: DateTime.sunday,
      hour: 20,
      title: '📋 Weekly Review',
      body: '5 minutes to reflect on your week.',
      channelId: _reportChannel.id,
      channelName: _reportChannel.name,
      payload: '/weekly-review',
    );
  }

  // ─── Streak Alerts ─────────────────────────────────────────

  /// Show streak warning at 8 PM if no activity today
  static Future<void> scheduleStreakWarning() async {
    await _scheduleDaily(
      id: 300,
      hour: 20,
      title: '🔥 Streak at Risk!',
      body: 'Do one focus session to keep your streak alive.',
      channelId: _streakChannel.id,
      channelName: _streakChannel.name,
    );
  }

  /// Show streak celebration
  static Future<void> showStreakCelebration(int days) async {
    await _plugin.show(
      301,
      '🔥 $days-Day Streak!',
      'Consistency is your superpower. Keep going!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _streakChannel.id,
          _streakChannel.name,
          channelDescription: _streakChannel.description,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  static Future<void> _scheduleDaily({
    required int id,
    required int hour,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(channelId, channelName),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> _scheduleWeekly({
    required int id,
    required int weekday,
    required int hour,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);

    // Find next occurrence of the target weekday
    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(channelId, channelName),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> cancelEnergyCheckIns() async {
    await _plugin.cancel(100);
    await _plugin.cancel(101);
    await _plugin.cancel(102);
  }

  static Future<void> cancelReportReminder() async {
    await _plugin.cancel(200);
  }

  static Future<void> cancelWeeklyReview() async {
    await _plugin.cancel(201);
  }

  static Future<void> cancelStreakWarning() async {
    await _plugin.cancel(300);
  }

  /// Convert our const channel to the mutable type the plugin expects
  static AndroidNotificationChannel _toAndroidChannel(
      AndroidNotificationChannel c) => c;
}
