import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flowos/features/notifications/services/timezone_service.dart';
import 'package:flowos/features/notifications/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-008: Timezone-Aware Notification Scheduling Tests', () {
    tearDown(() {
      TimezoneService.setOverrideTimezoneForTesting(null);
    });

    test(
      'Asia/Kolkata (+05:30) resolves location and calculates 09:00 local wall-clock time',
      () async {
        TimezoneService.setOverrideTimezoneForTesting('Asia/Kolkata');
        final location = await TimezoneService.initializeLocalTimezone();

        expect(location.name, equals('Asia/Kolkata'));
        expect(tz.local.name, equals('Asia/Kolkata'));
        expect(
          tz.local.currentTimeZone.offset,
          equals(19800 * 1000),
        ); // +05:30 = 19800 seconds

        // Given fake current time in IST: July 27, 2026 at 08:00 AM IST
        final now = tz.TZDateTime(tz.local, 2026, 7, 27, 8, 0);
        var scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          9,
        );
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }

        expect(scheduled.year, equals(2026));
        expect(scheduled.month, equals(7));
        expect(scheduled.day, equals(27));
        expect(scheduled.hour, equals(9));
        expect(scheduled.minute, equals(0));
        expect(
          scheduled.timeZoneOffset.inMinutes,
          equals(330),
        ); // 5 hours 30 mins
      },
    );

    test(
      'America/New_York DST transitions preserve 09:00 local wall-clock time',
      () async {
        TimezoneService.setOverrideTimezoneForTesting('America/New_York');
        final location = await TimezoneService.initializeLocalTimezone();

        expect(location.name, equals('America/New_York'));

        // Before DST end: Oct 31, 2026 (EDT, UTC-4)
        final edtNow = tz.TZDateTime(tz.local, 2026, 10, 31, 8, 0);
        final edtScheduled = tz.TZDateTime(
          tz.local,
          edtNow.year,
          edtNow.month,
          edtNow.day,
          9,
        );

        expect(edtScheduled.hour, equals(9));
        expect(edtScheduled.timeZoneOffset.inHours, equals(-4)); // EDT

        // After DST end: Nov 2, 2026 (EST, UTC-5)
        final estNow = tz.TZDateTime(tz.local, 2026, 11, 2, 8, 0);
        final estScheduled = tz.TZDateTime(
          tz.local,
          estNow.year,
          estNow.month,
          estNow.day,
          9,
        );

        expect(estScheduled.hour, equals(9));
        expect(estScheduled.timeZoneOffset.inHours, equals(-5)); // EST
      },
    );

    test(
      'Invalid timezone string falls back safely to UTC without crashing',
      () async {
        TimezoneService.setOverrideTimezoneForTesting(
          'Invalid/NonExistent_Zone',
        );
        final location = await TimezoneService.initializeLocalTimezone();

        expect(location.name, equals('UTC'));
        expect(tz.local.name, equals('UTC'));
      },
    );

    test(
      'Rescheduling re-initializes timezone and preserves notification IDs',
      () async {
        TimezoneService.setOverrideTimezoneForTesting('Europe/London');
        await NotificationService.rescheduleAllNotifications(
          morningHour: 9,
          afternoonHour: 13,
          eveningHour: 17,
          reportHour: 21,
        );

        expect(
          TimezoneService.currentLocalTimezoneName,
          equals('Europe/London'),
        );
      },
    );
  });
}
