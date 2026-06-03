import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/achievements_table.dart';

part 'achievements_dao.g.dart';

@DriftAccessor(tables: [Achievements])
class AchievementsDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementsDaoMixin {
  AchievementsDao(super.db);

  Future<void> unlock(AchievementsCompanion entry) =>
      into(achievements).insert(entry);

  /// Get all unlocked achievements
  Future<List<Achievement>> getAll() =>
      (select(achievements)
            ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]))
          .get();

  /// Watch all achievements
  Stream<List<Achievement>> watchAll() =>
      (select(achievements)
            ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]))
          .watch();

  /// Check if a specific achievement is unlocked
  Future<bool> isUnlocked(String key) async {
    final result = await (select(achievements)
          ..where((a) => a.achievementKey.equals(key)))
        .getSingleOrNull();
    return result != null;
  }

  /// Get by ID (for sync pull lookup).
  Future<Achievement?> getById(String id) =>
      (select(achievements)..where((a) => a.id.equals(id))).getSingleOrNull();

  /// Insert an achievement (alias for unlock, used by sync engine).
  Future<void> insertAchievement(AchievementsCompanion entry) =>
      into(achievements).insert(entry);

  /// Get achievements since a given timestamp (for sync push).
  Future<List<Achievement>> getModifiedSince(DateTime since) =>
      (select(achievements)
            ..where((a) => a.unlockedAt.isBiggerOrEqualValue(since)))
          .get();
}
