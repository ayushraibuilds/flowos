// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unlock_attempts_dao.dart';

// ignore_for_file: type=lint
mixin _$UnlockAttemptsDaoMixin on DatabaseAccessor<AppDatabase> {
  $UnlockAttemptsTable get unlockAttempts => attachedDatabase.unlockAttempts;
  UnlockAttemptsDaoManager get managers => UnlockAttemptsDaoManager(this);
}

class UnlockAttemptsDaoManager {
  final _$UnlockAttemptsDaoMixin _db;
  UnlockAttemptsDaoManager(this._db);
  $$UnlockAttemptsTableTableManager get unlockAttempts =>
      $$UnlockAttemptsTableTableManager(
        _db.attachedDatabase,
        _db.unlockAttempts,
      );
}
