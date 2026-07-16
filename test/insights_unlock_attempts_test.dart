import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/insights/providers/insights_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('insightUnlockAttemptsProvider aggregates data correctly when database is empty', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final attempts = await container.read(insightUnlockAttemptsProvider.future);
    expect(attempts.hasData, false);
    expect(attempts.totalAttempts, 0);
  });

  test('insightUnlockAttemptsProvider aggregates total attempts, peak hour, and most blocked target', () async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    final now = DateTime.now();

    // 1. Insert unlock attempts: 2 for instagram at 14:00, 1 for youtube at 15:00
    await db.unlockAttemptsDao.insertAttempt(UnlockAttemptsCompanion.insert(
      id: const Uuid().v4(),
      platform: 'android',
      target: 'com.instagram.android',
      level: 'guard',
      requestedBreakMinutes: 5,
      intention: const Value('Bored'),
      waitOutcome: 'completed_wait',
      timestamp: DateTime(now.year, now.month, now.day, 14, 15),
    ));

    await db.unlockAttemptsDao.insertAttempt(UnlockAttemptsCompanion.insert(
      id: const Uuid().v4(),
      platform: 'android',
      target: 'com.instagram.android',
      level: 'guard',
      requestedBreakMinutes: 5,
      intention: const Value('Checking feed'),
      waitOutcome: 'abandoned',
      timestamp: DateTime(now.year, now.month, now.day, 14, 45),
    ));

    await db.unlockAttemptsDao.insertAttempt(UnlockAttemptsCompanion.insert(
      id: const Uuid().v4(),
      platform: 'android',
      target: 'com.google.android.youtube',
      level: 'deep',
      requestedBreakMinutes: 0,
      intention: const Value('Watch video'),
      waitOutcome: 'abandoned',
      timestamp: DateTime(now.year, now.month, now.day, 15, 30),
    ));

    final attempts = await container.read(insightUnlockAttemptsProvider.future);
    expect(attempts.hasData, true);
    expect(attempts.totalAttempts, 3);
    expect(attempts.mostBlockedTarget, 'com.instagram.android');
    expect(attempts.peakHour, 14);
  });
}
