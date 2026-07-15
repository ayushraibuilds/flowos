import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/attention/repository/attention_data_repository.dart';
import 'package:flowos/features/focus/models/effective_policy.dart';
import 'package:flowos/features/focus/models/pending_trigger.dart';
import 'package:flowos/features/focus/services/policy_writer.dart';
import 'package:flowos/features/focus/services/protection_policy_service.dart';

class FakeDeviceAttentionPlatform extends DeviceAttentionPlatform {
  Map<String, dynamic>? pendingTrigger;
  List<Map<String, dynamic>> nudgeEvents = [];
  Set<String> acknowledgedNudges = {};

  @override
  Future<Map<String, dynamic>?> claimPendingBlockedAppTrigger() async {
    if (pendingTrigger != null) {
      final t = Map<String, dynamic>.from(pendingTrigger!);
      if (t['claimed'] == false) {
        t['claimed'] = true;
        pendingTrigger = t;
        return t;
      }
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> getNudgeEvents() async {
    return nudgeEvents.where((e) => !acknowledgedNudges.contains(e['id'])).toList();
  }

  @override
  Future<void> acknowledgeNudgeEvent(String id) async {
    acknowledgedNudges.add(id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeDeviceAttentionPlatform platform;
  late FakePolicyWriter policyWriter;
  late ProtectionPolicyService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    platform = FakeDeviceAttentionPlatform();
    policyWriter = FakePolicyWriter();
    service = ProtectionPolicyService(db, platform, policyWriter);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProtectionPolicyService M1 Tests', () {
    test('activateFocusPolicy writes correct active policies set', () async {
      await service.activateFocusPolicy(
        sessionId: 'session-123',
        mode: ProtectionMode.guard,
      );

      final policies = await policyWriter.getActivePolicies();
      expect(policies, isNotNull);
      expect(policies!.focus, isNotNull);
      expect(policies.focus!.sessionId, 'session-123');
      expect(policies.focus!.protectionMode, ProtectionMode.guard);
      expect(policies.focus!.source, PolicySource.focus);
    });

    test('deactivateFocusPolicy removes only focus entry', () async {
      // Setup both focus and sleep active
      final now = DateTime.now();
      policyWriter.policies = ActivePolicies(
        focus: SourcePolicy(
          sessionId: 'f-123',
          activeUntil: now.add(const Duration(minutes: 10)),
          selectedPackages: {'pkg.a'},
          protectionMode: ProtectionMode.guard,
          source: PolicySource.focus,
          scopedBreaks: [],
        ),
        sleep: SourcePolicy(
          sessionId: 's-123',
          activeUntil: now.add(const Duration(minutes: 10)),
          selectedPackages: {'pkg.b'},
          protectionMode: ProtectionMode.deep,
          source: PolicySource.sleep,
          scopedBreaks: [],
        ),
      );

      await service.deactivateFocusPolicy();

      final policies = await policyWriter.getActivePolicies();
      expect(policies!.focus, isNull);
      expect(policies.sleep, isNotNull);
      expect(policies.sleep!.sessionId, 's-123');
    });

    test('renewFocusLease extends activeUntil', () async {
      final now = DateTime.now();
      policyWriter.policies = ActivePolicies(
        focus: SourcePolicy(
          sessionId: 'f-123',
          activeUntil: now.add(const Duration(minutes: 1)),
          selectedPackages: {'pkg.a'},
          protectionMode: ProtectionMode.guard,
          source: PolicySource.focus,
          scopedBreaks: [],
        ),
      );

      await service.renewFocusLease();

      final policies = await policyWriter.getActivePolicies();
      expect(policies!.focus!.activeUntil.isAfter(now.add(const Duration(minutes: 2))), true);
    });

    test('empty protected_apps table resolves to empty package set', () async {
      await service.activateFocusPolicy(
        sessionId: 'f-123',
        mode: ProtectionMode.guard,
      );
      final policies = await policyWriter.getActivePolicies();
      expect(policies!.focus!.selectedPackages, isEmpty);
    });

    test('grantScopedBreak validates guard break durations', () async {
      policyWriter.policies = ActivePolicies(
        focus: SourcePolicy(
          sessionId: 'f-123',
          activeUntil: DateTime.now().add(const Duration(minutes: 10)),
          selectedPackages: {'pkg.a'},
          protectionMode: ProtectionMode.guard,
          source: PolicySource.focus,
          scopedBreaks: [],
        ),
      );

      await service.grantScopedBreak(packageName: 'pkg.a', minutes: 5);
      final policies = await policyWriter.getActivePolicies();
      expect(policies!.focus!.scopedBreaks.length, 1);
      expect(policies.focus!.scopedBreaks.first.packageName, 'pkg.a');

      expect(
        () => service.grantScopedBreak(packageName: 'pkg.a', minutes: 7),
        throwsArgumentError,
      );
    });

    test('no structured policy -> no blocking', () async {
      final policies = await policyWriter.getActivePolicies();
      expect(policies!.effectiveModeForPackage('pkg.a'), isNull);
    });

    test('Focus Guard plus Sleep Deep -> Deep remains active after focus ends', () async {
      final now = DateTime.now();
      policyWriter.policies = ActivePolicies(
        focus: SourcePolicy(
          sessionId: 'f-123',
          activeUntil: now.add(const Duration(minutes: 10)),
          selectedPackages: {'instagram'},
          protectionMode: ProtectionMode.guard,
          source: PolicySource.focus,
          scopedBreaks: [],
        ),
        sleep: SourcePolicy(
          sessionId: 's-123',
          activeUntil: now.add(const Duration(minutes: 10)),
          selectedPackages: {'instagram', 'youtube'},
          protectionMode: ProtectionMode.deep,
          source: PolicySource.sleep,
          scopedBreaks: [],
        ),
      );

      expect(policyWriter.policies.effectiveModeForPackage('instagram'), ProtectionMode.deep);

      await service.deactivateFocusPolicy();

      final policies = await policyWriter.getActivePolicies();
      expect(policies!.effectiveModeForPackage('instagram'), ProtectionMode.deep);
      expect(policies.effectiveModeForPackage('youtube'), ProtectionMode.deep);
    });

    test('Temporary Instagram break does not permit YouTube', () async {
      final now = DateTime.now();
      policyWriter.policies = ActivePolicies(
        focus: SourcePolicy(
          sessionId: 'f-123',
          activeUntil: now.add(const Duration(minutes: 10)),
          selectedPackages: {'instagram', 'youtube'},
          protectionMode: ProtectionMode.guard,
          source: PolicySource.focus,
          scopedBreaks: [
            ScopedBreak(
              packageName: 'instagram',
              expiresAt: now.add(const Duration(minutes: 5)),
              source: PolicySource.focus,
            ),
          ],
        ),
      );

      expect(policyWriter.policies.isScopedBreakActive('instagram'), true);
      expect(policyWriter.policies.isScopedBreakActive('youtube'), false);
    });

    test('Temporary Focus break does not override Deep Sleep policy', () async {
      final now = DateTime.now();
      policyWriter.policies = ActivePolicies(
        focus: SourcePolicy(
          sessionId: 'f-123',
          activeUntil: now.add(const Duration(minutes: 10)),
          selectedPackages: {'instagram'},
          protectionMode: ProtectionMode.guard,
          source: PolicySource.focus,
          scopedBreaks: [
            ScopedBreak(
              packageName: 'instagram',
              expiresAt: now.add(const Duration(minutes: 5)),
              source: PolicySource.focus,
            ),
          ],
        ),
        sleep: SourcePolicy(
          sessionId: 's-123',
          activeUntil: now.add(const Duration(minutes: 10)),
          selectedPackages: {'instagram'},
          protectionMode: ProtectionMode.deep,
          source: PolicySource.sleep,
          scopedBreaks: [],
        ),
      );

      // Even though there's a scoped break from focus, sleep mode deep still blocks it!
      expect(policyWriter.policies.isScopedBreakActive('instagram'), false);
      expect(policyWriter.policies.effectiveModeForPackage('instagram'), ProtectionMode.deep);
    });

    test('Expired or claimed trigger never opens a second shield', () async {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      platform.pendingTrigger = {
        'id': 'trig-123',
        'packageName': 'instagram',
        'triggeredAt': nowMs,
        'source': 'focus',
        'claimed': false,
      };

      final t1 = await service.claimPendingTrigger();
      expect(t1, isNotNull);
      expect(t1!.packageName, 'instagram');
      expect(platform.pendingTrigger!['claimed'], true);

      final t2 = await service.claimPendingTrigger();
      expect(t2, isNull);

      // Expired trigger is also ignored
      platform.pendingTrigger = {
        'id': 'trig-456',
        'packageName': 'youtube',
        'triggeredAt': nowMs - 70000, // > 60s ago
        'source': 'focus',
        'claimed': false,
      };
      final t3 = await service.claimPendingTrigger();
      expect(t3, isNull);
    });
  });
}
