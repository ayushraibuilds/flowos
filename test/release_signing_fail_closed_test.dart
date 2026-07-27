import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TASK-009: Release Signing Fail-Closed Tests', () {
    test(
      'build.gradle.kts throws GradleException when key.properties is missing',
      () {
        final gradleFile = File('android/app/build.gradle.kts');
        expect(
          gradleFile.existsSync(),
          isTrue,
          reason: 'android/app/build.gradle.kts must exist',
        );

        final content = gradleFile.readAsStringSync();

        // Must throw GradleException on missing key.properties
        expect(content.contains('throw GradleException('), isTrue);
        expect(content.contains('PRODUCTION RELEASE BUILD FAILED'), isTrue);

        // Must NOT fall back to debug signing config in release
        final releaseBlockMatch = RegExp(
          r'signingConfigs\s*\{[\s\S]*?create\("release"\)\s*\{([\s\S]*?)\}',
        );
        final match = releaseBlockMatch.firstMatch(content);
        expect(match, isNotNull);
        final releaseSigningBody = match!.group(1)!;

        expect(
          releaseSigningBody.contains('signingConfigs.getByName("debug")'),
          isFalse,
        );
      },
    );

    test(
      'android/key.properties.example template exists with required keys',
      () {
        final exampleFile = File('android/key.properties.example');
        expect(
          exampleFile.existsSync(),
          isTrue,
          reason: 'android/key.properties.example must exist',
        );

        final content = exampleFile.readAsStringSync();
        expect(content.contains('storePassword='), isTrue);
        expect(content.contains('keyPassword='), isTrue);
        expect(content.contains('keyAlias='), isTrue);
        expect(content.contains('storeFile='), isTrue);
      },
    );

    test('.gitignore excludes sensitive key.properties and .jks keystores', () {
      final gitignoreFile = File('.gitignore');
      expect(gitignoreFile.existsSync(), isTrue);

      final content = gitignoreFile.readAsStringSync();
      expect(content.contains('**/android/key.properties'), isTrue);
      expect(content.contains('*.jks'), isTrue);
    });
  });
}
