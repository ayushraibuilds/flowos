import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/protected_apps_table.dart';

part 'protected_apps_dao.g.dart';

@DriftAccessor(tables: [ProtectedApps])
class ProtectedAppsDao extends DatabaseAccessor<AppDatabase>
    with _$ProtectedAppsDaoMixin {
  ProtectedAppsDao(super.db);

  Future<List<ProtectedApp>> getAll() => select(protectedApps).get();

  Future<void> insertApp(ProtectedAppsCompanion entry) =>
      into(protectedApps).insert(entry);

  Future<void> upsertApp(ProtectedAppsCompanion entry) =>
      into(protectedApps).insertOnConflictUpdate(entry);

  Future<void> deleteApp(String id) =>
      (delete(protectedApps)..where((t) => t.id.equals(id))).go();

  Future<void> clearAll() => delete(protectedApps).go();
}
