/// Recurring task rule — defines how a task repeats.
///
/// Uses simplified RRULE-like syntax for Drift storage:
/// - `daily` — every day
/// - `weekdays` — Mon–Fri
/// - `weekly:1,3,5` — specific days of week (1=Mon)
/// - `monthly:15` — specific day of month
/// - `custom:3` — every N days
class RecurrenceRule {
  final RecurrenceType type;
  final List<int>? daysOfWeek; // 1=Mon, 7=Sun
  final int? dayOfMonth;
  final int? intervalDays;

  const RecurrenceRule({
    required this.type,
    this.daysOfWeek,
    this.dayOfMonth,
    this.intervalDays,
  });

  /// Parse from stored string
  factory RecurrenceRule.fromString(String s) {
    final parts = s.split(':');
    switch (parts[0]) {
      case 'daily':
        return const RecurrenceRule(type: RecurrenceType.daily);
      case 'weekdays':
        return const RecurrenceRule(
          type: RecurrenceType.weekly,
          daysOfWeek: [1, 2, 3, 4, 5],
        );
      case 'weekly':
        return RecurrenceRule(
          type: RecurrenceType.weekly,
          daysOfWeek: parts[1].split(',').map(int.parse).toList(),
        );
      case 'monthly':
        return RecurrenceRule(
          type: RecurrenceType.monthly,
          dayOfMonth: int.parse(parts[1]),
        );
      case 'custom':
        return RecurrenceRule(
          type: RecurrenceType.custom,
          intervalDays: int.parse(parts[1]),
        );
      default:
        return const RecurrenceRule(type: RecurrenceType.daily);
    }
  }

  /// Serialize to storable string
  String toStorageString() {
    switch (type) {
      case RecurrenceType.daily:
        return 'daily';
      case RecurrenceType.weekly:
        if (daysOfWeek != null &&
            daysOfWeek!.length == 5 &&
            daysOfWeek!.every((d) => d >= 1 && d <= 5)) {
          return 'weekdays';
        }
        return 'weekly:${daysOfWeek?.join(',') ?? '1'}';
      case RecurrenceType.monthly:
        return 'monthly:${dayOfMonth ?? 1}';
      case RecurrenceType.custom:
        return 'custom:${intervalDays ?? 1}';
    }
  }

  /// Get next occurrence date from a given date
  DateTime nextOccurrence(DateTime from) {
    switch (type) {
      case RecurrenceType.daily:
        return from.add(const Duration(days: 1));
      case RecurrenceType.weekly:
        if (daysOfWeek == null || daysOfWeek!.isEmpty) {
          return from.add(const Duration(days: 7));
        }
        // Find next matching weekday
        var next = from.add(const Duration(days: 1));
        while (!daysOfWeek!.contains(next.weekday)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case RecurrenceType.monthly:
        final target = dayOfMonth ?? from.day;
        var next = DateTime(from.year, from.month + 1, target);
        // Handle months with fewer days
        while (next.day != target) {
          next = DateTime(next.year, next.month, target - 1);
        }
        return next;
      case RecurrenceType.custom:
        return from.add(Duration(days: intervalDays ?? 1));
    }
  }

  /// Human-readable label
  String get label {
    switch (type) {
      case RecurrenceType.daily:
        return 'Every day';
      case RecurrenceType.weekly:
        if (daysOfWeek != null &&
            daysOfWeek!.length == 5 &&
            daysOfWeek!.every((d) => d >= 1 && d <= 5)) {
          return 'Weekdays';
        }
        final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return daysOfWeek?.map((d) => dayNames[d]).join(', ') ?? 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly on day $dayOfMonth';
      case RecurrenceType.custom:
        return 'Every $intervalDays days';
    }
  }
}

enum RecurrenceType { daily, weekly, monthly, custom }
