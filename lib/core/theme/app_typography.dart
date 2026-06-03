import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FlowOS Typography System
/// Primary: Inter (via Google Fonts) — all body text, labels, buttons
/// Monospace: JetBrains Mono (bundled) — timer digits, XP numbers, stats
abstract final class AppTypography {
  // ─── Base Text Styles ──────────────────────────────────────────

  /// Display — Flow Score grade, level-up number (48px, 800 weight)
  static TextStyle get display => GoogleFonts.inter(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -1.0,
  );

  /// H1 — Screen titles ("Morning Intention") (28px, 700 weight)
  static TextStyle get h1 => GoogleFonts.inter(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// H2 — Section headers ("Today's MITs") (22px, 600 weight)
  static TextStyle get h2 => GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  /// H3 — Card titles, task names (18px, 600 weight)
  static TextStyle get h3 => GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  /// Body — Body text, descriptions, AI report content (15px, 400 weight)
  static TextStyle get body => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Body Small — Secondary labels, timestamps (13px, 400 weight)
  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Caption — Badges, tags, micro-labels (11px, 500 weight)
  static TextStyle get caption => GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.3,
  );

  /// Button text (15px, 600 weight)
  static TextStyle get button => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.0,
  );

  // ─── Monospace Styles (JetBrains Mono — bundled) ───────────────

  /// Mono — Timer digits (32px, 700 weight)
  static const mono = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 1.0,
  );

  /// Mono Large — Focus timer countdown (48px, 700 weight)
  static const monoLarge = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 48,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: 1.5,
  );

  /// Mono Small — XP count, streak number, stats (16px, 500 weight)
  static const monoSmall = TextStyle(
    fontFamily: 'JetBrainsMono',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );
}
