// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievements_dao.dart';

// ignore_for_file: type=lint
mixin _$AchievementsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AchievementsTable get achievements => attachedDatabase.achievements;
  AchievementsDaoManager get managers => AchievementsDaoManager(this);
}

class AchievementsDaoManager {
  final _$AchievementsDaoMixin _db;
  AchievementsDaoManager(this._db);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db.attachedDatabase, _db.achievements);
}
