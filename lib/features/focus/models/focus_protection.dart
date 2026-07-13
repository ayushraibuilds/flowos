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
      'A kind cue welcomes you back; your timer keeps moving.',
    FocusProtectionLevel.pauseAndProtect =>
      'Your timer pauses when you leave FlowOS, so you can return by choice.',
    FocusProtectionLevel.intentionalExit =>
      'Pause on leave, plus a five-second reflection before ending a session.',
  };

  bool get pausesWhenLeaving => this != FocusProtectionLevel.softReturn;

  bool get requiresExitReflection =>
      this == FocusProtectionLevel.intentionalExit;
}
