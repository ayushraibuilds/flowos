import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database/app_database.dart';
import '../models/effective_policy.dart';
import '../models/pending_trigger.dart';
import 'policy_writer.dart';
import '../../attention/repository/attention_data_repository.dart';

class ProtectionPolicyService {
  final AppDatabase _db;
  final DeviceAttentionPlatform _platform;
  final PolicyWriter _policyWriter;

  ProtectionPolicyService(this._db, this._platform, this._policyWriter);

  Future<void> activateFocusPolicy({
    required String sessionId,
    required ProtectionMode mode,
  }) async {
    final protectedApps = await _db.protectedAppsDao.getFocusProtected();
    final packages = protectedApps.map((a) => a.appRef).toSet();

    final policy = SourcePolicy(
      sessionId: sessionId,
      activeUntil: DateTime.now().add(const Duration(minutes: 3)),
      selectedPackages: packages,
      protectionMode: mode,
      source: PolicySource.focus,
      scopedBreaks: [],
    );

    await _policyWriter.activatePolicy(policy);
  }

  Future<void> deactivateFocusPolicy() async {
    await _policyWriter.deactivatePolicy(PolicySource.focus);
  }

  Future<void> renewFocusLease() async {
    await _policyWriter.renewLease(
      PolicySource.focus,
      DateTime.now().add(const Duration(minutes: 3)),
    );
  }

  Future<void> grantScopedBreak({
    required String packageName,
    required int minutes,
  }) async {
    if (!ActivePolicies.guardBreakOptions.contains(minutes)) {
      throw ArgumentError('Invalid guard break duration: $minutes');
    }

    final activePolicies = await _policyWriter.getActivePolicies();
    if (activePolicies != null) {
      final activeSleep = (activePolicies.sleep != null && !activePolicies.sleep!.isExpired)
          ? activePolicies.sleep
          : null;
      if (activeSleep != null && activeSleep.selectedPackages.contains(packageName)) {
        // Sleep policy is active and protects this package.
        // If sleep is Deep, a Focus Guard temporary break is ignored (cannot override sleep deep).
        if (activeSleep.protectionMode.strictnessValue > ProtectionMode.guard.strictnessValue) {
          // Stricter sleep deep mode is active. Scoped break cannot be granted.
          return;
        }
      }
    }

    final scopedBreak = ScopedBreak(
      packageName: packageName,
      expiresAt: DateTime.now().add(Duration(minutes: minutes)),
      source: PolicySource.focus,
    );

    await _policyWriter.grantScopedBreak(scopedBreak);
  }

  Future<PendingTrigger?> claimPendingTrigger() async {
    try {
      final triggerJson = await _platform.claimPendingBlockedAppTrigger();
      if (triggerJson != null) {
        final trigger = PendingTrigger.fromJson(triggerJson);
        if (!trigger.isExpired) {
          return trigger;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<PendingTrigger>> getNudgeEvents() async {
    try {
      final events = await _platform.getNudgeEvents();
      final list = events.map((e) => PendingTrigger.fromJson(e)).toList();
      return list.where((e) => !e.isExpired).toList();
    } catch (_) {}
    return [];
  }

  Future<ActivePolicies?> getActivePolicies() async {
    return _policyWriter.getActivePolicies();
  }
}

final protectionPolicyServiceProvider = Provider<ProtectionPolicyService>((ref) {
  final db = ref.watch(databaseProvider);
  final platform = ref.watch(deviceAttentionPlatformProvider);
  const policyWriter = SharedPrefsPolicyWriter();
  return ProtectionPolicyService(db, platform, policyWriter);
});
