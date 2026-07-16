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

  group('HomeScreen Widget Tests', () {
    testWidgets('Renders levels and metrics consistently', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Verify level text renders correctly
      // Level 1 is the default start level
      expect(find.textContaining('Lv 1'), findsAtLeast(1));
      expect(find.textContaining('Next: Lv 2'), findsOneWidget);

      // Clean up animation tickers
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Daily score shows incomplete indicator when zero engagement', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();

      // Zero engagement should show "—" instead of "F" for daily score grade
      expect(find.text('—'), findsAtLeast(1));
      expect(find.text('F'), findsNothing);

      // Clean up animation tickers
      await tester.pumpWidget(const SizedBox());
    });
  });
}
