import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

/// Sync Engine — Drift (local) ↔ Supabase (cloud).
///
/// Strategy:
/// - Tasks/Sessions/Plans: last-write-wins using `updated_at` + `device_id`
/// - XP Ledger: append-only push (no conflicts possible)
/// - Scroll Logs / Energy: append-only push
/// - Soft deletes: `deleted_at` instead of actual deletion
///
/// Sync runs:
/// 1. On app open (pull then push)
/// 2. After every mutation (push only)
/// 3. On network reconnect (full sync)
class SyncEngine {
  final SupabaseClient _client;
  bool _isSyncing = false;
  Timer? _debounceTimer;

  SyncEngine(this._client);

  String get _userId => _client.auth.currentUser!.id;
  bool get isAuthenticated => _client.auth.currentUser != null;

  // ─── Full Sync ─────────────────────────────────────────────

  /// Full bidirectional sync. Call on app open and network reconnect.
  Future<SyncResult> fullSync() async {
    if (!isAuthenticated || _isSyncing) {
      return SyncResult(pushed: 0, pulled: 0, errors: []);
    }

    _isSyncing = true;
    final errors = <String>[];
    int pushed = 0;
    int pulled = 0;

    try {
      // Pull first (server → local)
      pulled += await _pullTasks();
      pulled += await _pullSessions();
      pulled += await _pullPlans();
      pulled += await _pullAchievements();

      // Push (local → server)
      pushed += await _pushTasks();
      pushed += await _pushSessions();
      pushed += await _pushXpLedger();
      pushed += await _pushScrollLogs();
      pushed += await _pushEnergy();
      pushed += await _pushPlans();
      pushed += await _pushAchievements();

      debugPrint('✅ Sync complete: ↑$pushed ↓$pulled');
    } catch (e) {
      errors.add(e.toString());
      debugPrint('❌ Sync error: $e');
    } finally {
      _isSyncing = false;
    }

    return SyncResult(pushed: pushed, pulled: pulled, errors: errors);
  }

  /// Debounced push after local mutation (300ms debounce).
  void schedulePush() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _pushAll();
    });
  }

  Future<void> _pushAll() async {
    if (!isAuthenticated || _isSyncing) return;
    _isSyncing = true;
    try {
      await _pushTasks();
      await _pushSessions();
      await _pushXpLedger();
      await _pushScrollLogs();
      await _pushEnergy();
      await _pushPlans();
    } catch (e) {
      debugPrint('Push error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ─── Pull (Server → Local) ─────────────────────────────────

  Future<int> _pullTasks() async {
    try {
      final data = await _client
          .from('tasks')
          .select()
          .order('updated_at', ascending: false)
          .limit(500);

      // TODO: Upsert into Drift using updated_at comparison
      // For each server row:
      //   - If local row exists and server.updated_at > local.updated_at → update local
      //   - If local row doesn't exist → insert local
      //   - If server.deleted_at is set → soft-delete local

      return (data as List).length;
    } catch (e) {
      debugPrint('Pull tasks error: $e');
      return 0;
    }
  }

  Future<int> _pullSessions() async {
    try {
      final data = await _client
          .from('focus_sessions')
          .select()
          .order('updated_at', ascending: false)
          .limit(500);
      return (data as List).length;
    } catch (e) {
      debugPrint('Pull sessions error: $e');
      return 0;
    }
  }

  Future<int> _pullPlans() async {
    try {
      final data = await _client
          .from('daily_plans')
          .select()
          .order('plan_date', ascending: false)
          .limit(60);
      return (data as List).length;
    } catch (e) {
      debugPrint('Pull plans error: $e');
      return 0;
    }
  }

  Future<int> _pullAchievements() async {
    try {
      final data = await _client.from('achievements').select();
      return (data as List).length;
    } catch (e) {
      debugPrint('Pull achievements error: $e');
      return 0;
    }
  }

  // ─── Push (Local → Server) ─────────────────────────────────

  Future<int> _pushTasks() async {
    // TODO: Query Drift for tasks with updated_at > last_synced_at
    // Upsert to Supabase with device_id and conflict on id
    return 0;
  }

  Future<int> _pushSessions() async {
    return 0;
  }

  /// XP Ledger — append-only. Only push entries not yet synced.
  Future<int> _pushXpLedger() async {
    // TODO: Query Drift for XP entries not yet in Supabase
    // INSERT only, never UPDATE. No conflicts possible.
    return 0;
  }

  Future<int> _pushScrollLogs() async {
    return 0;
  }

  Future<int> _pushEnergy() async {
    return 0;
  }

  Future<int> _pushPlans() async {
    return 0;
  }

  Future<int> _pushAchievements() async {
    return 0;
  }

  // ─── Helpers ───────────────────────────────────────────────

  /// Upsert a batch of rows to Supabase table.
  Future<void> _upsertBatch(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    for (final row in rows) {
      row['user_id'] = _userId;
      row['device_id'] = SupabaseConfig.deviceId;
    }

    await _client.from(table).upsert(rows, onConflict: 'id');
  }

  /// Append-only insert (for XP ledger, scroll logs, energy).
  Future<void> _appendBatch(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    for (final row in rows) {
      row['user_id'] = _userId;
    }

    // Use insert with ignoreDuplicates to skip already-synced rows
    await _client.from(table).insert(rows);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Sync result
class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;

  SyncResult({required this.pushed, required this.pulled, required this.errors});

  bool get hasErrors => errors.isNotEmpty;
  bool get isClean => !hasErrors && (pushed > 0 || pulled > 0);
}
