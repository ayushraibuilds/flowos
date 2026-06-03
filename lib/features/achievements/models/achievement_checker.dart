import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/dao/achievements_dao.dart';
import '../../../data/local/dao/xp_ledger_dao.dart';
import '../../../data/local/dao/focus_sessions_dao.dart';
import '../../../data/local/dao/scroll_logs_dao.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/xp_ledger_table.dart';
import '../../../core/constants/xp_constants.dart';

const _uuid = Uuid();

/// All achievable badges in FlowOS.
enum AchievementKey {
  earlyBird,       // 🌅 MIT before 8 AM × 7 days
  flowMaster,      // 🔥 5 consecutive 90-min sessions
  digitalDetox,    // 📵 0 scroll for full day
  tripleThreat,    // 🎯 All 3 MITs × 30 days
  reader,          // 📚 25 break content reads
  breathMaster,    // 🧘 14 breathing exercises
  thousandXPDay,   // ⚡ 1000+ XP in single day
  flowGod,         // 🌌 Level 51
  consistencyKing, // 👑 30-day streak
  nightOwl,        // 🦉 Deep Work after 10 PM
  speedDemon,      // 💨 5 tasks < 1 hour
  bounceBack,      // 🔄 10 recovery actions
  ritualMaster,    // 🧘 20 focus rituals
}

/// Achievement metadata
class AchievementInfo {
  final AchievementKey key;
  final String emoji;
  final String name;
  final String description;

  const AchievementInfo({
    required this.key,
    required this.emoji,
    required this.name,
    required this.description,
  });
}

/// All achievement definitions
const allAchievements = [
  AchievementInfo(key: AchievementKey.earlyBird, emoji: '🌅', name: 'Early Bird', description: 'Complete a MIT before 8 AM for 7 days'),
  AchievementInfo(key: AchievementKey.flowMaster, emoji: '🔥', name: 'Flow Master', description: 'Complete 5 consecutive 90-min sessions'),
  AchievementInfo(key: AchievementKey.digitalDetox, emoji: '📵', name: 'Digital Detox', description: '0 scroll minutes for a full day'),
  AchievementInfo(key: AchievementKey.tripleThreat, emoji: '🎯', name: 'Triple Threat', description: 'All 3 MITs for 30 consecutive days'),
  AchievementInfo(key: AchievementKey.reader, emoji: '📚', name: 'Reader', description: 'Read 25 break content items'),
  AchievementInfo(key: AchievementKey.breathMaster, emoji: '🧘', name: 'Breath Master', description: 'Complete 14 breathing exercises'),
  AchievementInfo(key: AchievementKey.thousandXPDay, emoji: '⚡', name: '1000 XP Day', description: 'Earn 1000+ XP in a single day'),
  AchievementInfo(key: AchievementKey.flowGod, emoji: '🌌', name: 'Flow God', description: 'Reach Level 51'),
  AchievementInfo(key: AchievementKey.consistencyKing, emoji: '👑', name: 'Consistency King', description: 'Maintain a 30-day streak'),
  AchievementInfo(key: AchievementKey.nightOwl, emoji: '🦉', name: 'Night Owl', description: 'Deep Work session after 10 PM'),
  AchievementInfo(key: AchievementKey.speedDemon, emoji: '💨', name: 'Speed Demon', description: 'Complete 5 tasks in under 1 hour'),
  AchievementInfo(key: AchievementKey.bounceBack, emoji: '🔄', name: 'Bounce Back', description: 'Use recovery action 10 times'),
  AchievementInfo(key: AchievementKey.ritualMaster, emoji: '🧘', name: 'Ritual Master', description: 'Complete focus ritual 20 times'),
];

/// Achievement Checker — runs after every XP-granting action.
/// Returns newly unlocked achievements (if any).
class AchievementChecker {
  final AchievementsDao _achievementsDao;
  final XpLedgerDao _xpLedgerDao;
  // ignore: unused_field — used in flowMaster check expansion
  final FocusSessionsDao sessionsDao;
  final ScrollLogsDao _scrollLogsDao;

  AchievementChecker({
    required AchievementsDao achievementsDao,
    required XpLedgerDao xpLedgerDao,
    required FocusSessionsDao sessionsDao,
    required ScrollLogsDao scrollLogsDao,
  })  : _achievementsDao = achievementsDao,
        _xpLedgerDao = xpLedgerDao,
        sessionsDao = sessionsDao,
        _scrollLogsDao = scrollLogsDao;

  /// Check all achievements and unlock any that are newly earned.
  /// Returns list of newly unlocked achievement keys.
  Future<List<AchievementKey>> checkAll({
    required int streakDays,
    required int lifetimeXP,
  }) async {
    final newlyUnlocked = <AchievementKey>[];

    // ⚡ 1000 XP Day
    await _check(AchievementKey.thousandXPDay, () async {
      final dailyXP = await _xpLedgerDao.getDailyXP();
      return dailyXP >= 1000;
    }, newlyUnlocked);

    // 🌌 Flow God — Level 51
    await _check(AchievementKey.flowGod, () async {
      return XpConstants.levelFromXP(lifetimeXP) >= 51;
    }, newlyUnlocked);

    // 👑 Consistency King — 30-day streak
    await _check(AchievementKey.consistencyKing, () async {
      return streakDays >= 30;
    }, newlyUnlocked);

    // 📵 Digital Detox — 0 scroll today
    await _check(AchievementKey.digitalDetox, () async {
      final scrollToday = await _scrollLogsDao.getDailyTotal();
      return scrollToday == 0;
    }, newlyUnlocked);

    // 🦉 Night Owl — Deep Work after 10 PM
    await _check(AchievementKey.nightOwl, () async {
      final now = DateTime.now();
      return now.hour >= 22; // Simplified: checked when session completes
    }, newlyUnlocked);

    // 🔄 Bounce Back — 10 recovery actions
    await _check(AchievementKey.bounceBack, () async {
      // Check total all-time recovery actions
      final allEntries = await _xpLedgerDao.getRecent(limit: 1000);
      final recoveryCount = allEntries
          .where((e) => e.actionType == XpActionTypeColumn.bounceBackBonus)
          .length;
      return recoveryCount >= 10;
    }, newlyUnlocked);

    // 🧘 Ritual Master — 20 focus rituals
    await _check(AchievementKey.ritualMaster, () async {
      final allEntries = await _xpLedgerDao.getRecent(limit: 1000);
      final ritualCount = allEntries
          .where((e) => e.actionType == XpActionTypeColumn.focusRitualComplete)
          .length;
      return ritualCount >= 20;
    }, newlyUnlocked);

    return newlyUnlocked;
  }

  /// Internal helper: check if achievement is already unlocked, if not check condition.
  Future<void> _check(
    AchievementKey key,
    Future<bool> Function() condition,
    List<AchievementKey> newlyUnlocked,
  ) async {
    final alreadyUnlocked = await _achievementsDao.isUnlocked(key.name);
    if (alreadyUnlocked) return;

    final earned = await condition();
    if (!earned) return;

    await _achievementsDao.unlock(AchievementsCompanion(
      id: Value(_uuid.v4()),
      achievementKey: Value(key.name),
      unlockedAt: Value(DateTime.now()),
    ));

    newlyUnlocked.add(key);
  }
}
