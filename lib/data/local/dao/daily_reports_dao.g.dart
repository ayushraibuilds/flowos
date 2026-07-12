// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_reports_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyReportsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyReportsTable get dailyReports => attachedDatabase.dailyReports;
  DailyReportsDaoManager get managers => DailyReportsDaoManager(this);
}

class DailyReportsDaoManager {
  final _$DailyReportsDaoMixin _db;
  DailyReportsDaoManager(this._db);
  $$DailyReportsTableTableManager get dailyReports =>
      $$DailyReportsTableTableManager(_db.attachedDatabase, _db.dailyReports);
}
