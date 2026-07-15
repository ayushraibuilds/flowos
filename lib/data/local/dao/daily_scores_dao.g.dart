// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_scores_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyScoresDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyScoresTable get dailyScores => attachedDatabase.dailyScores;
  DailyScoresDaoManager get managers => DailyScoresDaoManager(this);
}

class DailyScoresDaoManager {
  final _$DailyScoresDaoMixin _db;
  DailyScoresDaoManager(this._db);
  $$DailyScoresTableTableManager get dailyScores =>
      $$DailyScoresTableTableManager(_db.attachedDatabase, _db.dailyScores);
}
