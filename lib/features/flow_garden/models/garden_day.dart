import '../../../data/local/tables/focus_sessions_table.dart';

enum GardenObjectKind { tree, flower, water, light, wildlife }

/// A visible object in a daily Flow Garden plot. It is derived from real
/// activity, so the garden never creates another progression currency.
class GardenObject {
  final String id;
  final GardenObjectKind kind;
  final String emoji;
  final String seedEmoji;
  final String title;
  final String? detail;
  final double x;
  final double y;

  const GardenObject({
    required this.id,
    required this.kind,
    required this.emoji,
    required this.seedEmoji,
    required this.title,
    required this.x,
    required this.y,
    this.detail,
  });

  static GardenObject fromFocusSession({
    required String sessionId,
    required SessionTypeColumn sessionType,
    required int actualMinutes,
    String? taskTitle,
  }) {
    final seed = _stableSeed(sessionId);
    final isTree =
        sessionType == SessionTypeColumn.deepWork || actualMinutes >= 50;
    final variants = isTree ? ['🌲', '🌳', '🌴'] : ['🌸', '🌻', '🌷', '🌼'];
    final emoji = variants[seed % variants.length];
    final x = 0.14 + ((seed % 68) / 100);
    final y = 0.46 + (((seed ~/ 11) % 30) / 100);

    return GardenObject(
      id: 'focus-$sessionId',
      kind: isTree ? GardenObjectKind.tree : GardenObjectKind.flower,
      emoji: emoji,
      seedEmoji: isTree ? '🌰' : '🌱',
      title: isTree ? 'Deep-root tree' : 'Focus flower',
      detail: taskTitle?.trim().isEmpty ?? true ? null : taskTitle,
      x: x,
      y: y,
    );
  }

  static int _stableSeed(String value) {
    return value.codeUnits.fold<int>(
      0,
      (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
    );
  }
}

class GardenDay {
  final DateTime date;
  final List<GardenObject> objects;
  final int focusMinutes;
  final int recoveryCount;
  final int scrollMinutes;
  final int scrollBudgetMinutes;
  final bool isCompleted;
  final bool isProtected;

  const GardenDay({
    required this.date,
    required this.objects,
    required this.focusMinutes,
    required this.recoveryCount,
    required this.scrollMinutes,
    required this.scrollBudgetMinutes,
    required this.isCompleted,
    required this.isProtected,
  });

  bool get isResting => objects.isEmpty;

  String get headline {
    if (isResting) {
      return 'Resting soil';
    }
    if (isProtected) {
      return 'A protected landscape';
    }
    if (focusMinutes >= 90) {
      return 'Deep roots are growing';
    }
    if (focusMinutes > 0) {
      return 'Your plot is taking shape';
    }
    return 'Care is tending the soil';
  }

  String get supportingText {
    if (isResting) {
      return 'Nothing is lost on quiet days. Your garden is resting.';
    }
    if (isProtected) {
      return 'You protected your attention; wildlife has arrived.';
    }
    if (recoveryCount > 0) {
      return 'Recovery counts as care here.';
    }
    return 'Every focus block leaves something living behind.';
  }
}

class GardenSeason {
  final String name;
  final String emoji;
  final String description;

  const GardenSeason(this.name, this.emoji, this.description);

  factory GardenSeason.forDate(DateTime date) {
    return switch (date.month) {
      12 || 1 || 2 => const GardenSeason(
        'Winter rest',
        '❄️',
        'A season for roots, rest, and gentle return.',
      ),
      3 || 4 || 5 => const GardenSeason(
        'Spring growth',
        '🌱',
        'Small acts are becoming visible life.',
      ),
      6 || 7 || 8 => const GardenSeason(
        'Summer canopy',
        '☀️',
        'Your focus is making shade for what matters.',
      ),
      _ => const GardenSeason(
        'Autumn glow',
        '🍂',
        'A season for harvest, reflection, and renewal.',
      ),
    };
  }
}
