import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';

import '../../../features/notifications/services/notification_service.dart';
import '../../../data/local/database/app_database.dart';
import '../../focus/models/focus_protection.dart';

class SettingsState {
  final bool energyReminders;
  final bool reportReminder;
  final bool streakWarning;
  final bool weeklyReview;
  final int scrollBudget;
  final bool soundEnabled;
  final bool autoSync;
  final FocusProtectionLevel focusProtection;

  const SettingsState({
    required this.energyReminders,
    required this.reportReminder,
    required this.streakWarning,
    required this.weeklyReview,
    required this.scrollBudget,
    required this.soundEnabled,
    required this.autoSync,
    required this.focusProtection,
  });

  SettingsState copyWith({
    bool? energyReminders,
    bool? reportReminder,
    bool? streakWarning,
    bool? weeklyReview,
    int? scrollBudget,
    bool? soundEnabled,
    bool? autoSync,
    FocusProtectionLevel? focusProtection,
  }) {
    return SettingsState(
      energyReminders: energyReminders ?? this.energyReminders,
      reportReminder: reportReminder ?? this.reportReminder,
      streakWarning: streakWarning ?? this.streakWarning,
      weeklyReview: weeklyReview ?? this.weeklyReview,
      scrollBudget: scrollBudget ?? this.scrollBudget,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      autoSync: autoSync ?? this.autoSync,
      focusProtection: focusProtection ?? this.focusProtection,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;

  static const _keyEnergyReminders = 'flowos_energy_reminders';
  static const _keyReportReminder = 'flowos_report_reminder';
  static const _keyStreakWarning = 'flowos_streak_reminder';
  static const _keyWeeklyReview = 'flowos_weekly_review';
  static const _keyScrollBudget = 'flowos_scroll_budget';
  static const _keySoundEnabled = 'flowos_ambient_sounds';
  static const _keyAutoSync = 'flowos_auto_sync';
  static const _keyFocusProtection = 'flowos_focus_protection';

  SettingsNotifier(this._ref)
      : super(const SettingsState(
          energyReminders: true,
          reportReminder: true,
          streakWarning: true,
          weeklyReview: true,
          scrollBudget: 30,
          soundEnabled: true,
          autoSync: true,
          focusProtection: FocusProtectionLevel.softReturn,
        )) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      energyReminders: prefs.getBool(_keyEnergyReminders) ?? true,
      reportReminder: prefs.getBool(_keyReportReminder) ?? true,
      streakWarning: prefs.getBool(_keyStreakWarning) ?? true,
      weeklyReview: prefs.getBool(_keyWeeklyReview) ?? true,
      scrollBudget: prefs.getInt(_keyScrollBudget) ?? 30,
      soundEnabled: prefs.getBool(_keySoundEnabled) ?? true,
      autoSync: prefs.getBool(_keyAutoSync) ?? true,
      focusProtection: FocusProtectionLevel.values.firstWhere(
        (level) => level.name == prefs.getString(_keyFocusProtection),
        orElse: () => FocusProtectionLevel.softReturn,
      ),
    );
  }

  Future<void> setEnergyReminders(bool value) async {
    state = state.copyWith(energyReminders: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnergyReminders, value);
    if (value) {
      await NotificationService.scheduleEnergyCheckIns();
    } else {
      await NotificationService.cancelEnergyCheckIns();
    }
  }

  Future<void> setReportReminder(bool value) async {
    state = state.copyWith(reportReminder: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReportReminder, value);
    if (value) {
      await NotificationService.scheduleReportReminder();
    } else {
      await NotificationService.cancelReportReminder();
    }
  }

  Future<void> setStreakWarning(bool value) async {
    state = state.copyWith(streakWarning: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyStreakWarning, value);
    if (value) {
      await NotificationService.scheduleStreakWarning();
    } else {
      await NotificationService.cancelStreakWarning();
    }
  }

  Future<void> setWeeklyReview(bool value) async {
    state = state.copyWith(weeklyReview: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyReview, value);
    if (value) {
      await NotificationService.scheduleWeeklyReview();
    } else {
      await NotificationService.cancelWeeklyReview();
    }
  }

  Future<void> setScrollBudget(int value) async {
    state = state.copyWith(scrollBudget: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScrollBudget, value);

    // Update today's plan scroll budget if it exists in DB
    final db = _ref.read(databaseProvider);
    final todayPlan = await db.dailyPlansDao.getToday();
    if (todayPlan != null) {
      await db.dailyPlansDao.upsertToday(
        DailyPlansCompanion(
          id: Value(todayPlan.id),
          date: Value(todayPlan.date),
          scrollBudgetMinutes: Value(value),
          mit1Id: Value(todayPlan.mit1Id),
          mit2Id: Value(todayPlan.mit2Id),
          mit3Id: Value(todayPlan.mit3Id),
          morningEnergy: Value(todayPlan.morningEnergy),
          intentionCompleted: Value(todayPlan.intentionCompleted),
          shutdownCompleted: Value(todayPlan.shutdownCompleted),
        ),
      );
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    state = state.copyWith(soundEnabled: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, value);
  }

  Future<void> setAutoSync(bool value) async {
    state = state.copyWith(autoSync: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, value);
  }

  Future<void> setFocusProtection(FocusProtectionLevel value) async {
    state = state.copyWith(focusProtection: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFocusProtection, value.name);
  }
}
