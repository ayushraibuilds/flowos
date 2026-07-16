import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/unlock_attempts_table.dart';

part 'unlock_attempts_dao.g.dart';

@DriftAccessor(tables: [UnlockAttempts])
class UnlockAttemptsDao extends DatabaseAccessor<AppDatabase>
    with _$UnlockAttemptsDaoMixin {
  UnlockAttemptsDao(super.db);

  final _uuid = const Uuid();

  Future<UnlockAttempt?> getById(String id) =>
      (select(unlockAttempts)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<void> _recordOutboxUpsert(String id) async {
    final attempt = await getById(id);
    if (attempt != null) {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('unlock_attempts'),
        entityId: Value(id),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(attempt.toJson())),
      ));
    }
  }

  /// Insert a single unlock attempt log
  Future<void> insertAttempt(UnlockAttemptsCompanion entry) async {
    await transaction(() async {
      await into(unlockAttempts).insert(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> insertAttemptFromSync(UnlockAttemptsCompanion entry) => into(unlockAttempts).insert(entry);

  /// Get attempts sorted by timestamp descending
  Future<List<UnlockAttempt>> getAllAttempts() =>
      (select(unlockAttempts)..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
          .get();

  /// Get attempts modified/created since last sync
  Future<List<UnlockAttempt>> getModifiedSince(DateTime since) =>
      (select(unlockAttempts)
            ..where((r) => r.timestamp.isBiggerThanValue(since))
            ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
          .get();
}
