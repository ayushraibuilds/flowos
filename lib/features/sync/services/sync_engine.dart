import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../data/local/database/app_database.dart';
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
  int _syncGeneration = 0;
  String? _activeUserId;

  SyncEngine(this._client, this._db);

  String get _userId => _client.auth.currentUser!.id;
  bool get isAuthenticated => _client.auth.currentUser != null;

  // ─── Error Taxonomy ──────────────────────────────────────────────────

  SyncErrorKind _classifyError(Object e) {
    if (e is AuthException) return SyncErrorKind.auth;
    final msg = e.toString().toLowerCase();
    if (msg.contains('401') ||
        msg.contains('unauthorized') ||
        msg.contains('jwt') ||
        msg.contains('invalid_token')) {
      return SyncErrorKind.auth;
    }
    if (msg.contains('socketexception') ||
        msg.contains('timeoutexception') ||
        msg.contains('clientexception') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('offline') ||
        msg.contains('timeout') ||
        msg.contains('500') ||
        msg.contains('502') ||
        msg.contains('503') ||
        msg.contains('504')) {
      return SyncErrorKind.retryable;
    }
    return SyncErrorKind.terminal;
  }

  // ─── Watermark Cursors ───────────────────────────────────────────────

  Future<Map<String, String>?> _getCursor(String table) async {
    final prefs = await SharedPreferences.getInstance();
    final updatedAt = prefs.getString(
      'flowos_sync_cursor_v2_${_userId}_${table}_updated_at',
    );
    final id = prefs.getString('flowos_sync_cursor_v2_${_userId}_${table}_id');
    if (updatedAt == null || id == null) return null;
    return {'updated_at': updatedAt, 'id': id};
  }

  Future<void> _setCursor(String table, String updatedAt, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'flowos_sync_cursor_v2_${_userId}_${table}_updated_at',
      updatedAt,
    );
    await prefs.setString('flowos_sync_cursor_v2_${_userId}_${table}_id', id);
  }

  // ─── Full Sync ─────────────────────────────────────────────────────

  /// Full bidirectional sync. Pulls newest changes from cursors, then pushes unsynced outbox.
  Future<SyncResult> fullSync() async {
    if (!SupabaseConfig.isConfigured || !isAuthenticated) {
      return SyncResult(
        pushed: 0,
        pulled: 0,
        errors: ['Supabase not configured or not authenticated'],
        isPaused: false,
        errorKind: SyncErrorKind.auth,
      );
    }

    final currentUserId = _userId;
    if (_activeUserId != null && _activeUserId != currentUserId) {
      cancelSync();
    }

    if (_isSyncing) {
      _syncRequested = true;
      return SyncResult(pushed: 0, pulled: 0, errors: [], isPaused: false);
    }

    _isSyncing = true;
    _syncRequested = false;
    _activeUserId = currentUserId;
    final gen = ++_syncGeneration;

    int pushedCount = 0;
    int pulledCount = 0;
    final List<String> errors = [];
    SyncErrorKind overallErrorKind = SyncErrorKind.none;
    String? failedTable;

    final tables = [
      'tasks',
      'focus_sessions',
      'daily_plans',
      'daily_reports',
      'scroll_logs',
      'energy_checkins',
      'achievements',
      'daily_scores',
      'xp_ledger',
      'unlock_attempts',
    ];

    try {
      // 1. Pull changes table by table using cursors
      for (final table in tables) {
        if (_syncGeneration != gen) {
          return SyncResult(
            pushed: pushedCount,
            pulled: pulledCount,
            errors: ['Sync cancelled'],
            isCancelled: true,
          );
        }

        try {
          pulledCount += await _pullTable(table, gen);
        } catch (e) {
          final kind = _classifyError(e);
          errors.add('$table pull error: $e');
          failedTable = table;
          if (overallErrorKind == SyncErrorKind.none) {
            overallErrorKind = kind;
          }
          if (kind == SyncErrorKind.auth) {
            break;
          }
        }
      }

      // 2. Push unacknowledged outbox operations
      if (_syncGeneration == gen && overallErrorKind != SyncErrorKind.auth) {
        try {
          pushedCount += await _pushOutbox(gen);
        } catch (e) {
          final kind = _classifyError(e);
          errors.add('Outbox push error: $e');
          if (overallErrorKind == SyncErrorKind.none) {
            overallErrorKind = kind;
          }
        }
      }
    } finally {
      _isSyncing = false;
    }

    if (_syncGeneration != gen) {
      return SyncResult(
        pushed: pushedCount,
        pulled: pulledCount,
        errors: ['Sync cancelled'],
        isCancelled: true,
      );
    }

    if (_syncRequested && overallErrorKind == SyncErrorKind.none) {
      final nextResult = await fullSync();
      return SyncResult(
        pushed: pushedCount + nextResult.pushed,
        pulled: pulledCount + nextResult.pulled,
        errors: [...errors, ...nextResult.errors],
        isPaused: false,
        isCancelled: nextResult.isCancelled,
        errorKind: nextResult.errorKind,
        failedTable: nextResult.failedTable ?? failedTable,
      );
    }

    return SyncResult(
      pushed: pushedCount,
      pulled: pulledCount,
      errors: errors,
      isPaused: false,
      errorKind: overallErrorKind,
      failedTable: failedTable,
    );
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

  // ═══════════════════════════════════════════════════════════════
  // PULL (Server → Local)
  // ═══════════════════════════════════════════════════════════════

  Future<int> _pullTable(String table, int gen) async {
    int pulledCount = 0;
    bool hasMore = true;

    while (hasMore) {
      if (_syncGeneration != gen) break;

      final cursor = await _getCursor(table);
      var query = _client.from(table).select();

      final sortCol = (table == 'xp_ledger' || table == 'unlock_attempts')
          ? 'created_at'
          : 'updated_at';

      if (cursor != null) {
        final cTime = cursor['updated_at']!;
        final cId = cursor['id']!;
        query = query.or(
          '$sortCol.gt.$cTime,and($sortCol.eq.$cTime,id.gt.$cId)',
        );
      }

      final List<dynamic> data = await query
          .order(sortCol, ascending: true)
          .order('id', ascending: true)
          .limit(100);

      if (data.isEmpty) {
        hasMore = false;
        break;
      }

      String? pageMaxTime;
      String? pageMaxId;

      for (final row in data) {
        if (_syncGeneration != gen) break;

        final id = row['id'] as String;
        final serverTime = row[sortCol] as String;

        // Process row
        await _applyRowFromSync(table, row);

        pageMaxTime = serverTime;
        pageMaxId = id;
        pulledCount++;
      }

      if (_syncGeneration != gen) break;

      // Update cursor watermark ONLY after page successfully completes
      if (pageMaxTime != null && pageMaxId != null) {
        await _setCursor(table, pageMaxTime, pageMaxId);
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
        } else if (_shouldUpdateLocal(local.updatedAt, row)) {
          await _db.tasksDao.updateTaskFromSync(server);
        }
        break;

      case 'focus_sessions':
        final server = CloudMappers.focusSessionFromCloud(row);
        final local = await _db.focusSessionsDao.getById(id);
        if (local == null) {
          await _db.focusSessionsDao.insertSessionFromSync(server);
        } else if (_shouldUpdateLocal(local.updatedAt, row)) {
          await _db.focusSessionsDao.updateSessionFromSync(server);
        }
        break;

      case 'daily_plans':
        final server = CloudMappers.dailyPlanFromCloud(row);
        final local = await _db.dailyPlansDao.getById(id);
        if (local == null) {
          await _db.dailyPlansDao.insertPlanFromSync(server);
        } else if (_shouldUpdateLocal(local.updatedAt, row)) {
          await _db.dailyPlansDao.updatePlanFromSync(server);
        }
        break;

      case 'daily_reports':
        final server = CloudMappers.dailyReportFromCloud(row);
        final local = await _db.dailyReportsDao.getById(id);
        if (local == null) {
          await _db.dailyReportsDao.insertReportFromSync(server);
        } else if (_shouldUpdateLocal(local.updatedAt, row)) {
          await _db.dailyReportsDao.updateReportFromSync(server);
        }
        break;

      case 'scroll_logs':
        final server = CloudMappers.scrollLogFromCloud(row);
        final local = await _db.scrollLogsDao.getById(id);
        if (local == null) {
          await _db.scrollLogsDao.insertLogFromSync(server);
        } else if (_shouldUpdateLocal(local.updatedAt, row)) {
          await _db.scrollLogsDao.updateLogFromSync(server);
        }
        break;

      case 'energy_checkins':
        final server = CloudMappers.energyCheckInFromCloud(row);
        final local = await _db.energyCheckInsDao.getById(id);
        if (local == null) {
          await _db.energyCheckInsDao.insertCheckInFromSync(server);
        } else if (_shouldUpdateLocal(local.updatedAt, row)) {
          await _db.energyCheckInsDao.updateCheckInFromSync(server);
        }
        break;

      case 'achievements':
        final server = CloudMappers.achievementFromCloud(row);
        final local = await _db.achievementsDao.getById(id);
        if (local == null) {
          await _db.achievementsDao.insertAchievementFromSync(server);
        } else if (_shouldUpdateLocal(local.updatedAt, row)) {
          await _db.achievementsDao.updateAchievementFromSync(server);
        }
        break;

      case 'daily_scores':
        final server = CloudMappers.dailyScoreFromCloud(row);
        final local = await _db.dailyScoresDao.getById(id);
        if (local == null) {
          await _db.dailyScoresDao.insertScoreFromSync(server);
        } else if (_shouldUpdateLocal(local.computedAt, row)) {
          await _db.dailyScoresDao.updateScoreFromSync(server);
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

  bool _shouldUpdateLocal(
    DateTime localUpdatedAt,
    Map<String, dynamic> serverRow,
  ) {
    final serverUpdated = DateTime.parse(serverRow['updated_at'] as String);
    if (serverUpdated.isAfter(localUpdatedAt)) return true;
    if (serverUpdated.isAtSameMomentAs(localUpdatedAt)) {
      final serverDev = serverRow['device_id'] as String? ?? '';
      return serverDev.compareTo(SupabaseConfig.deviceId) > 0;
    }
    return false;
  }

  Future<void> claimLocalDataIfNeeded(String targetUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final claimedBy = prefs.getString('flowos_account_claimed_by');
    if (claimedBy == null) {
      await _db.syncOutboxDao.claimLocalOutbox(targetUserId);
      await prefs.setString('flowos_account_claimed_by', targetUserId);
    }
  }

  void cancelSync() {
    _debounceTimer?.cancel();
    _syncGeneration++;
    _isSyncing = false;
    _syncRequested = false;
  }

  // ═══════════════════════════════════════════════════════════════
  // PUSH (Local → Server)
  // ═══════════════════════════════════════════════════════════════

  Future<int> _pushOutbox(int gen) async {
    final currentUserId = _userId;
    _db.setActiveOwnerId(currentUserId);
    await claimLocalDataIfNeeded(currentUserId);

    if (await _db.syncOutboxDao.hasUnsyncedForOtherOwner(currentUserId)) {
      debugPrint(
        '⚠️ Sync engine: Unsynced outbox operations for another identity exist. Isolating push to $currentUserId.',
      );
    }

    final unsynced = await _db.syncOutboxDao.getUnsyncedForOwner(currentUserId);
    if (unsynced.isEmpty) return 0;

    int pushedCount = 0;

    // Group outbox operations by table to perform bulk upserts
    final Map<String, List<SyncOutboxData>> grouped = {};
    for (final op in unsynced) {
      grouped.putIfAbsent(op.entityTable, () => []).add(op);
    }

    for (final entry in grouped.entries) {
      if (_syncGeneration != gen) break;

      final table = entry.key;
      final ops = entry.value;

      final rowsToPush = <Map<String, dynamic>>[];
      final successOps = <SyncOutboxData>[];

      for (final op in ops) {
        if (_syncGeneration != gen) break;
        final cloudRow = _mapOutboxToCloud(op, currentUserId);
        if (cloudRow != null) {
          rowsToPush.add(cloudRow);
          successOps.add(op);
        } else {
          // Terminal row mapping error — mark as synced to prevent infinite outbox retry loop
          await _db.syncOutboxDao.markSynced(op.id);
        }
      }

      if (rowsToPush.isNotEmpty && _syncGeneration == gen) {
        // Upsert to Supabase
        await _client.from(table).upsert(rowsToPush, onConflict: 'id');

        if (_syncGeneration == gen) {
          // Mark outbox operations as synced
          for (final op in successOps) {
            await _db.syncOutboxDao.markSynced(op.id);
          }
          pushedCount += rowsToPush.length;
        }
      }
    }

    if (_syncGeneration == gen) {
      // Clean up synced outbox records to avoid table growth
      await _db.syncOutboxDao.deleteSynced();
    }

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
          return CloudMappers.focusSessionToCloud(
            s,
            userId,
            SupabaseConfig.deviceId,
          );
        case 'xp_ledger':
          final e = XpLedgerEntry.fromJson(data);
          return CloudMappers.xpLedgerToCloud(e, userId);
        case 'scroll_logs':
          final l = ScrollLog.fromJson(data);
          return CloudMappers.scrollLogToCloud(
            l,
            userId,
            SupabaseConfig.deviceId,
          );
        case 'energy_checkins':
          final c = EnergyCheckIn.fromJson(data);
          return CloudMappers.energyCheckInToCloud(
            c,
            userId,
            SupabaseConfig.deviceId,
          );
        case 'daily_plans':
          final p = DailyPlan.fromJson(data);
          return CloudMappers.dailyPlanToCloud(
            p,
            userId,
            SupabaseConfig.deviceId,
          );
        case 'daily_reports':
          final r = DailyReport.fromJson(data);
          return CloudMappers.dailyReportToCloud(r, userId);
        case 'achievements':
          final a = Achievement.fromJson(data);
          return CloudMappers.achievementToCloud(a, userId);
        case 'daily_scores':
          final ds = DailyScore.fromJson(data);
          return CloudMappers.dailyScoreToCloud(
            ds,
            userId,
            SupabaseConfig.deviceId,
          );
        case 'unlock_attempts':
          final u = UnlockAttempt.fromJson(data);
          return CloudMappers.unlockAttemptToCloud(u, userId);
      }
    } catch (e) {
      debugPrint('Terminal mapping error for outbox row ${op.id}: $e');
    }
    return null;
  }

  void dispose() {
    cancelSync();
  }
}

enum SyncErrorKind { none, auth, retryable, terminal }

/// Sync result representation
class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;
  final bool isPaused;
  final bool isCancelled;
  final SyncErrorKind errorKind;
  final String? failedTable;

  SyncResult({
    required this.pushed,
    required this.pulled,
    required this.errors,
    this.isPaused = false,
    this.isCancelled = false,
    this.errorKind = SyncErrorKind.none,
    this.failedTable,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isClean => !hasErrors && !isCancelled && (pushed > 0 || pulled > 0);
  bool get isAuthError => errorKind == SyncErrorKind.auth;
  bool get isRetryable => errorKind == SyncErrorKind.retryable;
}
