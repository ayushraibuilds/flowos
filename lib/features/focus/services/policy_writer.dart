import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/effective_policy.dart';

abstract class PolicyWriter {
  Future<void> activatePolicy(SourcePolicy policy);
  Future<void> deactivatePolicy(PolicySource source);
  Future<void> renewLease(PolicySource source, DateTime newActiveUntil);
  Future<void> grantScopedBreak(ScopedBreak scopedBreak);
  Future<ActivePolicies?> getActivePolicies();
}

class SharedPrefsPolicyWriter implements PolicyWriter {
  static const _key = 'flowos_active_policies';

  const SharedPrefsPolicyWriter();

  @override
  Future<ActivePolicies?> getActivePolicies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return ActivePolicies.fromPrefsJson(jsonStr);
      }
    } catch (_) {}
    return const ActivePolicies();
  }

  @override
  Future<void> activatePolicy(SourcePolicy policy) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getActivePolicies() ?? const ActivePolicies();

    final updated = ActivePolicies(
      focus: policy.source == PolicySource.focus ? policy : current.focus,
      sleep: policy.source == PolicySource.sleep ? policy : current.sleep,
    );

    await prefs.setString(_key, updated.toPrefsJson());
  }

  @override
  Future<void> deactivatePolicy(PolicySource source) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getActivePolicies() ?? const ActivePolicies();

    final updated = ActivePolicies(
      focus: source == PolicySource.focus ? null : current.focus,
      sleep: source == PolicySource.sleep ? null : current.sleep,
    );

    await prefs.setString(_key, updated.toPrefsJson());
  }

  @override
  Future<void> renewLease(PolicySource source, DateTime newActiveUntil) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getActivePolicies() ?? const ActivePolicies();

    SourcePolicy? updatedFocus = current.focus;
    SourcePolicy? updatedSleep = current.sleep;

    if (source == PolicySource.focus && current.focus != null) {
      updatedFocus = SourcePolicy(
        sessionId: current.focus!.sessionId,
        activeUntil: newActiveUntil,
        selectedPackages: current.focus!.selectedPackages,
        protectionMode: current.focus!.protectionMode,
        source: current.focus!.source,
        scopedBreaks: current.focus!.scopedBreaks,
      );
    } else if (source == PolicySource.sleep && current.sleep != null) {
      updatedSleep = SourcePolicy(
        sessionId: current.sleep!.sessionId,
        activeUntil: newActiveUntil,
        selectedPackages: current.sleep!.selectedPackages,
        protectionMode: current.sleep!.protectionMode,
        source: current.sleep!.source,
        scopedBreaks: current.sleep!.scopedBreaks,
      );
    }

    final updated = ActivePolicies(
      focus: updatedFocus,
      sleep: updatedSleep,
    );

    await prefs.setString(_key, updated.toPrefsJson());
  }

  @override
  Future<void> grantScopedBreak(ScopedBreak scopedBreak) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getActivePolicies() ?? const ActivePolicies();

    SourcePolicy? updatedFocus = current.focus;
    SourcePolicy? updatedSleep = current.sleep;

    if (scopedBreak.source == PolicySource.focus && current.focus != null) {
      final breaks = List<ScopedBreak>.from(current.focus!.scopedBreaks);
      breaks.removeWhere((b) => b.packageName == scopedBreak.packageName);
      breaks.add(scopedBreak);

      updatedFocus = SourcePolicy(
        sessionId: current.focus!.sessionId,
        activeUntil: current.focus!.activeUntil,
        selectedPackages: current.focus!.selectedPackages,
        protectionMode: current.focus!.protectionMode,
        source: current.focus!.source,
        scopedBreaks: breaks,
      );
    } else if (scopedBreak.source == PolicySource.sleep && current.sleep != null) {
      final breaks = List<ScopedBreak>.from(current.sleep!.scopedBreaks);
      breaks.removeWhere((b) => b.packageName == scopedBreak.packageName);
      breaks.add(scopedBreak);

      updatedSleep = SourcePolicy(
        sessionId: current.sleep!.sessionId,
        activeUntil: current.sleep!.activeUntil,
        selectedPackages: current.sleep!.selectedPackages,
        protectionMode: current.sleep!.protectionMode,
        source: current.sleep!.source,
        scopedBreaks: breaks,
      );
    }

    final updated = ActivePolicies(
      focus: updatedFocus,
      sleep: updatedSleep,
    );

    await prefs.setString(_key, updated.toPrefsJson());
  }
}

class FakePolicyWriter implements PolicyWriter {
  ActivePolicies policies = const ActivePolicies();

  FakePolicyWriter();

  @override
  Future<ActivePolicies?> getActivePolicies() async => policies;

  @override
  Future<void> activatePolicy(SourcePolicy policy) async {
    policies = ActivePolicies(
      focus: policy.source == PolicySource.focus ? policy : policies.focus,
      sleep: policy.source == PolicySource.sleep ? policy : policies.sleep,
    );
  }

  @override
  Future<void> deactivatePolicy(PolicySource source) async {
    policies = ActivePolicies(
      focus: source == PolicySource.focus ? null : policies.focus,
      sleep: source == PolicySource.sleep ? null : policies.sleep,
    );
  }

  @override
  Future<void> renewLease(PolicySource source, DateTime newActiveUntil) async {
    SourcePolicy? updatedFocus = policies.focus;
    SourcePolicy? updatedSleep = policies.sleep;

    if (source == PolicySource.focus && policies.focus != null) {
      updatedFocus = SourcePolicy(
        sessionId: policies.focus!.sessionId,
        activeUntil: newActiveUntil,
        selectedPackages: policies.focus!.selectedPackages,
        protectionMode: policies.focus!.protectionMode,
        source: policies.focus!.source,
        scopedBreaks: policies.focus!.scopedBreaks,
      );
    } else if (source == PolicySource.sleep && policies.sleep != null) {
      updatedSleep = SourcePolicy(
        sessionId: policies.sleep!.sessionId,
        activeUntil: newActiveUntil,
        selectedPackages: policies.sleep!.selectedPackages,
        protectionMode: policies.sleep!.protectionMode,
        source: policies.sleep!.source,
        scopedBreaks: policies.sleep!.scopedBreaks,
      );
    }

    policies = ActivePolicies(
      focus: updatedFocus,
      sleep: updatedSleep,
    );
  }

  @override
  Future<void> grantScopedBreak(ScopedBreak scopedBreak) async {
    SourcePolicy? updatedFocus = policies.focus;
    SourcePolicy? updatedSleep = policies.sleep;

    if (scopedBreak.source == PolicySource.focus && policies.focus != null) {
      final breaks = List<ScopedBreak>.from(policies.focus!.scopedBreaks);
      breaks.removeWhere((b) => b.packageName == scopedBreak.packageName);
      breaks.add(scopedBreak);

      updatedFocus = SourcePolicy(
        sessionId: policies.focus!.sessionId,
        activeUntil: policies.focus!.activeUntil,
        selectedPackages: policies.focus!.selectedPackages,
        protectionMode: policies.focus!.protectionMode,
        source: policies.focus!.source,
        scopedBreaks: breaks,
      );
    } else if (scopedBreak.source == PolicySource.sleep && policies.sleep != null) {
      final breaks = List<ScopedBreak>.from(policies.sleep!.scopedBreaks);
      breaks.removeWhere((b) => b.packageName == scopedBreak.packageName);
      breaks.add(scopedBreak);

      updatedSleep = SourcePolicy(
        sessionId: policies.sleep!.sessionId,
        activeUntil: policies.sleep!.activeUntil,
        selectedPackages: policies.sleep!.selectedPackages,
        protectionMode: policies.sleep!.protectionMode,
        source: policies.sleep!.source,
        scopedBreaks: breaks,
      );
    }

    policies = ActivePolicies(
      focus: updatedFocus,
      sleep: updatedSleep,
    );
  }
}
