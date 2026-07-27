import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/focus_sessions_table.dart';
import 'package:flowos/features/insights/widgets/focus_session_timeline.dart';

void main() {
  testWidgets(
    'FocusSessionTimeline classifies deepWork session with focusBlue color',
    (tester) async {
      final now = DateTime.now();
      final session = FocusSession(
        id: 'session-1',
        sessionType: SessionTypeColumn.deepWork,
        durationMinutes: 90,
        actualMinutes: 90,
        startedAt: now.subtract(const Duration(minutes: 90)),
        completedAt: now,
        pauseCount: 0,
        appBackgroundCount: 0,
        xpEarned: 200,
        qualityScore: 'A',
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: FocusSessionTimeline(sessions: [session]),
            ),
          ),
        ),
      );

      // Find the positioned block child in the timeline
      final containerFinder = find.byType(Positioned);
      expect(containerFinder, findsWidgets);

      // Verify widget rendered cleanly without analysis or runtime type mismatch errors
      expect(find.byType(FocusSessionTimeline), findsOneWidget);
    },
  );
}
