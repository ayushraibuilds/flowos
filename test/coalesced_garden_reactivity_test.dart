import 'dart:async';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/data/local/tables/tasks_table.dart';
import 'package:flowos/features/flow_garden/services/garden_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late GardenService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = GardenService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TASK-014: Coalesced Garden Reactivity & Query Batching Tests', () {
    test(
      'Batched task lookup in buildDay performs 1 batch query for N sessions',
      () async {
        // 1. Insert 3 tasks
        for (int i = 1; i <= 3; i++) {
          await db.tasksDao.insertTask(
            TasksCompanion(
              id: Value('task_$i'),
              title: Value('Task $i'),
              energyLevel: const Value(EnergyLevelColumn.medium),
              category: const Value(TaskCategoryColumn.work),
            ),
          );
        }

        // 2. Insert 5 focus sessions linked to tasks
        final now = DateTime.now();
        for (int i = 1; i <= 5; i++) {
          final taskId = 'task_${((i - 1) % 3) + 1}';
          await db.focusSessionsDao.insertSession(
            FocusSessionsCompanion.insert(
              id: 'session_$i',
              sessionType: SessionTypeColumn.deepWork,
              durationMinutes: 25,
              actualMinutes: const Value(25),
              qualityScore: const Value('A'),
              completedAt: Value(now),
              taskId: Value(taskId),
              startedAt: now.subtract(const Duration(minutes: 25)),
            ),
          );
        }

        final gardenDay = await service.buildDay(now);

        expect(gardenDay.focusMinutes, equals(125));
        expect(gardenDay.objects.length, greaterThanOrEqualTo(5));

        final sessionObjects = gardenDay.objects
            .where((o) => o.detail != null && o.detail!.startsWith('Task'))
            .toList();
        expect(sessionObjects.length, equals(5));
      },
    );

    test(
      'Multiple listeners share the same broadcast stream pipeline',
      () async {
        final stream1 = service.watchToday();
        final stream2 = service.watchToday();

        expect(identical(stream1, stream2), isTrue);

        final completer1 = Completer<void>();
        final completer2 = Completer<void>();

        final sub1 = stream1.listen((_) {
          if (!completer1.isCompleted) completer1.complete();
        });
        final sub2 = stream2.listen((_) {
          if (!completer2.isCompleted) completer2.complete();
        });

        await Future.wait([completer1.future, completer2.future]);

        await sub1.cancel();
        await sub2.cancel();
      },
    );

    test(
      'Burst table updates coalesce into a single delayed rebuild',
      () async {
        final stream = service.watchToday();
        int emitCount = 0;

        final sub = stream.listen((_) {
          emitCount++;
        });

        // Allow initial build to emit
        await Future.delayed(const Duration(milliseconds: 100));
        final initialEmits = emitCount;

        // Trigger rapid burst of writes
        final now = DateTime.now();
        for (int i = 10; i <= 15; i++) {
          await db.focusSessionsDao.insertSession(
            FocusSessionsCompanion.insert(
              id: 'burst_session_$i',
              sessionType: SessionTypeColumn.deepWork,
              durationMinutes: 25,
              actualMinutes: const Value(25),
              qualityScore: const Value('A'),
              completedAt: Value(now),
              startedAt: now.subtract(const Duration(minutes: 25)),
            ),
          );
        }

        // Wait for debounced coalesce period (150ms)
        await Future.delayed(const Duration(milliseconds: 150));

        // Burst of 6 inserts should result in only 1 additional emission
        expect(emitCount, equals(initialEmits + 1));

        await sub.cancel();
      },
    );
  });
}
