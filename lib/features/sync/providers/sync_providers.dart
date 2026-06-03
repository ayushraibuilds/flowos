import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/sync_engine.dart';
import '../../auth/services/auth_service.dart';

// ─── Sync Engine Provider ───────────────────────────────────────

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SyncEngine(client);
});

// ─── Sync Status ────────────────────────────────────────────────

enum SyncStatus { idle, syncing, synced, error }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

// ─── Sync Controller ────────────────────────────────────────────

/// Manages sync lifecycle: triggers on auth changes and network reconnect.
final syncControllerProvider = Provider<SyncController>((ref) {
  final engine = ref.watch(syncEngineProvider);
  final status = ref.read(syncStatusProvider.notifier);

  // Auto-sync on auth state change
  ref.listen(authStateProvider, (prev, next) {
    next.whenData((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        _triggerSync(engine, status);
      }
    });
  });

  return SyncController(engine: engine, statusNotifier: status);
});

class SyncController {
  final SyncEngine engine;
  final StateController<SyncStatus> statusNotifier;

  SyncController({required this.engine, required this.statusNotifier});

  /// Manual full sync
  Future<SyncResult> sync() async {
    statusNotifier.state = SyncStatus.syncing;
    final result = await engine.fullSync();
    statusNotifier.state = result.hasErrors ? SyncStatus.error : SyncStatus.synced;
    return result;
  }

  /// Schedule a push (debounced, called after local mutations)
  void schedulePush() {
    engine.schedulePush();
  }
}

Future<void> _triggerSync(SyncEngine engine, StateController<SyncStatus> status) async {
  status.state = SyncStatus.syncing;
  final result = await engine.fullSync();
  status.state = result.hasErrors ? SyncStatus.error : SyncStatus.synced;
}
