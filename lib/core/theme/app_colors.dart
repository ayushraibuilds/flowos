import 'dart:ui';

import 'package:flutter/material.dart';

/// FlowOS Color Palette — Dark-first, calm aesthetic.
/// "Think Spotify meets a luxury watch."
abstract final class AppColors {
  // ─── Background Layers ─────────────────────────────────────────
  /// Near-black with blue undertone — deepest background
  static const background0 = Color(0xFF0A0E14);

  /// Dark slate — main content areas
  static const background1 = Color(0xFF121820);

  /// Elevated cards, bottom sheets
  static const background2 = Color(0xFF1A2230);

  /// Modals, tooltips, hover states
  static const background3 = Color(0xFF222E3E);

  // ─── Glass Surfaces ───────────────────────────────────────────
  /// Standard glassmorphism card
  static Color glassSurface = const Color(0xFF1A2230).withValues(alpha: 0.72);
  static const glassBlur = 18.0;
  static Color glassBorder = Colors.white.withValues(alpha: 0.06);

  /// Elevated glassmorphism (modals, focus timer)
  static Color glassElevated = const Color(0xFF222E3E).withValues(alpha: 0.80);
  static const glassElevatedBlur = 24.0;
  static Color glassElevatedBorder = Colors.white.withValues(alpha: 0.10);

  /// Floating glass (XP reveal, level-up overlay)
  static Color glassFloating = const Color(0xFF222E3E).withValues(alpha: 0.85);
  static const glassFloatingBlur = 30.0;
  static Color glassFloatingBorder = Colors.white.withValues(alpha: 0.14);

  // ─── Accent Colors ─────────────────────────────────────────────
  /// Primary — XP gains, positive actions, CTAs, streak indicators
  static const emerald = Color(0xFF00D68F);

  /// Secondary — less emphasis
  static const emeraldMuted = Color(0xFF00B878);

  /// Ambient glow behind emerald elements
  static Color emeraldGlow = const Color(0xFF00D68F).withValues(alpha: 0.15);

  /// Active focus sessions, timer ring, "in flow" state
  static const focusBlue = Color(0xFF4A9EFF);

  /// Ambient glow during focus mode
  static Color focusBlueGlow = const Color(0xFF4A9EFF).withValues(alpha: 0.12);

  /// Attention costs, scroll time, approaching budget
  static const warningAmber = Color(0xFFFFB74D);

  /// Scroll over budget, low wellbeing, F grade
  static const dangerCoral = Color(0xFFFF6B6B);

  /// Recovery actions, wellbeing score, bounce-back
  static const recoveryTeal = Color(0xFF26C6DA);

  // ─── Text Colors ───────────────────────────────────────────────
  /// Main text, titles (not pure white — reduces eye strain)
  static const textPrimary = Color(0xFFE8ECF1);

  /// Subtitles, labels, timestamps
  static const textSecondary = Color(0xFF7A8BA5);

  /// Placeholder text, disabled states
  static const textTertiary = Color(0xFF4A5568);

  /// Text on light/colored backgrounds
  static const textInverse = Color(0xFF0A0E14);

  // ─── Energy Level Colors ───────────────────────────────────────
  /// 🔥 Deep Work — high-energy tasks, intense focus
  static const energyDeep = Color(0xFFFF6B6B);

  /// ⚡ Medium — moderate tasks
  static const energyMedium = Color(0xFFFFB74D);

  /// 🌿 Light — low-energy tasks, admin work
  static const energyLight = Color(0xFF00D68F);

  // ─── Grade Colors (Flow Score) ─────────────────────────────────
  static const gradeA = Color(0xFF00D68F);
  static const gradeB = Color(0xFF4A9EFF);
  static const gradeC = Color(0xFFFFB74D);
  static const gradeD = Color(0xFFFF8A65);
  static const gradeF = Color(0xFFFF6B6B);

  /// Returns the color for a given Flow Score grade letter.
  static Color gradeColor(String grade) => switch (grade.toUpperCase()) {
    'A+' || 'A' => gradeA,
    'B' => gradeB,
    'C' => gradeC,
    'D' => gradeD,
    _ => gradeF,
  };

  /// Returns the color for a given energy level.
  static Color energyColor(EnergyLevel level) => switch (level) {
    EnergyLevel.deep => energyDeep,
    EnergyLevel.medium => energyMedium,
    EnergyLevel.light => energyLight,
  };

  // ─── Light Mode (Secondary) ────────────────────────────────────
  static const lightBackground = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE2E8F0);
  static const lightTextPrimary = Color(0xFF1A202C);

  // ─── Unlockable Theme Bases ────────────────────────────────────
  static const themeSpace = Color(0xFF0B0D1A);
  static const themeSpaceAccent = Color(0xFF7C6AFF);

  static const themeForest = Color(0xFF0A1408);
  static const themeForestAccent = Color(0xFF4CAF50);

  static const themeMidnight = Color(0xFF08080F);
  static const themeMidnightAccent = Color(0xFF64B5F6);

  static const themeSunrise = Color(0xFF140A0A);
  static const themeSunriseAccent = Color(0xFFFF8A65);
}

/// Energy levels for tasks — used throughout the app.
enum EnergyLevel {
  deep,   // 🔥 Deep Work
  medium, // ⚡ Medium
  light,  // 🌿 Light
}
