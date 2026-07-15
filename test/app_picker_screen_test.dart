import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/attention/providers/app_picker_providers.dart';
import 'package:flowos/presentation/screens/protection/app_picker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'flowos_user_profile': '{"distractions": ["Instagram"]}',
      'flowos_legacy_suggestions_shown': false,
    });
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        launchableAppsProvider.overrideWith((ref) async => [
          {'packageName': 'com.instagram.android', 'label': 'Instagram'},
          {'packageName': 'com.zhiliaoapp.musically', 'label': 'TikTok'},
        ]),
        essentialPackagesProvider.overrideWith((ref) async => [
          {'packageName': 'com.android.settings', 'reason': 'System settings'},
          {'packageName': 'com.google.android.GoogleCamera', 'reason': 'Default Camera'},
        ]),
      ],
      child: MaterialApp(
        home: AppPickerScreen(key: UniqueKey()),
      ),
    );
  }

  group('AppPickerScreen Widget Tests', () {
    testWidgets('Renders tabs and search field', (tester) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Choose apps to protect'), findsOneWidget);
      expect(find.text('Distracting'), findsOneWidget);
      expect(find.text('Always Available'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Search apps...'), findsOneWidget);

      await db.close();
      await tester.pumpAndSettle();
    });

    testWidgets('Legacy suggestion banner pre-checks and dismisses cleanly', (tester) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Suggestions banner is visible
      expect(find.textContaining('We found 1 apps from your earlier setup'), findsOneWidget);

      // Pre-fill suggestions
      await tester.tap(find.text('Pre-fill'));
      await tester.pumpAndSettle();

      // Banner should be gone
      expect(find.textContaining('We found 1 apps from your earlier setup'), findsNothing);

      // Verify com.instagram.android is pre-filled but not yet saved in SQLite
      var saved = await db.protectedAppsDao.getAll();
      expect(saved, isEmpty);

      // Close database and rebuild a clean state
      await db.close();
      await tester.pumpAndSettle();

      db = AppDatabase.forTesting(NativeDatabase.memory());
      
      // Explicitly reset SharedPreferences keys for the next run
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('flowos_legacy_suggestions_shown', false);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Suggestions banner is visible again
      expect(find.textContaining('We found 1 apps from your earlier setup'), findsOneWidget);

      // Tap Dismiss
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.textContaining('We found 1 apps from your earlier setup'), findsNothing);

      await db.close();
      await tester.pumpAndSettle();
    });

    testWidgets('Toggling and saving persists protected apps', (tester) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // We pre-fill or manually tap checkboxes
      // Find checkbox for com.instagram.android Focus toggle
      // The Distraction App row has two checkboxes: first is Focus, second is Sleep
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(4)); // 2 checkboxes per app, 2 apps in distracting tab

      // Tap Instagram Focus checkbox
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final saved = await db.protectedAppsDao.getAll();
      expect(saved.length, 1);
      expect(saved.first.appRef, 'com.instagram.android');
      expect(saved.first.protectsFocus, true);
      expect(saved.first.protectsSleep, false);

      await db.close();
      await tester.pumpAndSettle();
    });

    testWidgets('Essential apps appear locked in Always Available tab', (tester) async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to Always Available tab
      await tester.tap(find.text('Always Available'));
      await tester.pumpAndSettle();

      expect(find.text('Default Camera'), findsOneWidget);
      expect(find.text('System settings'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNWidgets(2));

      await db.close();
      await tester.pumpAndSettle();
    });
  });
}
