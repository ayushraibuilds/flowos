import 'effective_policy.dart';

/// A consent-based ladder for protecting a focus session.
///
/// These levels only control FlowOS behavior. They never claim to block other
/// apps or punish a person for leaving a session.
enum FocusProtectionLevel { softReturn, pauseAndProtect, intentionalExit }

extension FocusProtectionLevelDetails on FocusProtectionLevel {
  String get label => switch (this) {
    FocusProtectionLevel.softReturn => 'Soft Return',
    FocusProtectionLevel.pauseAndProtect => 'Pause & Protect',
    FocusProtectionLevel.intentionalExit => 'Intentional Exit',
  };

  String get shortLabel => switch (this) {
    FocusProtectionLevel.softReturn => 'Gentle',
    FocusProtectionLevel.pauseAndProtect => 'Guardrail',
    FocusProtectionLevel.intentionalExit => 'Shield',
  };

  String get description => switch (this) {
    FocusProtectionLevel.softReturn =>
      'A kind cue welcomes you back; your timer keeps moving. No app blocking.',
    FocusProtectionLevel.pauseAndProtect =>
      'Timer pauses on leave. Focus-protected apps are blocked and redirect you back.',
    FocusProtectionLevel.intentionalExit =>
      'Pause on leave, a five-second exit reflection, and focus-protected apps are blocked.',
  };

  bool get pausesWhenLeaving => this != FocusProtectionLevel.softReturn;

  bool get requiresExitReflection =>
      this == FocusProtectionLevel.intentionalExit;

  ProtectionMode toProtectionMode() => switch (this) {
        FocusProtectionLevel.softReturn => ProtectionMode.nudge,
        FocusProtectionLevel.pauseAndProtect => ProtectionMode.guard,
        FocusProtectionLevel.intentionalExit => ProtectionMode.deep,
      };
}
