import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/features/flow_garden/models/garden_day.dart';
import 'package:flowos/features/flow_garden/services/garden_service.dart';
import 'package:flowos/features/focus/services/focus_session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FocusSessionService focusService;
  late GardenService gardenService;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    focusService = FocusSessionService(db);
    gardenService = GardenService(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'deep work grows a tree and a protected completed day welcomes wildlife',
    () async {
      final now = DateTime.now();
      await db.dailyPlansDao.insertPlan(
        DailyPlansCompanion.insert(
          id: 'today-plan',
          date: now,
          scrollBudgetMinutes: const Value(30),
          shutdownCompleted: const Value(true),
        ),
      );
      final sessionId = await focusService.startSession(
        type: SessionTypeColumn.deepWork,
        durationMinutes: 90,
      );

      final completion = await focusService.completeSession(
        sessionId: sessionId,
        elapsedSeconds: 90 * 60,
        pauseCount: 0,
        backgroundCount: 0,
        type: SessionTypeColumn.deepWork,
      );
      final day = await gardenService.buildDay(now);

      expect(completion.gardenGrowth?.kind, GardenObjectKind.tree);
      expect(day.focusMinutes, 90);
      expect(day.isProtected, isTrue);
      expect(
        day.objects.any((object) => object.kind == GardenObjectKind.tree),
        isTrue,
      );
      expect(
        day.objects.any((object) => object.kind == GardenObjectKind.wildlife),
        isTrue,
      );
    },
  );

  test(
    'a quiet day becomes resting soil without losing prior growth',
    () async {
      final quietDay = DateTime.now().add(const Duration(days: 2));

      final day = await gardenService.buildDay(quietDay);

      expect(day.isResting, isTrue);
      expect(day.headline, 'Resting soil');
      expect(day.supportingText, contains('Nothing is lost'));
    },
  );
}
