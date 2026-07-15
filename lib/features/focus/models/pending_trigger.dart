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
