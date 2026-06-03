import 'package:flutter/material.dart';

/// FlowOS Motion Design Tokens — Animation durations, curves, and rules.
///
/// Rules:
/// 1. Every button press has a `quick` scale-down (0.97)
/// 2. Cards entering view use `easeOut` + `standard` + fade
/// 3. Numbers use `AnimatedSwitcher` with `standard`
/// 4. Screen transitions use `smooth` + `emphasis`
/// 5. Focus Mode: only timer ring animates (calm mode)
/// 6. Reduce Motion: check MediaQuery.disableAnimations
abstract final class MotionTokens {
  // ─── Duration Tokens ───────────────────────────────────────────

  /// 150ms — Micro-interactions (haptic response, button press)
  static const quick = Duration(milliseconds: 150);

  /// 300ms — Card transitions, list reorder
  static const standard = Duration(milliseconds: 300);

  /// 500ms — Screen transitions, XP bar fill
  static const emphasis = Duration(milliseconds: 500);

  /// 800ms — Level-up, achievement unlock
  static const dramatic = Duration(milliseconds: 800);

  /// 1200ms — Confetti, Flow Score reveal
  static const celebration = Duration(milliseconds: 1200);

  // ─── Easing Curves ─────────────────────────────────────────────

  /// Elements appearing, entering view
  static const easeOut = Curves.easeOutCubic;

  /// Elements disappearing, leaving view
  static const easeIn = Curves.easeInCubic;

  /// Bouncy feedback (XP gain, badge unlock)
  static const spring = Curves.elasticOut;

  /// Steady transitions (screen changes)
  static const smooth = Curves.easeInOutCubic;

  // ─── Stagger Delays ────────────────────────────────────────────

  /// Each list item enters 50ms after previous
  static const staggerDelay = Duration(milliseconds: 50);

  // ─── Button Press Scale ────────────────────────────────────────

  /// Scale-down factor on button press
  static const pressScale = 0.97;

  /// Opacity on press
  static const pressOpacity = 0.85;

  // ─── Helpers ───────────────────────────────────────────────────

  /// Returns [Duration.zero] if animations are disabled, otherwise the given duration.
  static Duration resolve(BuildContext context, Duration duration) {
    return MediaQuery.of(context).disableAnimations ? Duration.zero : duration;
  }
}
