import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database/app_database.dart';
import '../../xp/providers/xp_providers.dart';
import '../services/energy_checkin_service.dart';

final energyCheckInServiceProvider = Provider<EnergyCheckInService>((ref) {
  final db = ref.watch(databaseProvider);
  final xpCalculator = ref.watch(xpCalculatorProvider);
  return EnergyCheckInService(db: db, xpCalculator: xpCalculator);
});

final todayEnergyCheckInsProvider = StreamProvider<List<EnergyCheckIn>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.energyCheckInsDao.watchToday();
});

final latestEnergyCheckInProvider = Provider<EnergyCheckIn?>((ref) {
  final checkinsAsync = ref.watch(todayEnergyCheckInsProvider);
  return checkinsAsync.when(
    data: (checkins) {
      if (checkins.isEmpty) return null;
      final sorted = List<EnergyCheckIn>.from(checkins)
        ..sort((a, b) => b.date.compareTo(a.date));
      return sorted.first;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
