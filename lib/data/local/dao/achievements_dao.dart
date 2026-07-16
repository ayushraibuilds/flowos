import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/achievements_table.dart';

part 'achievements_dao.g.dart';

@DriftAccessor(tables: [Achievements])
class AchievementsDao extends DatabaseAccessor<AppDatabase>
    with _$AchievementsDaoMixin {
  AchievementsDao(super.db);

  final _uuid = const Uuid();

  Future<void> _recordOutboxUpsert(String id) async {
    final achievement = await getById(id);
    if (achievement != null) {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('achievements'),
        entityId: Value(id),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(achievement.toJson())),
      ));
    }
  }

  Future<void> unlock(AchievementsCompanion entry) async {
    await transaction(() async {
      await into(achievements).insert(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  /// Get all unlocked achievements
  Future<List<Achievement>> getAll() =>
      (select(achievements)
            ..where((a) => a.deletedAt.isNull())
            ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]))
          .get();

  /// Watch all achievements
  Stream<List<Achievement>> watchAll() =>
      (select(achievements)
            ..where((a) => a.deletedAt.isNull())
            ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]))
          .watch();

  /// Check if a specific achievement is unlocked
  Future<bool> isUnlocked(String key) async {
    final result = await (select(achievements)
          ..where((a) => a.achievementKey.equals(key) & a.deletedAt.isNull()))
        .getSingleOrNull();
    return result != null;
  }

  /// Get by ID (for sync pull lookup).
  Future<Achievement?> getById(String id) =>
      (select(achievements)..where((a) => a.id.equals(id))).getSingleOrNull();

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> insertAchievementFromSync(AchievementsCompanion entry) => into(achievements).insert(entry);
  Future<void> updateAchievementFromSync(AchievementsCompanion entry) =>
      (update(achievements)..where((a) => a.id.equals(entry.id.value))).write(entry);

  /// Get achievements modified since a given timestamp (for sync push).
  Future<List<Achievement>> getModifiedSince(DateTime since) =>
      (select(achievements)
            ..where((a) => a.updatedAt.isBiggerOrEqualValue(since)))
          .get();
}
