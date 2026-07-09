import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/energy_checkins_table.dart';
import 'package:flowos/features/energy/services/energy_checkin_service.dart';
import 'package:flowos/features/xp/models/xp_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnergyCheckInService', () {
    late AppDatabase db;
    late XpCalculator xpCalculator;
    late EnergyCheckInService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
      xpCalculator = XpCalculator(db.xpLedgerDao);
      service = EnergyCheckInService(db: db, xpCalculator: xpCalculator);
    });

    tearDown(() async {
      await db.close();
    });

    test('logging first check-in works and inserts row', () async {
      final bonus = await service.logEnergy(TimeOfDayColumn.morning, 4);
      expect(bonus, false); // No bonus for first check-in

      final checkins = await db.energyCheckInsDao.getForDate(DateTime.now());
      expect(checkins.length, 1);
      expect(checkins.first.timeOfDay, TimeOfDayColumn.morning);
      expect(checkins.first.value, 4);
    });

    test('logging same bucket again updates existing row', () async {
      await service.logEnergy(TimeOfDayColumn.morning, 4);
      final bonus = await service.logEnergy(TimeOfDayColumn.morning, 5);
      expect(bonus, false);

      final checkins = await db.energyCheckInsDao.getForDate(DateTime.now());
      expect(checkins.length, 1);
      expect(checkins.first.timeOfDay, TimeOfDayColumn.morning);
      expect(checkins.first.value, 5); // Updated value
    });

    test('logging 3 distinct buckets awards 3x daily bonus', () async {
      // 1st log
      var bonus = await service.logEnergy(TimeOfDayColumn.morning, 4);
      expect(bonus, false);
      expect(await db.xpLedgerDao.getLifetimeXP(), 0);

      // 2nd log
      bonus = await service.logEnergy(TimeOfDayColumn.afternoon, 3);
      expect(bonus, false);
      expect(await db.xpLedgerDao.getLifetimeXP(), 0);

      // 3rd log
      bonus = await service.logEnergy(TimeOfDayColumn.evening, 5);
      expect(bonus, true); // 3x bonus awarded!
      expect(await db.xpLedgerDao.getLifetimeXP(), 20); // XpConstants.energyCheckin3x is 20
    });

    test('idempotency of 3x bonus on subsequent updates', () async {
      // Log all three
      await service.logEnergy(TimeOfDayColumn.morning, 4);
      await service.logEnergy(TimeOfDayColumn.afternoon, 3);
      var bonus = await service.logEnergy(TimeOfDayColumn.evening, 5);
      expect(bonus, true);
      expect(await db.xpLedgerDao.getLifetimeXP(), 20);

      // Log evening again (update)
      bonus = await service.logEnergy(TimeOfDayColumn.evening, 4);
      expect(bonus, false); // No double award
      expect(await db.xpLedgerDao.getLifetimeXP(), 20); // Remaining 20
    });
  });
}
