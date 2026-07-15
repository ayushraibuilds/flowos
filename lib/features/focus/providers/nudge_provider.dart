import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pending_trigger.dart';
import '../services/protection_policy_service.dart';

class CurrentNudgeNotifier extends StateNotifier<PendingNudge?> {
  final ProtectionPolicyService _policyService;
  bool _isChecking = false;

  CurrentNudgeNotifier(this._policyService) : super(null);

  Future<void> checkForNudge() async {
    if (_isChecking) return;
    _isChecking = true;
    try {
      final nudge = await _policyService.claimPendingNudge();
      if (nudge != null) {
        state = nudge;
      }
    } catch (_) {} finally {
      _isChecking = false;
    }
  }

  void dismiss() {
    state = null;
  }
}

final currentNudgeProvider =
    StateNotifierProvider<CurrentNudgeNotifier, PendingNudge?>((ref) {
  final service = ref.watch(protectionPolicyServiceProvider);
  return CurrentNudgeNotifier(service);
});
