// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'protected_apps_dao.dart';

// ignore_for_file: type=lint
mixin _$ProtectedAppsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProtectedAppsTable get protectedApps => attachedDatabase.protectedApps;
  ProtectedAppsDaoManager get managers => ProtectedAppsDaoManager(this);
}

class ProtectedAppsDaoManager {
  final _$ProtectedAppsDaoMixin _db;
  ProtectedAppsDaoManager(this._db);
  $$ProtectedAppsTableTableManager get protectedApps =>
      $$ProtectedAppsTableTableManager(_db.attachedDatabase, _db.protectedApps);
}
