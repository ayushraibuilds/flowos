import 'ai_service.dart';

class LocalBrainDumpParser {
  static List<BrainDumpTask> parse({
    required String rawText,
    required int currentEnergy,
  }) {
    if (rawText.trim().isEmpty) return [];

    // Split on newlines, semicolons, bullets (•, -, *), and numbered lists (e.g. 1.)
    final rawLines = rawText.split(RegExp(r'[\n;•\-\*]'));
    final List<String> lines = [];

    for (var line in rawLines) {
      var trimmed = line.trim();
      // Remove leading numbered list indicator like "1. ", "2) "
      trimmed = trimmed.replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '').trim();
      if (trimmed.isNotEmpty) {
        lines.add(trimmed);
      }
    }

    // Drop empty, limit to max 10 items
    final items = lines.take(10).toList();

    final List<BrainDumpTask> tasks = [];

    for (int i = 0; i < items.length; i++) {
      final titleRaw = items[i];
      // Title ≤ 60 chars
      final title = titleRaw.length > 60 ? '${titleRaw.substring(0, 57)}...' : titleRaw;

      // Energy heuristic: "write, code, research" → deep; "email, call, schedule" → light; else medium
      final lowerTitle = title.toLowerCase();
      String energyLevel = 'medium';
      if (lowerTitle.contains('write') ||
          lowerTitle.contains('code') ||
          lowerTitle.contains('research') ||
          lowerTitle.contains('build') ||
          lowerTitle.contains('design') ||
          lowerTitle.contains('program')) {
        energyLevel = 'deep';
      } else if (lowerTitle.contains('email') ||
          lowerTitle.contains('call') ||
          lowerTitle.contains('schedule') ||
          lowerTitle.contains('buy') ||
          lowerTitle.contains('clean') ||
          lowerTitle.contains('reply') ||
          lowerTitle.contains('send')) {
        energyLevel = 'light';
      }

      // Friction: longer titles / "maybe" / "should" / "need to" → higher (0.2–0.8)
      double frictionScore = 0.4;
      if (lowerTitle.contains('maybe') ||
          lowerTitle.contains('should') ||
          lowerTitle.contains('need to') ||
          lowerTitle.contains('figure out') ||
          lowerTitle.contains('decide')) {
        frictionScore += 0.2;
      }
      if (title.length > 40) {
        frictionScore += 0.2;
      }
      frictionScore = frictionScore.clamp(0.2, 0.8);

      // Minutes: default 25; parse \d+m if present; clamp 5–480
      int estimatedMinutes = 25;
      final match = RegExp(r'(\d+)\s*m\b').firstMatch(lowerTitle);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '');
        if (val != null) {
          estimatedMinutes = val.clamp(5, 480);
        }
      }

      tasks.add(BrainDumpTask(
        title: title,
        energyLevel: energyLevel,
        estimatedMinutes: estimatedMinutes,
        frictionScore: frictionScore,
        suggestedOrder: 0,
        reasoning: 'Heuristic-based offline fallback sorting.',
      ));
    }

    // Sort by current energy:
    // Energy >= 4 (high) → deep first, then medium, then light
    // Energy == 3 (steady) → medium first, then deep or light
    // Energy <= 2 (low) → light first, then medium, then deep
    tasks.sort((a, b) {
      int getPriority(String energy) {
        if (currentEnergy >= 4) {
          return switch (energy) {
            'deep' => 0,
            'medium' => 1,
            'light' => 2,
            _ => 1,
          };
        } else if (currentEnergy == 3) {
          return switch (energy) {
            'medium' => 0,
            'deep' => 1,
            'light' => 2,
            _ => 1,
          };
        } else {
          return switch (energy) {
            'light' => 0,
            'medium' => 1,
            'deep' => 2,
            _ => 1,
          };
        }
      }

      // If priorities are equal, sort by friction: higher friction last
      final aPriority = getPriority(a.energyLevel);
      final bPriority = getPriority(b.energyLevel);
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      return a.frictionScore.compareTo(b.frictionScore);
    });

    // Map suggestedOrder to index
    final List<BrainDumpTask> sortedTasks = [];
    for (int i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      sortedTasks.add(BrainDumpTask(
        title: t.title,
        energyLevel: t.energyLevel,
        estimatedMinutes: t.estimatedMinutes,
        frictionScore: t.frictionScore,
        suggestedOrder: i + 1,
        reasoning: t.reasoning,
      ));
    }

    return sortedTasks;
  }
}
