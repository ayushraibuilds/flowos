import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowos/presentation/widgets/flow_surface.dart';

void main() {
  group('FlowSurface', () {
    testWidgets('renders child content correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlowSurface(
              child: Text('Hello FlowOS'),
            ),
          ),
        ),
      );

      expect(find.text('Hello FlowOS'), findsOneWidget);
    });

    testWidgets('applies standard variant decoration properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlowSurface(
              variant: FlowSurfaceVariant.standard,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).last;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;

      expect(decoration.borderRadius, isNotNull);
      expect(decoration.border, isNotNull);
    });
  });
}
