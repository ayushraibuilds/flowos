import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/features/attention/widgets/distraction_app_icon.dart';
import 'package:flowos/features/flow_garden/models/garden_day.dart';
import 'package:flowos/features/flow_garden/widgets/garden_plot.dart';

void main() {
  const focusFlower = GardenObject(
    id: 'focus-session-1',
    kind: GardenObjectKind.flower,
    emoji: '🌸',
    seedEmoji: '🌱',
    title: 'Focus flower',
    detail: 'Write the first draft',
    focusMinutes: 25,
    x: .5,
    y: .5,
  );

  final gardenDay = GardenDay(
    date: DateTime(2026, 7, 22),
    objects: [focusFlower],
    focusMinutes: 25,
    recoveryCount: 0,
    scrollMinutes: 0,
    scrollBudgetMinutes: 30,
    isCompleted: false,
    isProtected: false,
  );

  testWidgets('a grown plant opens its focus record instead of starting focus', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: GardenPlot(day: gardenDay)),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel(RegExp('Focus flower, grown from a 25-minute focus session')));
    await tester.pumpAndSettle();

    expect(find.text('25 minutes of focus grew this flower.'), findsOneWidget);
    expect(find.text('Task: Write the first draft'), findsOneWidget);
    expect(find.text('Plant another'), findsOneWidget);
  });

  testWidgets('all distraction category illustrations paint without emoji assets', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: DistractionAppIconType.values
                .map((type) => DistractionAppIcon(type: type, color: Colors.white))
                .toList(),
          ),
        ),
      ),
    );

    expect(find.byType(DistractionAppIcon), findsNWidgets(DistractionAppIconType.values.length));
  });
}
