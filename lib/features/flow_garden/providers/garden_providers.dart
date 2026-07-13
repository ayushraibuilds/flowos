import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database/app_database.dart';
import '../models/garden_day.dart';
import '../services/garden_service.dart';

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

/// Today's living plot, assembled from focus, recovery, energy, and attention data.
final todayGardenProvider = StreamProvider<GardenDay>((ref) {
  final db = ref.watch(databaseProvider);
  return GardenService(db).watchToday();
});

/// The current week becomes a small seasonal archive instead of a fragile streak.
final gardenWeekProvider = StreamProvider<List<GardenDay>>((ref) {
  final db = ref.watch(databaseProvider);
  return GardenService(db).watchCurrentWeek();
});
