import 'dart:convert';

enum ProtectionMode { nudge, guard, deep }

extension ProtectionModeValue on ProtectionMode {
  int get strictnessValue => switch (this) {
        ProtectionMode.nudge => 0,
        ProtectionMode.guard => 1,
        ProtectionMode.deep => 2,
      };
}

enum PolicySource { focus, sleep }

class ScopedBreak {
  final String packageName;
  final DateTime expiresAt;
  final PolicySource source;

  const ScopedBreak({
    required this.packageName,
    required this.expiresAt,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'source': source.name,
      };

  factory ScopedBreak.fromJson(Map<String, dynamic> json) => ScopedBreak(
        packageName: json['packageName'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
        source: PolicySource.values.byName(json['source'] as String),
      );

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class SourcePolicy {
  final String sessionId;
  final DateTime activeUntil;
  final Set<String> selectedPackages;
  final ProtectionMode protectionMode;
  final PolicySource source;
  final List<ScopedBreak> scopedBreaks;

  const SourcePolicy({
    required this.sessionId,
    required this.activeUntil,
    required this.selectedPackages,
    required this.protectionMode,
    required this.source,
    required this.scopedBreaks,
  });

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'activeUntil': activeUntil.millisecondsSinceEpoch,
        'selectedPackages': selectedPackages.toList(),
        'protectionMode': protectionMode.name,
        'source': source.name,
        'scopedBreaks': scopedBreaks.map((b) => b.toJson()).toList(),
      };

  factory SourcePolicy.fromJson(Map<String, dynamic> json) => SourcePolicy(
        sessionId: json['sessionId'] as String? ?? '',
        activeUntil: DateTime.fromMillisecondsSinceEpoch(json['activeUntil'] as int),
        selectedPackages: List<String>.from(json['selectedPackages'] ?? []).toSet(),
        protectionMode: ProtectionMode.values.byName(json['protectionMode'] as String),
        source: PolicySource.values.byName(json['source'] as String),
        scopedBreaks: (json['scopedBreaks'] as List? ?? [])
            .map((b) => ScopedBreak.fromJson(Map<String, dynamic>.from(b)))
            .toList(),
      );

  bool get isExpired => DateTime.now().isAfter(activeUntil);
}

class ActivePolicies {
  final SourcePolicy? focus;
  final SourcePolicy? sleep;

  static const guardBreakOptions = [5, 10, 15];

  const ActivePolicies({
    this.focus,
    this.sleep,
  });

  Map<String, dynamic> toJson() => {
        'focus': focus?.toJson(),
        'sleep': sleep?.toJson(),
      };

  factory ActivePolicies.fromJson(Map<String, dynamic> json) {
    final focusJson = json['focus'];
    final sleepJson = json['sleep'];
    return ActivePolicies(
      focus: focusJson != null ? SourcePolicy.fromJson(Map<String, dynamic>.from(focusJson)) : null,
      sleep: sleepJson != null ? SourcePolicy.fromJson(Map<String, dynamic>.from(sleepJson)) : null,
    );
  }

  String toPrefsJson() => jsonEncode(toJson());

  factory ActivePolicies.fromPrefsJson(String jsonStr) {
    if (jsonStr.isEmpty || jsonStr == '{}') {
      return const ActivePolicies();
    }
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) {
        return ActivePolicies.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
    return const ActivePolicies();
  }

  ProtectionMode? effectiveModeForPackage(String packageName) {
    final activeFocus = (focus != null && !focus!.isExpired) ? focus : null;
    final activeSleep = (sleep != null && !sleep!.isExpired) ? sleep : null;

    ProtectionMode? focusMode;
    if (activeFocus != null && activeFocus.selectedPackages.contains(packageName)) {
      focusMode = activeFocus.protectionMode;
    }

    ProtectionMode? sleepMode;
    if (activeSleep != null && activeSleep.selectedPackages.contains(packageName)) {
      sleepMode = activeSleep.protectionMode;
    }

    if (focusMode == null && sleepMode == null) return null;
    if (focusMode == null) return sleepMode;
    if (sleepMode == null) return focusMode;

    return focusMode.strictnessValue >= sleepMode.strictnessValue ? focusMode : sleepMode;
  }

  bool isScopedBreakActive(String packageName) {
    final now = DateTime.now();

    // Check focus breaks
    final activeFocus = (focus != null && !focus!.isExpired) ? focus : null;
    if (activeFocus != null && activeFocus.selectedPackages.contains(packageName)) {
      final breakActive = activeFocus.scopedBreaks.any(
        (b) => b.packageName == packageName && b.expiresAt.isAfter(now),
      );
      if (breakActive) {
        final activeSleep = (sleep != null && !sleep!.isExpired) ? sleep : null;
        if (activeSleep != null && activeSleep.selectedPackages.contains(packageName)) {
          if (activeSleep.protectionMode.strictnessValue > activeFocus.protectionMode.strictnessValue) {
            return false; // Deep sleep wins, Instagram remains blocked.
          }
          final sleepBreakActive = activeSleep.scopedBreaks.any(
            (b) => b.packageName == packageName && b.expiresAt.isAfter(now),
          );
          return sleepBreakActive;
        }
        return true;
      }
    }

    // Check sleep breaks
    final activeSleep = (sleep != null && !sleep!.isExpired) ? sleep : null;
    if (activeSleep != null && activeSleep.selectedPackages.contains(packageName)) {
      final breakActive = activeSleep.scopedBreaks.any(
        (b) => b.packageName == packageName && b.expiresAt.isAfter(now),
      );
      if (breakActive) {
        final activeFocus = (focus != null && !focus!.isExpired) ? focus : null;
        if (activeFocus != null && activeFocus.selectedPackages.contains(packageName)) {
          if (activeFocus.protectionMode.strictnessValue > activeSleep.protectionMode.strictnessValue) {
            return false;
          }
        }
        return true;
      }
    }

    return false;
  }
}
