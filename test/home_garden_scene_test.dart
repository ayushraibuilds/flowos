import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/features/flow_garden/models/garden_day.dart';
import 'package:flowos/features/flow_garden/widgets/home_garden_scene.dart';

void main() {
  GardenDay buildDay({GardenVitality? vitality, int recoveryCount = 0}) {
    final objects = <GardenObject>[
      const GardenObject(
        id: 'today-companion',
        kind: GardenObjectKind.wildlife,
        emoji: '🦋',
        seedEmoji: '🦋',
        title: 'Wildlife Companion',
        x: 0.15,
        y: 0.48,
      ),
    ];
    if (vitality == GardenVitality.growing ||
        vitality == GardenVitality.flourishing ||
        vitality == GardenVitality.recovering ||
        vitality == GardenVitality.thirsty) {
      objects.add(
        const GardenObject(
          id: 'focus-session',
          kind: GardenObjectKind.flower,
          emoji: '🌱',
          seedEmoji: '🌱',
          title: 'Focus flower',
          x: 0.5,
          y: 0.6,
        ),
      );
    }
    return GardenDay(
      date: DateTime(2026, 7, 14),
      objects: objects,
      focusMinutes: vitality == GardenVitality.flourishing ? 30 : 10,
      recoveryCount: recoveryCount,
      scrollMinutes: vitality == GardenVitality.thirsty ? 40 : 0,
      scrollBudgetMinutes: 30,
      isCompleted: false,
      isProtected: false,
    );
  }

  Widget scene({
    required GardenDay day,
    required VoidCallback onFocus,
    required VoidCallback onRecovery,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: HomeGardenScene(
            day: day,
            onFocusTap: onFocus,
            onRecoveryTap: onRecovery,
            onGardenTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('focus action is available from a growing garden', (tester) async {
    var focusTapped = false;
    await tester.pumpWidget(
      scene(
        day: buildDay(vitality: GardenVitality.growing),
        onFocus: () => focusTapped = true,
        onRecovery: () {},
      ),
    );

    expect(find.text('Your plot is taking shape'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Start focus with your garden'));
    await tester.pump(const Duration(milliseconds: 160));

    expect(focusTapped, isTrue);
  });

  testWidgets('thirsty garden offers a recovery action without blame', (
    tester,
  ) async {
    var recoveryTapped = false;
    await tester.pumpWidget(
      scene(
        day: buildDay(vitality: GardenVitality.thirsty),
        onFocus: () {},
        onRecovery: () => recoveryTapped = true,
      ),
    );

    expect(find.text('Your plot is taking shape'), findsOneWidget);
    expect(find.text('A small reset is enough'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Offer a two-minute reset'));
    await tester.pump(const Duration(milliseconds: 160));

    expect(recoveryTapped, isTrue);
  });
}
