import '../../../data/local/database/app_database.dart';
import '../../../data/local/tables/energy_checkins_table.dart';
import '../../../features/xp/models/xp_calculator.dart';
import '../../../features/achievements/models/achievement_checker.dart';

class EnergyCheckInService {
  final AppDatabase _db;
  final XpCalculator _xpCalculator;

  EnergyCheckInService({
    required AppDatabase db,
    required XpCalculator xpCalculator,
  })  : _db = db,
        _xpCalculator = xpCalculator;

  /// Log energy and check for 3x bonus / achievements.
  /// Returns true if a 3x bonus was awarded.
  Future<bool> logEnergy(TimeOfDayColumn bucket, int value) async {
    // Count today's check-ins before inserting
    final beforeCount = await _db.energyCheckInsDao.countToday();
    final hasExistingInBucket = await _db.energyCheckInsDao.getForBucket(bucket, DateTime.now()) != null;

    // Upsert
    await _db.energyCheckInsDao.upsertCheckIn(bucket, value);

    // If we just completed all 3 check-ins today (from 2 -> 3)
    final afterCount = await _db.energyCheckInsDao.countToday();
    bool awardedBonus = false;

    if (afterCount == 3 && beforeCount < 3 && !hasExistingInBucket) {
      await _xpCalculator.awardEnergyCheckin3xBonus();
      await AchievementChecker.runCheck(_db);
      awardedBonus = true;
    }

    return awardedBonus;
  }
}
