import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database/app_database.dart';

/// Provider for lifetime focus minutes
final lifetimeFocusMinutesProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.focusSessionsDao.watchLifetimeFocusMinutes();
});

/// Provider for total completed tasks count
final totalCompletedTasksCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tasksDao.watchCompletedCount();
});

/// Provider for lifetime recoveries count
final lifetimeRecoveriesCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.xpLedgerDao.watchLifetimeRecoveriesCount();
});
