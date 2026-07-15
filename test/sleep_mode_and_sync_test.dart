import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/focus/models/effective_policy.dart';
import 'package:flowos/features/focus/widgets/focus_shield_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusShieldOverlay widget tests', () {
    testWidgets('FocusShieldOverlay hides break buttons when bypassAllowed is false', (tester) async {
      bool keepFocusCalled = false;
      bool cancelSessionCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      FocusShieldOverlay.show(
                        context,
                        packageName: 'com.test.app',
                        appDisplayName: 'Test App',
                        protectionMode: ProtectionMode.guard,
                        onKeepFocus: () {
                          keepFocusCalled = true;
                        },
                        onCancelSession: () {
                          cancelSessionCalled = true;
                        },
                        bypassAllowed: false, // Sleep Guard condition
                      );
                    },
                    child: const Text('Show Shield'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Open the overlay
      await tester.tap(find.text('Show Shield'));
      // Advance clock to finish the reflection wait countdown (20 seconds for Guard)
      for (int i = 0; i < 22; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      // Check that "Resume" button exists
      expect(find.text('Resume'), findsOneWidget);
      // Check that "Take a break" button does NOT exist
      expect(find.text('Take a break'), findsNothing);
    });
  });

  group('Drift Exactly-Once Sync tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Drift transaction exactly-once batch deduping', () async {
      // Process batch 1
      final isNew1 = await db.notificationDailyCountsDao.markBatchProcessed('batch-123');
      expect(isNew1, isTrue);

      await db.notificationDailyCountsDao.incrementCount(
        DateTime.now(),
        'android',
        'pkg.test',
        'Test App',
        1,
      );

      // Process batch 1 again (should be false/no-op)
      final isNew2 = await db.notificationDailyCountsDao.markBatchProcessed('batch-123');
      expect(isNew2, isFalse);

      if (isNew2) {
        await db.notificationDailyCountsDao.incrementCount(
          DateTime.now(),
          'android',
          'pkg.test',
          'Test App',
          1,
        );
      }

      final counts = await db.notificationDailyCountsDao.getForDay(DateTime.now());
      expect(counts.length, 1);
      expect(counts.first.count, 1); // should not be 2!
    });
  });
}
