import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FlowOS Unlockable Theme System.
///
/// Themes unlock at specific levels:
/// - Default Dark: Level 1 (always available)
/// - Space (purple/violet): Level 10
/// - Forest (green/natural): Level 20
/// - Midnight (icy blue): Level 35
/// - Sunrise (warm coral): Level 50
///
/// Themes change background layers and accent color while keeping
/// the rest of the design system intact.
class FlowTheme {
  final String id;
  final String name;
  final String emoji;
  final int unlockLevel;
  final Color background0;
  final Color background1;
  final Color background2;
  final Color background3;
  final Color accent;
  final Color accentMuted;
  final Color accentGlow;

  const FlowTheme({
    required this.id,
    required this.name,
    required this.emoji,
    required this.unlockLevel,
    required this.background0,
    required this.background1,
    required this.background2,
    required this.background3,
    required this.accent,
    required this.accentMuted,
    required this.accentGlow,
  });

  /// Is this theme unlocked at the given level?
  bool isUnlocked(int currentLevel) => currentLevel >= unlockLevel;
}

/// All available themes
class FlowThemes {
  FlowThemes._();

  static const defaultDark = FlowTheme(
    id: 'default',
    name: 'Default Dark',
    emoji: '🌑',
    unlockLevel: 1,
    background0: Color(0xFF0A0E14),
    background1: Color(0xFF121820),
    background2: Color(0xFF1A2230),
    background3: Color(0xFF222E3E),
    accent: Color(0xFF00D68F), // AppColors.emerald
    accentMuted: Color(0xFF00B878), // AppColors.emeraldMuted
    accentGlow: Color(0x2600D68F),
  );

  static const space = FlowTheme(
    id: 'space',
    name: 'Deep Space',
    emoji: '🪐',
    unlockLevel: 10,
    background0: Color(0xFF0B0D1A),
    background1: Color(0xFF111428),
    background2: Color(0xFF1A1E38),
    background3: Color(0xFF242A4A),
    accent: Color(0xFF7C6AFF),
    accentMuted: Color(0xFF6050E0),
    accentGlow: Color(0x267C6AFF),
  );

  static const forest = FlowTheme(
    id: 'forest',
    name: 'Dark Forest',
    emoji: '🌲',
    unlockLevel: 20,
    background0: Color(0xFF0A1408),
    background1: Color(0xFF101E0E),
    background2: Color(0xFF1A2E18),
    background3: Color(0xFF243E22),
    accent: Color(0xFF4CAF50),
    accentMuted: Color(0xFF388E3C),
    accentGlow: Color(0x264CAF50),
  );

  static const midnight = FlowTheme(
    id: 'midnight',
    name: 'Midnight Ice',
    emoji: '❄️',
    unlockLevel: 35,
    background0: Color(0xFF08080F),
    background1: Color(0xFF0E0E1A),
    background2: Color(0xFF16162A),
    background3: Color(0xFF1E1E3A),
    accent: Color(0xFF64B5F6),
    accentMuted: Color(0xFF42A5F5),
    accentGlow: Color(0x2664B5F6),
  );

  static const sunrise = FlowTheme(
    id: 'sunrise',
    name: 'Warm Sunrise',
    emoji: '🌅',
    unlockLevel: 50,
    background0: Color(0xFF140A0A),
    background1: Color(0xFF1E100E),
    background2: Color(0xFF2E1A18),
    background3: Color(0xFF3E2422),
    accent: Color(0xFFFF8A65),
    accentMuted: Color(0xFFFF7043),
    accentGlow: Color(0x26FF8A65),
  );

  static const all = [defaultDark, space, forest, midnight, sunrise];

  static FlowTheme byId(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => defaultDark);
  }
}

// ─── Theme State ────────────────────────────────────────────────

final themeProvider = StateNotifierProvider<ThemeNotifier, FlowTheme>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<FlowTheme> {
  ThemeNotifier() : super(FlowThemes.defaultDark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString('selected_theme') ?? 'default';
    state = FlowThemes.byId(themeId);
  }

  Future<void> setTheme(FlowTheme theme) async {
    state = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme.id);
  }

  /// Get list of themes with unlock status
  List<({FlowTheme theme, bool unlocked})> getThemesForLevel(int level) {
    return FlowThemes.all
        .map((t) => (theme: t, unlocked: t.isUnlocked(level)))
        .toList();
  }
}
