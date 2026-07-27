import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/sync_outbox_table.dart';

part 'sync_outbox_dao.g.dart';

@DriftAccessor(tables: [SyncOutbox])
class SyncOutboxDao extends DatabaseAccessor<AppDatabase> with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  Future<List<SyncOutboxData>> getUnsynced() => (select(syncOutbox)
        ..where((s) => s.isSynced.equals(false))
        ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
      .get();

  Future<List<SyncOutboxData>> getUnsyncedForOwner(String ownerId) =>
      (select(syncOutbox)
            ..where((s) => s.isSynced.equals(false) & s.ownerId.equals(ownerId))
            ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
          .get();

  Future<bool> hasUnsyncedForOtherOwner(String activeOwnerId) async {
    final list = await (select(syncOutbox)
          ..where((s) =>
              s.isSynced.equals(false) &
              s.ownerId.equals(activeOwnerId).not() &
              s.ownerId.equals('local').not()))
        .get();
    return list.isNotEmpty;
  }

  Future<void> claimLocalOutbox(String targetOwnerId) async {
    await (update(syncOutbox)..where((s) => s.ownerId.equals('local')))
        .write(SyncOutboxCompanion(ownerId: Value(targetOwnerId)));
  }

  Future<void> insertOp(SyncOutboxCompanion entry) => into(syncOutbox).insert(entry);

  Future<void> markSynced(String id) =>
      (update(syncOutbox)..where((s) => s.id.equals(id)))
          .write(const SyncOutboxCompanion(isSynced: Value(true)));

  Future<void> deleteSynced() =>
      (delete(syncOutbox)..where((s) => s.isSynced.equals(true))).go();
}
