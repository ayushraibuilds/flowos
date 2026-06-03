import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database/app_database.dart';

/// Riverpod providers for task data — bridges UI to Drift DAOs.
/// All providers are reactive streams that update when DB changes.

/// Watch all active (non-deleted) tasks, sorted by sort order.
final activeTasksProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tasksDao.watchAllActive();
});

/// Watch today's MITs (max 3).
final mitsProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tasksDao.watchMITs();
});

/// Watch incomplete tasks only.
final incompleteTasksProvider = FutureProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tasksDao.getIncomplete();
});

/// Count of tasks completed today.
final tasksCompletedTodayProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.tasksDao.countCompletedToday();
});
