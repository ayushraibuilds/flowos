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

  Future<void> insertOp(SyncOutboxCompanion entry) => into(syncOutbox).insert(entry);

  Future<void> markSynced(String id) =>
      (update(syncOutbox)..where((s) => s.id.equals(id)))
          .write(const SyncOutboxCompanion(isSynced: Value(true)));

  Future<void> deleteSynced() =>
      (delete(syncOutbox)..where((s) => s.isSynced.equals(true))).go();
}
