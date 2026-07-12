// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_plans_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyPlansDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyPlansTable get dailyPlans => attachedDatabase.dailyPlans;
  DailyPlansDaoManager get managers => DailyPlansDaoManager(this);
}

class DailyPlansDaoManager {
  final _$DailyPlansDaoMixin _db;
  DailyPlansDaoManager(this._db);
  $$DailyPlansTableTableManager get dailyPlans =>
      $$DailyPlansTableTableManager(_db.attachedDatabase, _db.dailyPlans);
}
