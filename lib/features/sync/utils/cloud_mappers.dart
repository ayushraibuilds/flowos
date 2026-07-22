import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/tasks_table.dart';
import '../../../data/local/tables/focus_sessions_table.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../data/local/tables/scroll_logs_table.dart';
import '../../../data/local/tables/energy_checkins_table.dart';

/// Centralized, type-safe mapping logic between Drift Database Entities and Supabase raw JSON objects.
class CloudMappers {
  // ─── Tasks Mapper ─────────────────────────────────────────────────────────

  static Map<String, dynamic> taskToCloud(Task t, String userId, String? deviceId) {
    return {
      'id': t.id,
      'user_id': userId,
      'title': t.title,
      'energy_level': t.energyLevel.name,
      'estimated_minutes': t.estimatedMinutes,
      'due_date': t.dueDate?.toIso8601String().substring(0, 10),
      'category': t.category.name,
      'is_mit': t.isMIT,
      'is_completed': t.isCompleted,
      'completed_at': t.completedAt?.toUtc().toIso8601String(),
      'sort_order': t.sortOrder,
      'recurrence_rule': t.recurrenceRule?.name,
      'parent_task_id': t.parentTaskId,
      'friction_score': t.frictionScore,
      'created_at': t.createdAt.toUtc().toIso8601String(),
      'updated_at': t.updatedAt.toUtc().toIso8601String(),
      'deleted_at': t.deletedAt?.toUtc().toIso8601String(),
      'device_id': deviceId,
    };
  }

  static TasksCompanion taskFromCloud(Map<String, dynamic> row) {
    return TasksCompanion(
      id: Value(row['id'] as String),
      title: Value(row['title'] as String? ?? ''),
      energyLevel: Value(_parseEnergyLevel(row['energy_level'])),
      estimatedMinutes: Value(row['estimated_minutes'] as int? ?? 25),
      dueDate: Value(row['due_date'] != null ? DateTime.parse(row['due_date'] as String) : null),
      category: Value(_parseCategory(row['category'])),
      isMIT: Value(row['is_mit'] as bool? ?? false),
      isCompleted: Value(row['is_completed'] as bool? ?? false),
      completedAt: Value(row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null),
      sortOrder: Value(row['sort_order'] as int? ?? 0),
      recurrenceRule: Value(_parseRecurrenceRule(row['recurrence_rule'])),
      parentTaskId: Value(row['parent_task_id'] as String?),
      frictionScore: Value((row['friction_score'] as num?)?.toInt() ?? 0),
      createdAt: Value(DateTime.parse(row['created_at'] as String)),
      updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
      deletedAt: Value(row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null),
    );
  }

  static EnergyLevelColumn _parseEnergyLevel(dynamic val) {
    if (val == null) return EnergyLevelColumn.medium;
    return EnergyLevelColumn.values.firstWhere(
      (e) => e.name == val.toString(),
      orElse: () => EnergyLevelColumn.medium,
    );
  }

  static TaskCategoryColumn _parseCategory(dynamic val) {
    if (val == null) return TaskCategoryColumn.personal;
    return TaskCategoryColumn.values.firstWhere(
      (e) => e.name == val.toString(),
      orElse: () => TaskCategoryColumn.personal,
    );
  }

  static RecurrenceRuleColumn? _parseRecurrenceRule(dynamic val) {
    if (val == null) return null;
    return RecurrenceRuleColumn.values.firstWhere(
      (e) => e.name == val.toString(),
      orElse: () => RecurrenceRuleColumn.daily,
    );
  }

  // ─── Focus Sessions Mapper ──────────────────────────────────────────────────

  static Map<String, dynamic> focusSessionToCloud(FocusSession s, String userId, String? deviceId) {
    return {
      'id': s.id,
      'user_id': userId,
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
      'started_at': s.startedAt.toUtc().toIso8601String(),
      'completed_at': s.completedAt?.toUtc().toIso8601String(),
      'created_at': s.createdAt.toUtc().toIso8601String(),
      'updated_at': s.updatedAt.toUtc().toIso8601String(),
      'deleted_at': s.deletedAt?.toUtc().toIso8601String(),
      'garden_seed_kind': s.gardenSeedKind,
      'garden_variant': s.gardenVariant,
      'garden_seed_emoji': s.gardenSeedEmoji,
      'device_id': deviceId,
    };
  }

  static FocusSessionsCompanion focusSessionFromCloud(Map<String, dynamic> row) {
    return FocusSessionsCompanion(
      id: Value(row['id'] as String),
      taskId: Value(row['task_id'] as String?),
      sessionType: Value(_parseSessionType(row['session_type'])),
      durationMinutes: Value(row['duration_minutes'] as int? ?? 25),
      actualMinutes: Value(row['actual_minutes'] as int? ?? 0),
      pauseCount: Value(row['pause_count'] as int? ?? 0),
      appBackgroundCount: Value(row['app_background_count'] as int? ?? 0),
      ambientSound: Value(row['ambient_sound'] as String?),
      energyBefore: Value(row['energy_before'] as int?),
      energyAfter: Value(row['energy_after'] as int?),
      qualityScore: Value(row['quality_score'] as String? ?? ''),
      xpEarned: Value(row['xp_earned'] as int? ?? 0),
      startedAt: Value(DateTime.parse(row['started_at'] as String)),
      completedAt: Value(row['completed_at'] != null ? DateTime.parse(row['completed_at'] as String) : null),
      createdAt: Value(DateTime.parse(row['created_at'] as String)),
      updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
      deletedAt: Value(row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null),
      gardenSeedKind: Value(row['garden_seed_kind'] as String?),
      gardenVariant: Value(row['garden_variant'] as int?),
      gardenSeedEmoji: Value(row['garden_seed_emoji'] as String?),
    );
  }

  static SessionTypeColumn _parseSessionType(dynamic val) {
    if (val == null) return SessionTypeColumn.pomodoro;
    return SessionTypeColumn.values.firstWhere(
      (e) => e.name == val.toString(),
      orElse: () => SessionTypeColumn.pomodoro,
    );
  }

  // ─── XP Ledger Mapper ─────────────────────────────────────────────────────

  static Map<String, dynamic> xpLedgerToCloud(XpLedgerEntry e, String userId) {
    return {
      'id': e.id,
      'user_id': userId,
      'action_type': e.actionType.name,
      'points_delta': e.pointsDelta,
      'source_entity_id': e.sourceEntityId,
      'explanation': e.explanation,
      'is_reversible': e.isReversible,
      'prompt_version': e.promptVersion,
      'created_at': e.timestamp.toUtc().toIso8601String(),
    };
  }

  static XpLedgerEntriesCompanion xpLedgerFromCloud(Map<String, dynamic> row) {
    return XpLedgerEntriesCompanion(
      id: Value(row['id'] as String),
      actionType: Value(_parseXpActionType(row['action_type'])),
      pointsDelta: Value(row['points_delta'] as int? ?? 0),
      sourceEntityId: Value(row['source_entity_id'] as String?),
      explanation: Value(row['explanation'] as String? ?? ''),
      isReversible: Value(row['is_reversible'] as bool? ?? false),
      promptVersion: Value(row['prompt_version'] as int?),
      timestamp: Value(DateTime.parse(row['created_at'] as String)),
    );
  }

  static XpActionTypeColumn _parseXpActionType(dynamic val) {
    if (val == null) return XpActionTypeColumn.taskComplete;
    return XpActionTypeColumn.values.firstWhere(
      (e) => e.name == val.toString(),
      orElse: () => XpActionTypeColumn.taskComplete,
    );
  }

  // ─── Scroll Logs Mapper ────────────────────────────────────────────────────

  static Map<String, dynamic> scrollLogToCloud(ScrollLog l, String userId, String? deviceId) {
    return {
      'id': l.id,
      'user_id': userId,
      'app_name': l.appName,
      'duration_minutes': l.durationMinutes,
      'daily_score_impact': l.dailyScoreImpact,
      'logged_at': l.timestamp.toUtc().toIso8601String(),
      'recovery_action_taken': l.recoveryActionTaken,
      'recovery_action_type': l.recoveryActionType,
      'intent': l.intent,
      'was_timeboxed': l.wasTimeboxed,
      'planned_minutes': l.plannedMinutes,
      'created_at': l.timestamp.toUtc().toIso8601String(),
      'updated_at': l.updatedAt.toUtc().toIso8601String(),
      'deleted_at': l.deletedAt?.toUtc().toIso8601String(),
      'device_id': deviceId,
    };
  }

  static ScrollLogsCompanion scrollLogFromCloud(Map<String, dynamic> row) {
    return ScrollLogsCompanion(
      id: Value(row['id'] as String),
      appName: Value(row['app_name'] as String? ?? ''),
      durationMinutes: Value(row['duration_minutes'] as int? ?? 0),
      dailyScoreImpact: Value(row['daily_score_impact'] as int? ?? 0),
      timestamp: Value(DateTime.parse(row['logged_at'] as String)),
      recoveryActionTaken: Value(row['recovery_action_taken'] as bool? ?? false),
      recoveryActionType: Value(row['recovery_action_type'] as String?),
      intent: Value(row['intent'] as String?),
      wasTimeboxed: Value(row['was_timeboxed'] as bool? ?? false),
      plannedMinutes: Value(row['planned_minutes'] as int?),
      updatedAt: Value(row['updated_at'] != null ? DateTime.parse(row['updated_at'] as String) : DateTime.parse(row['logged_at'] as String)),
      deletedAt: Value(row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null),
    );
  }

  // ─── Energy Check-ins Mapper ───────────────────────────────────────────────

  static Map<String, dynamic> energyCheckInToCloud(EnergyCheckIn c, String userId, String? deviceId) {
    return {
      'id': c.id,
      'user_id': userId,
      'energy_level': c.value,
      'time_of_day': c.timeOfDay.name,
      'checked_in_at': c.date.toUtc().toIso8601String(),
      'created_at': c.createdAt.toUtc().toIso8601String(),
      'updated_at': c.updatedAt.toUtc().toIso8601String(),
      'deleted_at': c.deletedAt?.toUtc().toIso8601String(),
      'device_id': deviceId,
    };
  }

  static EnergyCheckInsCompanion energyCheckInFromCloud(Map<String, dynamic> row) {
    return EnergyCheckInsCompanion(
      id: Value(row['id'] as String),
      value: Value(row['energy_level'] as int? ?? 3),
      timeOfDay: Value(_parseTimeOfDay(row['time_of_day'])),
      date: Value(DateTime.parse(row['checked_in_at'] as String)),
      createdAt: Value(row['created_at'] != null ? DateTime.parse(row['created_at'] as String) : DateTime.parse(row['checked_in_at'] as String)),
      updatedAt: Value(row['updated_at'] != null ? DateTime.parse(row['updated_at'] as String) : DateTime.parse(row['checked_in_at'] as String)),
      deletedAt: Value(row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null),
    );
  }

  static TimeOfDayColumn _parseTimeOfDay(dynamic val) {
    if (val == null) return TimeOfDayColumn.morning;
    return TimeOfDayColumn.values.firstWhere(
      (e) => e.name == val.toString(),
      orElse: () => TimeOfDayColumn.morning,
    );
  }

  // ─── Daily Plans Mapper ────────────────────────────────────────────────────

  static Map<String, dynamic> dailyPlanToCloud(DailyPlan p, String userId, String? deviceId) {
    return {
      'id': p.id,
      'user_id': userId,
      'plan_date': p.date.toIso8601String().substring(0, 10),
      'mit_1_id': p.mit1Id,
      'mit_2_id': p.mit2Id,
      'mit_3_id': p.mit3Id,
      'morning_energy': p.morningEnergy,
      'scroll_budget_minutes': p.scrollBudgetMinutes,
      'intention_completed': p.intentionCompleted,
      'shutdown_completed': p.shutdownCompleted,
      'intention_note': p.intentionNote,
      'created_at': p.createdAt.toUtc().toIso8601String(),
      'updated_at': p.updatedAt.toUtc().toIso8601String(),
      'deleted_at': p.deletedAt?.toUtc().toIso8601String(),
      'device_id': deviceId,
    };
  }

  static DailyPlansCompanion dailyPlanFromCloud(Map<String, dynamic> row) {
    return DailyPlansCompanion(
      id: Value(row['id'] as String),
      date: Value(DateTime.parse(row['plan_date'] as String)),
      mit1Id: Value(row['mit_1_id'] as String?),
      mit2Id: Value(row['mit_2_id'] as String?),
      mit3Id: Value(row['mit_3_id'] as String?),
      morningEnergy: Value(row['morning_energy'] as int? ?? 3),
      scrollBudgetMinutes: Value(row['scroll_budget_minutes'] as int? ?? 30),
      intentionCompleted: Value(row['intention_completed'] as bool? ?? false),
      shutdownCompleted: Value(row['shutdown_completed'] as bool? ?? false),
      intentionNote: Value(row['intention_note'] as String?),
      createdAt: Value(DateTime.parse(row['created_at'] as String)),
      updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
      deletedAt: Value(row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null),
    );
  }

  // ─── Daily Reports Mapper ──────────────────────────────────────────────────

  static Map<String, dynamic> dailyReportToCloud(DailyReport r, String userId) {
    return {
      'id': r.id,
      'user_id': userId,
      'date': r.date.toIso8601String().substring(0, 10),
      'report_json': r.reportJson is String ? jsonDecode(r.reportJson) : r.reportJson,
      'daily_score': r.dailyScore,
      'xp_earned_today': r.xpEarnedToday,
      'attention_cost_today': r.attentionCostToday,
      'prompt_version': r.promptVersion,
      'coverage_state': r.coverageState,
      'generated_at': r.generatedAt.toUtc().toIso8601String(),
      'updated_at': r.updatedAt.toUtc().toIso8601String(),
      'deleted_at': r.deletedAt?.toUtc().toIso8601String(),
    };
  }

  static DailyReportsCompanion dailyReportFromCloud(Map<String, dynamic> row) {
    final reportJsonRaw = row['report_json'];
    final reportJsonStr = reportJsonRaw is String ? reportJsonRaw : jsonEncode(reportJsonRaw);

    return DailyReportsCompanion(
      id: Value(row['id'] as String),
      date: Value(DateTime.parse(row['date'] as String)),
      reportJson: Value(reportJsonStr),
      dailyScore: Value(row['daily_score'] as int? ?? 0),
      xpEarnedToday: Value(row['xp_earned_today'] as int? ?? 0),
      attentionCostToday: Value(row['attention_cost_today'] as int? ?? 0),
      promptVersion: Value(row['prompt_version'] as int?),
      coverageState: Value(row['coverage_state'] as String?),
      generatedAt: Value(DateTime.parse(row['generated_at'] as String)),
      updatedAt: Value(DateTime.parse(row['updated_at'] as String)),
      deletedAt: Value(row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null),
    );
  }

  // ─── Achievements Mapper ───────────────────────────────────────────────────

  static Map<String, dynamic> achievementToCloud(Achievement a, String userId) {
    return {
      'id': a.id,
      'user_id': userId,
      'achievement_key': a.achievementKey,
      'unlocked_at': a.unlockedAt.toUtc().toIso8601String(),
      'created_at': a.unlockedAt.toUtc().toIso8601String(),
      'updated_at': a.updatedAt.toUtc().toIso8601String(),
      'deleted_at': a.deletedAt?.toUtc().toIso8601String(),
    };
  }

  static AchievementsCompanion achievementFromCloud(Map<String, dynamic> row) {
    return AchievementsCompanion(
      id: Value(row['id'] as String),
      achievementKey: Value(row['achievement_key'] as String? ?? ''),
      unlockedAt: Value(DateTime.parse(row['unlocked_at'] as String)),
      updatedAt: Value(row['updated_at'] != null ? DateTime.parse(row['updated_at'] as String) : DateTime.parse(row['unlocked_at'] as String)),
      deletedAt: Value(row['deleted_at'] != null ? DateTime.parse(row['deleted_at'] as String) : null),
    );
  }

  // ─── Unlock Attempts Mapper ────────────────────────────────────────────────

  static Map<String, dynamic> unlockAttemptToCloud(UnlockAttempt u, String userId) {
    return {
      'id': u.id,
      'user_id': userId,
      'platform': u.platform,
      'target': u.target,
      'level': u.level,
      'requested_break_minutes': u.requestedBreakMinutes,
      'intention': u.intention,
      'wait_outcome': u.waitOutcome,
      'session_id': u.sessionId,
      'timestamp': u.timestamp.toUtc().toIso8601String(),
    };
  }

  static UnlockAttemptsCompanion unlockAttemptFromCloud(Map<String, dynamic> row) {
    return UnlockAttemptsCompanion(
      id: Value(row['id'] as String),
      platform: Value(row['platform'] as String? ?? ''),
      target: Value(row['target'] as String? ?? ''),
      level: Value(row['level'] as String? ?? 'reflect'),
      requestedBreakMinutes: Value(row['requested_break_minutes'] as int? ?? 0),
      intention: Value(row['intention'] as String?),
      waitOutcome: Value(row['wait_outcome'] as String? ?? 'abandoned'),
      sessionId: Value(row['session_id'] as String?),
      timestamp: Value(DateTime.parse(row['timestamp'] as String)),
    );
  }

  // ─── Daily Scores Mapper ───────────────────────────────────────────────────

  static Map<String, dynamic> dailyScoreToCloud(DailyScore s, String userId, String? deviceId) {
    final dayStr = s.day.toIso8601String().substring(0, 10);
    return {
      'id': dayStr,
      'user_id': userId,
      'day': dayStr,
      'score': s.score,
      'grade': s.grade,
      'is_incomplete': s.isIncomplete,
      'available_weight': s.availableWeight,
      'scoring_version': s.scoringVersion,
      'focus_points': s.focusPoints,
      'intent_points': s.intentPoints,
      'attention_points': s.attentionPoints,
      'care_points': s.carePoints,
      'computed_at': s.computedAt.toUtc().toIso8601String(),
      'created_at': s.computedAt.toUtc().toIso8601String(),
      'updated_at': s.computedAt.toUtc().toIso8601String(),
      'device_id': deviceId,
    };
  }

  static DailyScoresCompanion dailyScoreFromCloud(Map<String, dynamic> row) {
    final dayDate = DateTime.parse(row['day'] as String);
    final startOfDay = DateTime(dayDate.year, dayDate.month, dayDate.day);
    return DailyScoresCompanion(
      day: Value(startOfDay),
      score: Value(row['score'] as int? ?? 0),
      grade: Value(row['grade'] as String?),
      isIncomplete: Value(row['is_incomplete'] as bool? ?? false),
      availableWeight: Value((row['available_weight'] as num?)?.toDouble() ?? 1.0),
      scoringVersion: Value(row['scoring_version'] as int? ?? 2),
      focusPoints: Value((row['focus_points'] as num?)?.toDouble() ?? 0.0),
      intentPoints: Value((row['intent_points'] as num?)?.toDouble() ?? 0.0),
      attentionPoints: Value((row['attention_points'] as num?)?.toDouble()),
      carePoints: Value((row['care_points'] as num?)?.toDouble() ?? 0.0),
      computedAt: Value(DateTime.parse(row['computed_at'] as String? ?? row['created_at'] as String)),
    );
  }
}
