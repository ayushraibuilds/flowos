import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/local/tables/focus_sessions_table.dart';

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
/// 2. After every mutation (push only, debounced 300ms)
/// 3. On network reconnect (full sync)
class SyncEngine {
  final SupabaseClient _client;
  final AppDatabase _db;
  bool _isSyncing = false;
  Timer? _debounceTimer;

  /// Key used to store last sync timestamp in SharedPreferences.
  static const _lastSyncKey = 'flowos_last_sync_at';

  SyncEngine(this._client, this._db);

  String get _userId => _client.auth.currentUser!.id;
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Get last successful sync timestamp.
  Future<DateTime> _getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastSyncKey);
    if (ms == null) return DateTime(2000); // Never synced → pull everything
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Update last sync timestamp.
  Future<void> _setLastSyncAt(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, dt.millisecondsSinceEpoch);
  }

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
      pulled += await _pullDailyReports();

      // Push (local → server)
      pushed += await _pushTasks();
      pushed += await _pushSessions();
      pushed += await _pushXpLedger();
      pushed += await _pushScrollLogs();
      pushed += await _pushEnergy();
      pushed += await _pushPlans();
      pushed += await _pushAchievements();
      pushed += await _pushDailyReports();

      // Mark sync time
      await _setLastSyncAt(DateTime.now());

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
      await _pushDailyReports();
    } catch (e) {
      debugPrint('Push error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PULL (Server → Local)
  // ═══════════════════════════════════════════════════════════════

  Future<int> _pullTasks() async {
    try {
      final data = await _client
          .from('tasks')
          .select()
          .order('updated_at', ascending: false)
          .limit(500);

      int count = 0;
      for (final row in (data as List)) {
        final serverId = row['id'] as String;
        final serverUpdatedAt = DateTime.parse(row['updated_at']);
        final local = await _db.tasksDao.getById(serverId);

        if (local == null) {
          // New from server → insert locally
          await _db.tasksDao.insertTask(TasksCompanion(
            id: Value(serverId),
            title: Value(row['title'] ?? ''),
            energyLevel: Value(_parseEnergyLevel(row['energy_level'])),
            estimatedMinutes: Value(row['estimated_minutes'] ?? 25),
            category: Value(_parseCategory(row['category'])),
            isMIT: Value(row['is_mit'] ?? false),
            isCompleted: Value(row['is_completed'] ?? false),
            completedAt: Value(row['completed_at'] != null
                ? DateTime.parse(row['completed_at'])
                : null),
            sortOrder: Value(row['sort_order'] ?? 0),
            createdAt: Value(DateTime.parse(row['created_at'])),
            updatedAt: Value(serverUpdatedAt),
            deletedAt: Value(row['deleted_at'] != null
                ? DateTime.parse(row['deleted_at'])
                : null),
          ));
          count++;
        } else if (serverUpdatedAt.isAfter(local.updatedAt)) {
          // Server is newer → update local
          await _db.tasksDao.updateTask(TasksCompanion(
            id: Value(serverId),
            title: Value(row['title'] ?? local.title),
            energyLevel: Value(_parseEnergyLevel(row['energy_level'])),
            estimatedMinutes: Value(row['estimated_minutes'] ?? local.estimatedMinutes),
            isMIT: Value(row['is_mit'] ?? local.isMIT),
            isCompleted: Value(row['is_completed'] ?? local.isCompleted),
            completedAt: Value(row['completed_at'] != null
                ? DateTime.parse(row['completed_at'])
                : local.completedAt),
            sortOrder: Value(row['sort_order'] ?? local.sortOrder),
            updatedAt: Value(serverUpdatedAt),
            deletedAt: Value(row['deleted_at'] != null
                ? DateTime.parse(row['deleted_at'])
                : local.deletedAt),
          ));
          count++;
        }
        // If local is newer or same → skip (will be pushed)
      }
      return count;
    } catch (e) {
      debugPrint('Pull tasks error: $e');
      return 0;
    }
  }

  Future<int> _pullSessions() async {
    try {
      final lastSync = await _getLastSyncAt();
      final data = await _client
          .from('focus_sessions')
          .select()
          .gte('updated_at', lastSync.toIso8601String())
          .order('updated_at', ascending: false)
          .limit(500);

      int count = 0;
      for (final row in (data as List)) {
        final serverId = row['id'] as String;
        // Check if exists locally
        final existing = await _db.focusSessionsDao.getById(serverId);
        final exists = existing != null;

        if (!exists) {
          await _db.focusSessionsDao.insertSession(FocusSessionsCompanion(
            id: Value(serverId),
            taskId: Value(row['task_id']),
            sessionType: Value(_parseSessionType(row['session_type'])),
            durationMinutes: Value(row['duration_minutes']),
            actualMinutes: Value(row['actual_minutes'] ?? 0),
            xpEarned: Value(row['xp_earned'] ?? 0),
            qualityScore: Value(row['quality_score'] ?? ''),
            startedAt: Value(DateTime.parse(row['started_at'])),
            completedAt: Value(row['completed_at'] != null
                ? DateTime.parse(row['completed_at'])
                : null),
          ));
          count++;
        }
      }
      return count;
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

      int count = 0;
      for (final row in (data as List)) {
        final serverId = row['id'] as String;
        final local = await _db.dailyPlansDao.getById(serverId);

        if (local == null) {
          await _db.dailyPlansDao.insertPlan(DailyPlansCompanion(
            id: Value(serverId),
            date: Value(DateTime.parse(row['plan_date'])),
            mit1Id: Value(row['mit_1_id']),
            mit2Id: Value(row['mit_2_id']),
            mit3Id: Value(row['mit_3_id']),
            morningEnergy: Value(row['morning_energy'] ?? 3),
            scrollBudgetMinutes: Value(row['scroll_budget_minutes'] ?? 30),
            intentionCompleted: Value(row['intention_completed'] ?? false),
            shutdownCompleted: Value(row['shutdown_completed'] ?? false),
            intentionNote: Value(row['intention_note']),
          ));
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Pull plans error: $e');
      return 0;
    }
  }

  Future<int> _pullAchievements() async {
    try {
      final data = await _client.from('achievements').select();

      int count = 0;
      for (final row in (data as List)) {
        final serverId = row['id'] as String;
        final local = await _db.achievementsDao.getById(serverId);

        if (local == null) {
          await _db.achievementsDao.insertAchievement(AchievementsCompanion(
            id: Value(serverId),
            achievementKey: Value(row['achievement_key']),
            unlockedAt: Value(DateTime.parse(row['unlocked_at'])),
          ));
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Pull achievements error: $e');
      return 0;
    }
  }

  Future<int> _pullDailyReports() async {
    try {
      final data = await _client
          .from('daily_reports')
          .select()
          .order('date', ascending: false)
          .limit(30);

      int count = 0;
      for (final row in (data as List)) {
        final serverId = row['id'] as String;
        final local = await (_db.select(_db.dailyReports)..where((r) => r.id.equals(serverId))).getSingleOrNull();

        if (local == null) {
          await _db.dailyReportsDao.upsertReport(DailyReportsCompanion(
            id: Value(serverId),
            date: Value(DateTime.parse(row['date'])),
            reportJson: Value(row['report_json']),
            dailyScore: Value(row['daily_score'] ?? 0),
            xpEarnedToday: Value(row['xp_earned_today'] ?? 0),
            attentionCostToday: Value(row['attention_cost_today'] ?? 0),
            promptVersion: Value(row['prompt_version']),
            generatedAt: Value(DateTime.parse(row['generated_at'])),
          ));
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Pull daily reports error: $e');
      return 0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PUSH (Local → Server)
  // ═══════════════════════════════════════════════════════════════

  Future<int> _pushTasks() async {
    try {
      final lastSync = await _getLastSyncAt();
      // Include soft-deleted tasks too — they need to sync their deleted_at
      final toPush = await _db.tasksDao.getModifiedSince(lastSync);

      if (toPush.isEmpty) return 0;

      final rows = toPush.map((t) => {
        'id': t.id,
        'title': t.title,
        'energy_level': t.energyLevel.name,
        'estimated_minutes': t.estimatedMinutes,
        'category': t.category.name,
        'is_mit': t.isMIT,
        'is_completed': t.isCompleted,
        'completed_at': t.completedAt?.toIso8601String(),
        'sort_order': t.sortOrder,
        'friction_score': t.frictionScore,
        'parent_task_id': t.parentTaskId,
        'recurrence_rule': t.recurrenceRule?.name,
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': t.updatedAt.toIso8601String(),
        'deleted_at': t.deletedAt?.toIso8601String(),
      }).toList();

      await _upsertBatch('tasks', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push tasks error: $e');
      return 0;
    }
  }

  Future<int> _pushSessions() async {
    try {
      final lastSync = await _getLastSyncAt();
      final sessions = await _db.focusSessionsDao.getModifiedSince(lastSync);

      if (sessions.isEmpty) return 0;

      final rows = sessions.map((s) => {
        'id': s.id,
        'task_id': s.taskId,
        'session_type': s.sessionType.name,
        'duration_minutes': s.durationMinutes,
        'actual_minutes': s.actualMinutes,
        'pause_count': s.pauseCount,
        'app_background_count': s.appBackgroundCount,
        'ambient_sound': s.ambientSound,
        'energy_before': s.energyBefore,
        'energy_after': s.energyAfter,
        'quality_score': s.qualityScore,
        'xp_earned': s.xpEarned,
        'started_at': s.startedAt.toIso8601String(),
        'completed_at': s.completedAt?.toIso8601String(),
      }).toList();

      await _upsertBatch('focus_sessions', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push sessions error: $e');
      return 0;
    }
  }

  /// XP Ledger — append-only. Only push entries not yet synced.
  Future<int> _pushXpLedger() async {
    try {
      final lastSync = await _getLastSyncAt();
      final entries = await _db.xpLedgerDao.getByDateRange(
        lastSync,
        DateTime.now().add(const Duration(days: 1)),
      );

      if (entries.isEmpty) return 0;

      final rows = entries.map((e) => {
        'id': e.id,
        'action_type': e.actionType.name,
        'points_delta': e.pointsDelta,
        'source_entity_id': e.sourceEntityId,
        'explanation': e.explanation,
        'is_reversible': e.isReversible,
        'prompt_version': e.promptVersion,
        'created_at': e.timestamp.toIso8601String(),
      }).toList();

      await _appendBatch('xp_ledger', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push XP ledger error: $e');
      return 0;
    }
  }

  Future<int> _pushScrollLogs() async {
    try {
      final lastSync = await _getLastSyncAt();
      final logs = await _db.scrollLogsDao.getModifiedSince(lastSync);

      if (logs.isEmpty) return 0;

      final rows = logs.map((l) => {
        'id': l.id,
        'app_name': l.appName,
        'duration_minutes': l.durationMinutes,
        'daily_score_impact': l.dailyScoreImpact,
        'logged_at': l.timestamp.toIso8601String(),
        'recovery_action_taken': l.recoveryActionTaken,
        'recovery_action_type': l.recoveryActionType,
      }).toList();

      await _appendBatch('scroll_logs', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push scroll logs error: $e');
      return 0;
    }
  }

  Future<int> _pushEnergy() async {
    try {
      final lastSync = await _getLastSyncAt();
      final checkins = await _db.energyCheckInsDao.getModifiedSince(lastSync);

      if (checkins.isEmpty) return 0;

      final rows = checkins.map((c) => {
        'id': c.id,
        'energy_level': c.value,
        'time_of_day': c.timeOfDay.name,
        'checked_in_at': c.date.toIso8601String(),
      }).toList();

      await _appendBatch('energy_checkins', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push energy error: $e');
      return 0;
    }
  }

  Future<int> _pushPlans() async {
    try {
      final lastSync = await _getLastSyncAt();
      final plans = await _db.dailyPlansDao.getModifiedSince(lastSync);

      if (plans.isEmpty) return 0;

      final rows = plans.map((p) => {
        'id': p.id,
        'plan_date': DateTime(p.date.year, p.date.month, p.date.day)
            .toIso8601String()
            .split('T')[0],
        'mit_1_id': p.mit1Id,
        'mit_2_id': p.mit2Id,
        'mit_3_id': p.mit3Id,
        'morning_energy': p.morningEnergy,
        'scroll_budget_minutes': p.scrollBudgetMinutes,
        'intention_completed': p.intentionCompleted,
        'shutdown_completed': p.shutdownCompleted,
        'intention_note': p.intentionNote,
      }).toList();

      await _upsertBatch('daily_plans', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push plans error: $e');
      return 0;
    }
  }

  Future<int> _pushAchievements() async {
    try {
      final lastSync = await _getLastSyncAt();
      final achievements = await _db.achievementsDao.getModifiedSince(lastSync);

      if (achievements.isEmpty) return 0;

      final rows = achievements.map((a) => {
        'id': a.id,
        'achievement_key': a.achievementKey,
        'unlocked_at': a.unlockedAt.toIso8601String(),
      }).toList();

      await _appendBatch('achievements', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push achievements error: $e');
      return 0;
    }
  }

  Future<int> _pushDailyReports() async {
    try {
      final lastSync = await _getLastSyncAt();
      final reports = await _db.dailyReportsDao.getModifiedSince(lastSync);

      if (reports.isEmpty) return 0;

      final rows = reports.map((r) => {
        'id': r.id,
        'date': DateTime(r.date.year, r.date.month, r.date.day)
            .toIso8601String()
            .split('T')[0],
        'report_json': r.reportJson,
        'daily_score': r.dailyScore,
        'xp_earned_today': r.xpEarnedToday,
        'attention_cost_today': r.attentionCostToday,
        'prompt_version': r.promptVersion,
        'generated_at': r.generatedAt.toIso8601String(),
      }).toList();

      await _upsertBatch('daily_reports', rows);
      return rows.length;
    } catch (e) {
      debugPrint('Push daily reports error: $e');
      return 0;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────

  /// Upsert a batch of rows to Supabase table (for mutable entities).
  Future<void> _upsertBatch(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    for (final row in rows) {
      row['user_id'] = _userId;
      row['device_id'] = SupabaseConfig.deviceId;
    }

    await _client.from(table).upsert(rows, onConflict: 'id');
  }

  /// Append-only insert (for XP ledger, scroll logs, energy).
  /// Uses ignoreDuplicates to skip already-synced rows.
  Future<void> _appendBatch(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    for (final row in rows) {
      row['user_id'] = _userId;
    }

    // Insert with ignoreDuplicates — if id already exists, skip silently
    await _client.from(table).upsert(rows, onConflict: 'id', ignoreDuplicates: true);
  }

  // ─── Enum Parsers ─────────────────────────────────────────

  EnergyLevelColumn _parseEnergyLevel(String? val) => switch (val) {
    'deep' => EnergyLevelColumn.deep,
    'medium' => EnergyLevelColumn.medium,
    'light' => EnergyLevelColumn.light,
    _ => EnergyLevelColumn.medium,
  };

  TaskCategoryColumn _parseCategory(String? val) => switch (val) {
    'work' => TaskCategoryColumn.work,
    'personal' => TaskCategoryColumn.personal,
    'health' => TaskCategoryColumn.health,
    'learning' => TaskCategoryColumn.learning,
    'admin' => TaskCategoryColumn.admin,
    _ => TaskCategoryColumn.personal,
  };

  SessionTypeColumn _parseSessionType(String? val) => switch (val) {
    'pomodoro' => SessionTypeColumn.pomodoro,
    'deepWork' => SessionTypeColumn.deepWork,
    'custom' => SessionTypeColumn.custom,
    _ => SessionTypeColumn.pomodoro,
  };

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
