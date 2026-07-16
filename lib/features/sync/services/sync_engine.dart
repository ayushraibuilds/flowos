import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/supabase_config.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../utils/cloud_mappers.dart';

/// Sync Engine — Drift (local) ↔ Supabase (cloud).
///
/// Strategy:
/// - Transactional Outbox for local modifications (push ASC by transaction)
/// - Server Cursors per-entity for pulling changes (gt/eq cursor check)
/// - Conflict Resolution: server-ordered Last-Write-Wins (LWW) with deterministic device ID tie-break.
class SyncEngine {
  final SupabaseClient _client;
  final AppDatabase _db;
  bool _isSyncing = false;
  bool _syncRequested = false;
  Timer? _debounceTimer;

  SyncEngine(this._client, this._db);

  String get _userId => _client.auth.currentUser!.id;
  bool get isAuthenticated => _client.auth.currentUser != null;

  // ─── Watermark Cursors ───────────────────────────────────────────────

  Future<Map<String, String>?> _getCursor(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedAt = prefs.getString('flowos_sync_cursor_v2_${table}_updated_at');
    final id = prefs.getString('flowos_sync_cursor_v2_${table}_id');
    if (updatedAt == null || id == null) return null;
    return {'updated_at': updatedAt, 'id': id};
  }

  Future<void> _setCursor(String table, String updatedAt, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('flowos_sync_cursor_v2_${table}_updated_at', updatedAt);
    await prefs.setString('flowos_sync_cursor_v2_${table}_id', id);
  }

  // ─── Full Sync ─────────────────────────────────────────────────────

  /// Full bidirectional sync. Pulls newest changes from cursors, then pushes unsynced outbox.
  Future<SyncResult> fullSync() async {
    if (!SupabaseConfig.isConfigured || !isAuthenticated) {
      return SyncResult(pushed: 0, pulled: 0, errors: ['Supabase not configured or not authenticated'], isPaused: false);
    }

    if (_isSyncing) {
      _syncRequested = true;
      return SyncResult(pushed: 0, pulled: 0, errors: [], isPaused: false);
    }

    _isSyncing = true;
    _syncRequested = false;

    int pushedCount = 0;
    int pulledCount = 0;
    final List<String> errors = [];

    try {
      // 1. Pull changes table by table using cursors
      pulledCount += await _pullTable('tasks');
      pulledCount += await _pullTable('focus_sessions');
      pulledCount += await _pullTable('daily_plans');
      pulledCount += await _pullTable('daily_reports');
      pulledCount += await _pullTable('scroll_logs');
      pulledCount += await _pullTable('energy_checkins');
      pulledCount += await _pullTable('achievements');
      pulledCount += await _pullTable('xp_ledger');
      pulledCount += await _pullTable('unlock_attempts');

      // 2. Push unacknowledged outbox operations
      pushedCount += await _pushOutbox();
    } catch (e) {
      errors.add(e.toString());
      debugPrint('Sync engine execution error: $e');
    } finally {
      _isSyncing = false;
    }

    if (_syncRequested) {
      final nextResult = await fullSync();
      return SyncResult(
        pushed: pushedCount + nextResult.pushed,
        pulled: pulledCount + nextResult.pulled,
        errors: [...errors, ...nextResult.errors],
        isPaused: false,
      );
    }

    return SyncResult(pushed: pushedCount, pulled: pulledCount, errors: errors, isPaused: false);
  }

  void schedulePush() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      fullSync();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PULL (Server → Local)
  // ═══════════════════════════════════════════════════════════════

  Future<int> _pullTable(String table) async {
    int pulledCount = 0;
    bool hasMore = true;

    while (hasMore) {
      final cursor = await _getCursor(table);
      var query = _client.from(table).select();

      final sortCol = (table == 'xp_ledger' || table == 'unlock_attempts') ? 'created_at' : 'updated_at';

      if (cursor != null) {
        final cTime = cursor['updated_at']!;
        final cId = cursor['id']!;
        query = query.or('$sortCol.gt.$cTime,and($sortCol.eq.$cTime,id.gt.$cId)');
      }

      final List<dynamic> data = await query
          .order(sortCol, ascending: true)
          .order('id', ascending: true)
          .limit(100);

      if (data.isEmpty) {
        hasMore = false;
        break;
      }

      for (final row in data) {
        final id = row['id'] as String;
        final serverTime = row[sortCol] as String;

        // Process row
        await _applyRowFromSync(table, row);

        // Update cursor watermark
        await _setCursor(table, serverTime, id);
        pulledCount++;
      }

      if (data.length < 100) {
        hasMore = false;
      }
    }

    return pulledCount;
  }

  Future<void> _applyRowFromSync(String table, Map<String, dynamic> row) async {
    final id = row['id'] as String;

    switch (table) {
      case 'tasks':
        final server = CloudMappers.taskFromCloud(row);
        final local = await _db.tasksDao.getById(id);
        if (local == null) {
          await _db.tasksDao.insertTaskFromSync(server);
        } else {
          final serverUpdated = DateTime.parse(row['updated_at'] as String);
          if (serverUpdated.isAfter(local.updatedAt)) {
            await _db.tasksDao.updateTaskFromSync(server);
          } else if (serverUpdated.isAtSameMomentAs(local.updatedAt)) {
            final serverDev = row['device_id'] as String? ?? '';
            if (serverDev.compareTo(SupabaseConfig.deviceId) > 0) {
              await _db.tasksDao.updateTaskFromSync(server);
            }
          }
        }
        break;

      case 'focus_sessions':
        final server = CloudMappers.focusSessionFromCloud(row);
        final local = await _db.focusSessionsDao.getById(id);
        if (local == null) {
          await _db.focusSessionsDao.insertSessionFromSync(server);
        } else {
          final serverUpdated = DateTime.parse(row['updated_at'] as String);
          if (serverUpdated.isAfter(local.updatedAt)) {
            await _db.focusSessionsDao.updateSessionFromSync(server);
          } else if (serverUpdated.isAtSameMomentAs(local.updatedAt)) {
            final serverDev = row['device_id'] as String? ?? '';
            if (serverDev.compareTo(SupabaseConfig.deviceId) > 0) {
              await _db.focusSessionsDao.updateSessionFromSync(server);
            }
          }
        }
        break;

      case 'daily_plans':
        final server = CloudMappers.dailyPlanFromCloud(row);
        final local = await _db.dailyPlansDao.getById(id);
        if (local == null) {
          await _db.dailyPlansDao.insertPlanFromSync(server);
        } else {
          final serverUpdated = DateTime.parse(row['updated_at'] as String);
          if (serverUpdated.isAfter(local.updatedAt)) {
            await _db.dailyPlansDao.updatePlanFromSync(server);
          } else if (serverUpdated.isAtSameMomentAs(local.updatedAt)) {
            final serverDev = row['device_id'] as String? ?? '';
            if (serverDev.compareTo(SupabaseConfig.deviceId) > 0) {
              await _db.dailyPlansDao.updatePlanFromSync(server);
            }
          }
        }
        break;

      case 'daily_reports':
        final server = CloudMappers.dailyReportFromCloud(row);
        final local = await _db.dailyReportsDao.getById(id);
        if (local == null) {
          await _db.dailyReportsDao.insertReportFromSync(server);
        } else {
          final serverUpdated = DateTime.parse(row['updated_at'] as String);
          if (serverUpdated.isAfter(local.updatedAt)) {
            await _db.dailyReportsDao.updateReportFromSync(server);
          } else if (serverUpdated.isAtSameMomentAs(local.updatedAt)) {
            final serverDev = row['device_id'] as String? ?? '';
            if (serverDev.compareTo(SupabaseConfig.deviceId) > 0) {
              await _db.dailyReportsDao.updateReportFromSync(server);
            }
          }
        }
        break;

      case 'scroll_logs':
        final server = CloudMappers.scrollLogFromCloud(row);
        final local = await _db.scrollLogsDao.getById(id);
        if (local == null) {
          await _db.scrollLogsDao.insertLogFromSync(server);
        } else {
          final serverUpdated = DateTime.parse(row['updated_at'] as String);
          if (serverUpdated.isAfter(local.updatedAt)) {
            await _db.scrollLogsDao.updateLogFromSync(server);
          } else if (serverUpdated.isAtSameMomentAs(local.updatedAt)) {
            final serverDev = row['device_id'] as String? ?? '';
            if (serverDev.compareTo(SupabaseConfig.deviceId) > 0) {
              await _db.scrollLogsDao.updateLogFromSync(server);
            }
          }
        }
        break;

      case 'energy_checkins':
        final server = CloudMappers.energyCheckInFromCloud(row);
        final local = await _db.energyCheckInsDao.getById(id);
        if (local == null) {
          await _db.energyCheckInsDao.insertCheckInFromSync(server);
        } else {
          final serverUpdated = DateTime.parse(row['updated_at'] as String);
          if (serverUpdated.isAfter(local.updatedAt)) {
            await _db.energyCheckInsDao.updateCheckInFromSync(server);
          } else if (serverUpdated.isAtSameMomentAs(local.updatedAt)) {
            final serverDev = row['device_id'] as String? ?? '';
            if (serverDev.compareTo(SupabaseConfig.deviceId) > 0) {
              await _db.energyCheckInsDao.updateCheckInFromSync(server);
            }
          }
        }
        break;

      case 'achievements':
        final server = CloudMappers.achievementFromCloud(row);
        final local = await _db.achievementsDao.getById(id);
        if (local == null) {
          await _db.achievementsDao.insertAchievementFromSync(server);
        } else {
          final serverUpdated = DateTime.parse(row['updated_at'] as String);
          if (serverUpdated.isAfter(local.updatedAt)) {
            await _db.achievementsDao.updateAchievementFromSync(server);
          } else if (serverUpdated.isAtSameMomentAs(local.updatedAt)) {
            final serverDev = row['device_id'] as String? ?? '';
            if (serverDev.compareTo(SupabaseConfig.deviceId) > 0) {
              await _db.achievementsDao.updateAchievementFromSync(server);
            }
          }
        }
        break;

      case 'xp_ledger':
        final server = CloudMappers.xpLedgerFromCloud(row);
        final local = await _db.xpLedgerDao.getById(id);
        if (local == null) {
          await _db.xpLedgerDao.appendEntryFromSync(server);
        }
        break;

      case 'unlock_attempts':
        final server = CloudMappers.unlockAttemptFromCloud(row);
        final local = await _db.unlockAttemptsDao.getById(id);
        if (local == null) {
          await _db.unlockAttemptsDao.insertAttemptFromSync(server);
        }
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PUSH (Local → Server)
  // ═══════════════════════════════════════════════════════════════

  Future<int> _pushOutbox() async {
    final unsynced = await _db.syncOutboxDao.getUnsynced();
    if (unsynced.isEmpty) return 0;

    int pushedCount = 0;

    // Group outbox operations by table to perform bulk upserts
    final Map<String, List<SyncOutboxData>> grouped = {};
    for (final op in unsynced) {
      grouped.putIfAbsent(op.entityTable, () => []).add(op);
    }

    for (final entry in grouped.entries) {
      final table = entry.key;
      final ops = entry.value;

      final rowsToPush = <Map<String, dynamic>>[];
      final successOps = <SyncOutboxData>[];

      for (final op in ops) {
        final cloudRow = _mapOutboxToCloud(op, _userId);
        if (cloudRow != null) {
          rowsToPush.add(cloudRow);
          successOps.add(op);
        }
      }

      if (rowsToPush.isNotEmpty) {
        // Upsert to Supabase
        await _client.from(table).upsert(rowsToPush, onConflict: 'id');

        // Mark outbox operations as synced
        for (final op in successOps) {
          await _db.syncOutboxDao.markSynced(op.id);
        }
        pushedCount += rowsToPush.length;
      }
    }

    // Clean up synced outbox records to avoid table growth
    await _db.syncOutboxDao.deleteSynced();

    return pushedCount;
  }

  Map<String, dynamic>? _mapOutboxToCloud(SyncOutboxData op, String userId) {
    try {
      final data = jsonDecode(op.serializedData);
      switch (op.entityTable) {
        case 'tasks':
          final t = Task.fromJson(data);
          return CloudMappers.taskToCloud(t, userId, SupabaseConfig.deviceId);
        case 'focus_sessions':
          final s = FocusSession.fromJson(data);
          return CloudMappers.focusSessionToCloud(s, userId, SupabaseConfig.deviceId);
        case 'xp_ledger':
          final e = XpLedgerEntry.fromJson(data);
          return CloudMappers.xpLedgerToCloud(e, userId);
        case 'scroll_logs':
          final l = ScrollLog.fromJson(data);
          return CloudMappers.scrollLogToCloud(l, userId, SupabaseConfig.deviceId);
        case 'energy_checkins':
          final c = EnergyCheckIn.fromJson(data);
          return CloudMappers.energyCheckInToCloud(c, userId, SupabaseConfig.deviceId);
        case 'daily_plans':
          final p = DailyPlan.fromJson(data);
          return CloudMappers.dailyPlanToCloud(p, userId, SupabaseConfig.deviceId);
        case 'daily_reports':
          final r = DailyReport.fromJson(data);
          return CloudMappers.dailyReportToCloud(r, userId);
        case 'achievements':
          final a = Achievement.fromJson(data);
          return CloudMappers.achievementToCloud(a, userId);
        case 'unlock_attempts':
          final u = UnlockAttempt.fromJson(data);
          return CloudMappers.unlockAttemptToCloud(u, userId);
      }
    } catch (e) {
      debugPrint('Error mapping outbox to cloud: $e');
    }
    return null;
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Sync result representation
class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;
  final bool isPaused;

  SyncResult({required this.pushed, required this.pulled, required this.errors, this.isPaused = false});

  bool get hasErrors => errors.isNotEmpty;
  bool get isClean => !hasErrors && (pushed > 0 || pulled > 0);
}
