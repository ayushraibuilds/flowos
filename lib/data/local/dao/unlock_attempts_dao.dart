import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../tables/unlock_attempts_table.dart';

part 'unlock_attempts_dao.g.dart';

@DriftAccessor(tables: [UnlockAttempts])
class UnlockAttemptsDao extends DatabaseAccessor<AppDatabase>
    with _$UnlockAttemptsDaoMixin {
  UnlockAttemptsDao(super.db);

  /// Insert a single unlock attempt log
  Future<void> insertAttempt(UnlockAttemptsCompanion entry) =>
      into(unlockAttempts).insert(entry);

  /// Get attempts sorted by timestamp descending
  Future<List<UnlockAttempt>> getAllAttempts() =>
      (select(unlockAttempts)..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
          .get();

  /// Get attempts modified/created since last sync
  Future<List<UnlockAttempt>> getModifiedSince(DateTime since) =>
      (select(unlockAttempts)
            ..where((r) => r.timestamp.isBiggerThanValue(since))
            ..orderBy([(r) => OrderingTerm.desc(r.timestamp)]))
          .get();
}
