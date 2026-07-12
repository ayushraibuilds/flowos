// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scroll_logs_dao.dart';

// ignore_for_file: type=lint
mixin _$ScrollLogsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ScrollLogsTable get scrollLogs => attachedDatabase.scrollLogs;
  ScrollLogsDaoManager get managers => ScrollLogsDaoManager(this);
}

class ScrollLogsDaoManager {
  final _$ScrollLogsDaoMixin _db;
  ScrollLogsDaoManager(this._db);
  $$ScrollLogsTableTableManager get scrollLogs =>
      $$ScrollLogsTableTableManager(_db.attachedDatabase, _db.scrollLogs);
}
