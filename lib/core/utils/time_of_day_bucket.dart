import '../../../data/local/tables/energy_checkins_table.dart';

/// Helper to derive the current time-of-day bucket for energy check-ins.
/// - Morning: before 12 PM
/// - Afternoon: 12 PM to 5 PM (17:00)
/// - Evening: after 5 PM
TimeOfDayColumn bucketFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return TimeOfDayColumn.morning;
  if (h < 17) return TimeOfDayColumn.afternoon;
  return TimeOfDayColumn.evening;
}
