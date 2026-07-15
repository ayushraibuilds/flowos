import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/protected_apps_table.dart';

part 'protected_apps_dao.g.dart';

@DriftAccessor(tables: [ProtectedApps])
class ProtectedAppsDao extends DatabaseAccessor<AppDatabase>
    with _$ProtectedAppsDaoMixin {
  ProtectedAppsDao(super.db);

  Future<List<ProtectedApp>> getAll() => select(protectedApps).get();

  Stream<List<ProtectedApp>> watchAll() => select(protectedApps).watch();

  Future<List<ProtectedApp>> getFocusProtected() =>
      (select(protectedApps)..where((t) => t.protectsFocus.equals(true))).get();

  Future<List<ProtectedApp>> getSleepProtected() =>
      (select(protectedApps)..where((t) => t.protectsSleep.equals(true))).get();

  Future<ProtectedApp?> getByPlatformAndRef(String platform, String appRef) =>
      (select(protectedApps)
            ..where((t) => t.platform.equals(platform) & t.appRef.equals(appRef)))
          .getSingleOrNull();

  Future<void> insertApp(ProtectedAppsCompanion entry) =>
      into(protectedApps).insert(entry);

  Future<void> upsertApp(ProtectedAppsCompanion entry) =>
      into(protectedApps).insertOnConflictUpdate(entry);

  Future<void> bulkUpsert(List<ProtectedAppsCompanion> entries) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(protectedApps, entries);
    });
  }

  Future<void> updateFlags({
    required String platform,
    required String appRef,
    bool? protectsFocus,
    bool? protectsSleep,
  }) async {
    final query = update(protectedApps)
      ..where((t) => t.platform.equals(platform) & t.appRef.equals(appRef));

    await query.write(ProtectedAppsCompanion(
      protectsFocus: protectsFocus != null ? Value(protectsFocus) : const Value.absent(),
      protectsSleep: protectsSleep != null ? Value(protectsSleep) : const Value.absent(),
    ));
  }

  Future<void> deleteIfUnprotected(String platform, String appRef) async {
    await (delete(protectedApps)
          ..where((t) =>
              t.platform.equals(platform) &
              t.appRef.equals(appRef) &
              t.protectsFocus.equals(false) &
              t.protectsSleep.equals(false)))
        .go();
  }

  Future<void> deleteApp(String id) =>
      (delete(protectedApps)..where((t) => t.id.equals(id))).go();

  Future<void> clearAll() => delete(protectedApps).go();
}
