import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-019: Deterministic Dependencies and Build Input Tests', () {
    test('pubspec.lock exists and is tracked for build reproducibility', () {
      final lockFile = File('pubspec.lock');
      expect(lockFile.existsSync(), isTrue);
    });

    test(
      'pubspec.yaml declares font families without redundant raw asset directories',
      () {
        final pubspecFile = File('pubspec.yaml');
        expect(pubspecFile.existsSync(), isTrue);
        final content = pubspecFile.readAsStringSync();

        expect(content, contains('family: JetBrainsMono'));
        expect(content, contains('family: Inter'));
        expect(content, isNot(contains('- assets/fonts/')));
        expect(content, isNot(contains('- assets/fonts/ttf/')));
      },
    );

    test('test directory is clean of giant local APK build artifacts', () {
      final testDir = Directory('test');
      expect(testDir.existsSync(), isTrue);

      final apkFiles = testDir
          .listSync(recursive: true)
          .where((e) => e is File && e.path.endsWith('.apk'))
          .toList();

      expect(apkFiles, isEmpty);
    });
  });
}
