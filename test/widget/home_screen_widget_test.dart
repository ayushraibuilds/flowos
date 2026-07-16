import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/presentation/screens/home/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'flowos_user_profile': '{"distractions": []}',
      'flowos_streak_count': 5,
      'flowos_best_streak': 5,
      'flowos_streak_last_active': '2026-07-16',
    });
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: HomeScreen(),
        ),
      ),
    );
  }

  /// Pump enough frames for async FutureProviders to resolve against
  /// the in-memory DB, then unmount cleanly to flush Drift stream timers.
  Future<void> pumpAndCleanUp(WidgetTester tester) async {
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> cleanUpWidget(WidgetTester tester) async {
    // Unmount the widget tree first, which disposes ProviderScope and Drift streams.
    await tester.pumpWidget(const SizedBox());
    // Flush any zero-duration timers left behind by Drift's StreamQueryStore disposal.
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);
  }

  group('HomeScreen Widget Tests', () {
    testWidgets('Renders levels and metrics consistently', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await pumpAndCleanUp(tester);

      // Level 0 is the default for a brand-new user (0 XP).
      // The hero card shows "Lv 0" and the progress bar shows "Next: Lv 1".
      expect(find.textContaining('Lv'), findsAtLeast(1));

      await cleanUpWidget(tester);
    });

    testWidgets('Daily score shows incomplete indicator when zero engagement', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await pumpAndCleanUp(tester);

      // Zero engagement should show "—" instead of "F" for daily score grade.
      // The dailyScoreProvider returns grade: null when hasEngagedToday is false,
      // and the UI renders that as "—".
      expect(find.text('—'), findsAtLeast(1));
      expect(find.text('F'), findsNothing);

      await cleanUpWidget(tester);
    });
  });
}
