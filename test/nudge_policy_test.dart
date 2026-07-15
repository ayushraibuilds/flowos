import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/focus/models/effective_policy.dart';
import 'package:flowos/features/focus/models/pending_trigger.dart';
import 'package:flowos/features/focus/services/policy_writer.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';

class FakeDeviceAttentionPlatform extends DeviceAttentionPlatform {
  Map<String, dynamic>? pendingTrigger;
  List<Map<String, dynamic>> nudgeEvents = [];
  Set<String> acknowledgedNudges = {};
  
  PermissionStates permissionStates = const PermissionStates(
    usageAccess: true,
    accessibility: true,
    notificationAccess: true,
    platformSupport: 'android',
  );

  @override
  Future<PermissionStates> getPermissionStates() async => permissionStates;

  @override
  Future<Map<String, dynamic>?> claimPendingBlockedAppTrigger() async {
    if (pendingTrigger != null) {
      final t = pendingTrigger;
      pendingTrigger = null;
      return t;
    }
    return null;
  }

  @override
  Future<PendingNudge?> claimPendingNudge() async {
    // Mimics the native MethodChannel implementation
    final prefs = await SharedPreferences.getInstance();
    final eventsStr = prefs.getString('flutter.flowos_nudge_events') ?? '[]';
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      final List<dynamic> list = jsonDecode(eventsStr);
      final List<dynamic> newList = [];
      Map<String, dynamic>? claimedNudge;

      for (final item in list) {
        final m = Map<String, dynamic>.from(item);
        final expiresAt = m['expiresAt'] as int;
        final claimed = m['claimed'] as bool? ?? false;

        if (now <= expiresAt) {
          if (!claimed && claimedNudge == null) {
            m['claimed'] = true;
            claimedNudge = m;
          }
          newList.add(m);
        }
      }
      await prefs.setString('flutter.flowos_nudge_events', jsonEncode(newList));

      if (claimedNudge != null) {
        return PendingNudge.fromJson(claimedNudge);
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> clearNudgesForSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsStr = prefs.getString('flutter.flowos_nudge_events') ?? '[]';
    try {
      final List<dynamic> list = jsonDecode(eventsStr);
      list.removeWhere((item) => item['sessionId'] == sessionId);
      await prefs.setString('flutter.flowos_nudge_events', jsonEncode(list));
    } catch (_) {}
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Nudge Policy Tests', () {
    test('ActivePolicies JSON serialization has schemaVersion: 1', () {
      final active = ActivePolicies(
        focus: SourcePolicy(
          sessionId: 'session-123',
          activeUntil: DateTime.now(),
          selectedPackages: {},
          protectionMode: ProtectionMode.nudge,
          source: PolicySource.focus,
          scopedBreaks: [],
        ),
      );
      final json = active.toJson();
      expect(json['schemaVersion'], 1);
    });

    test('Claiming a nudge marks it as claimed and consumed', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.flutter.flowos_nudge_events': jsonEncode([
          {
            'id': 'nudge-1',
            'kind': 'nudge',
            'packageName': 'com.instagram.android',
            'appLabel': 'Instagram',
            'sessionId': 'focus-123',
            'source': 'focus',
            'occurredAt': DateTime.now().millisecondsSinceEpoch,
            'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
            'claimed': false,
          }
        ]),
      });

      final platform = FakeDeviceAttentionPlatform();
      
      // First claim succeeds
      final first = await platform.claimPendingNudge();
      expect(first, isNotNull);
      expect(first!.packageName, 'com.instagram.android');
      expect(first.appLabel, 'Instagram');

      // Second claim returns null (claimed is true now)
      final second = await platform.claimPendingNudge();
      expect(second, isNull);
    });

    test('Deactivating focus policy clears nudges for the session', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flutter.flowos_nudge_events', jsonEncode([
        {
          'id': 'nudge-1',
          'kind': 'nudge',
          'packageName': 'com.instagram.android',
          'appLabel': 'Instagram',
          'sessionId': 'session-abc',
          'source': 'focus',
          'occurredAt': DateTime.now().millisecondsSinceEpoch,
          'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
          'claimed': false,
        },
        {
          'id': 'nudge-2',
          'kind': 'nudge',
          'packageName': 'com.facebook.katana',
          'appLabel': 'Facebook',
          'sessionId': 'session-diff',
          'source': 'focus',
          'occurredAt': DateTime.now().millisecondsSinceEpoch,
          'expiresAt': DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
          'claimed': false,
        }
      ]));

      // Mock policy writer with active focus session matching session-abc
      const writer = SharedPrefsPolicyWriter();
      await writer.activatePolicy(SourcePolicy(
        sessionId: 'session-abc',
        activeUntil: DateTime.now().add(const Duration(minutes: 10)),
        selectedPackages: {'com.instagram.android'},
        protectionMode: ProtectionMode.nudge,
        source: PolicySource.focus,
        scopedBreaks: [],
      ));

      // Deactivate focus policy
      await writer.deactivatePolicy(PolicySource.focus);

      // Verify that nudge-1 is deleted, but nudge-2 (from a different session) remains
      final nudgeStr = prefs.getString('flutter.flowos_nudge_events');
      expect(nudgeStr, isNotNull);
      final List<dynamic> list = jsonDecode(nudgeStr!);
      expect(list.length, 1);
      expect(list.first['id'], 'nudge-2');
    });
  });
}
