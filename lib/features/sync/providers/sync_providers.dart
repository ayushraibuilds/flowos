import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/sync_engine.dart';
import '../../auth/services/auth_service.dart';
import '../../../data/local/database/app_database.dart';

// ─── Sync Engine Provider ───────────────────────────────────────

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final db = ref.watch(databaseProvider);
  return SyncEngine(client, db);
});

// ─── Sync Status ────────────────────────────────────────────────

enum SyncStatus { idle, syncing, synced, error, authError, offline }

final syncStatusProvider = StateProvider<SyncStatus>((ref) => SyncStatus.idle);

// ─── Sync Controller ────────────────────────────────────────────

/// Manages sync lifecycle: triggers on auth changes, network reconnect, and manages backoff.
final syncControllerProvider = Provider<SyncController>((ref) {
  final engine = ref.watch(syncEngineProvider);
  final status = ref.read(syncStatusProvider.notifier);

  final controller = SyncController(engine: engine, statusNotifier: status);

  // Auto-sync on auth state change
  ref.listen(authStateProvider, (prev, next) {
    next.whenData((state) {
      if (state.event == AuthChangeEvent.signedIn) {
        controller.resetBackoff();
        controller.sync();
      } else if (state.event == AuthChangeEvent.signedOut) {
        controller.cancel();
      }
    });
  });

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

class SyncController {
  final SyncEngine engine;
  final StateController<SyncStatus> statusNotifier;

  int _retryCount = 0;
  Timer? _retryTimer;
  static const int maxRetries = 5;

  SyncController({required this.engine, required this.statusNotifier});

  int get retryCount => _retryCount;
  bool get hasActiveRetryTimer => _retryTimer != null && _retryTimer!.isActive;

  void resetBackoff() {
    _retryCount = 0;
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void cancel() {
    resetBackoff();
    engine.cancelSync();
    statusNotifier.state = SyncStatus.idle;
  }

  /// Manual or automated sync call
  Future<SyncResult> sync() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    statusNotifier.state = SyncStatus.syncing;

    final result = await engine.fullSync();

    if (result.isCancelled) {
      statusNotifier.state = SyncStatus.idle;
      return result;
    }

    if (result.isAuthError) {
      statusNotifier.state = SyncStatus.authError;
      return result;
    }

    if (result.hasErrors) {
      if (result.isRetryable && _retryCount < maxRetries) {
        statusNotifier.state = SyncStatus.offline;
        _scheduleRetry();
      } else {
        statusNotifier.state = SyncStatus.error;
      }
      return result;
    }

    _retryCount = 0;
    statusNotifier.state = SyncStatus.synced;
    return result;
  }

  void _scheduleRetry() {
    _retryTimer?.cancel();
    final delaySeconds = 1 << _retryCount; // 1s, 2s, 4s, 8s, 16s
    _retryCount++;
    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      sync();
    });
  }

  /// Manual retry method
  Future<SyncResult> retry() async {
    resetBackoff();
    return sync();
  }

  /// Schedule a push (debounced, called after local mutations)
  void schedulePush() {
    engine.schedulePush();
  }

  void dispose() {
    resetBackoff();
    engine.dispose();
  }
}
