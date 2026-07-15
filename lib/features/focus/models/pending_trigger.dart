class PendingTrigger {
  final String id;
  final String packageName;
  final int triggeredAt;
  final String source;
  final bool claimed;

  const PendingTrigger({
    required this.id,
    required this.packageName,
    required this.triggeredAt,
    required this.source,
    required this.claimed,
  });

  bool get isExpired {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return nowMs - triggeredAt > 60000; // 60 seconds
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'triggeredAt': triggeredAt,
        'source': source,
        'claimed': claimed,
      };

  factory PendingTrigger.fromJson(Map<String, dynamic> json) => PendingTrigger(
        id: json['id'] as String,
        packageName: json['packageName'] as String,
        triggeredAt: json['triggeredAt'] as int,
        source: json['source'] as String? ?? 'focus',
        claimed: json['claimed'] as bool? ?? false,
      );
}

class PendingNudge {
  final String id;
  final String packageName;
  final String appLabel;
  final String sessionId;
  final String source;
  final int occurredAt;
  final int expiresAt;

  const PendingNudge({
    required this.id,
    required this.packageName,
    required this.appLabel,
    required this.sessionId,
    required this.source,
    required this.occurredAt,
    required this.expiresAt,
  });

  bool get isExpired {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return nowMs > expiresAt;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'packageName': packageName,
        'appLabel': appLabel,
        'sessionId': sessionId,
        'source': source,
        'occurredAt': occurredAt,
        'expiresAt': expiresAt,
      };

  factory PendingNudge.fromJson(Map<String, dynamic> json) => PendingNudge(
        id: json['id'] as String,
        packageName: json['packageName'] as String,
        appLabel: json['appLabel'] as String? ?? json['packageName'] as String,
        sessionId: json['sessionId'] as String? ?? '',
        source: json['source'] as String? ?? 'focus',
        occurredAt: json['occurredAt'] as int,
        expiresAt: json['expiresAt'] as int,
      );
}
