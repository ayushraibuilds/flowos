import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/export/services/data_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DataExportService service;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = DataExportService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TASK-015: Truthful Data Export & Backup Behavior Tests', () {
    test(
      'buildExportMap includes version 2, manifest, and all 14 user tables',
      () async {
        final exportMap = await service.buildExportMap();

        expect(exportMap['export_version'], equals(2));
        expect(exportMap['exported_at'], isNotNull);

        final manifest = exportMap['manifest'] as Map<String, dynamic>;
        expect(manifest['app'], equals('FlowOS'));
        expect(manifest['schema_version'], equals(10));
        expect(
          manifest['privacy_notice'],
          contains('Contains sensitive task titles'),
        );

        final included = manifest['included_tables'] as List;
        expect(included.length, equals(14));
        expect(
          included,
          containsAll([
            'tasks',
            'focus_sessions',
            'xp_ledger',
            'scroll_logs',
            'energy_checkins',
            'daily_plans',
            'daily_reports',
            'achievements',
            'daily_scores',
            'unlock_attempts',
            'device_usage_records',
            'device_day_metrics',
            'protected_apps',
            'sleep_schedules',
          ]),
        );

        final excluded = manifest['excluded_tables'] as Map<String, dynamic>;
        expect(
          excluded.keys,
          containsAll([
            'attention_costs',
            'notification_daily_counts',
            'processed_notification_batches',
            'sync_outbox',
          ]),
        );
      },
    );

    test(
      'Temporary file generation and cleanup deletes old export files',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'flowos_export_test',
        );

        final oldFile = File('${tempDir.path}/flowos_data_export_1000.json');
        await oldFile.writeAsString('{"old": true}');
        expect(oldFile.existsSync(), isTrue);

        await service.cleanupOldExportFiles(tempDir);
        expect(oldFile.existsSync(), isFalse);

        await tempDir.delete(recursive: true);
      },
    );

    test(
      'Android backup XML rules exclude sensitive SQLite and session files',
      () {
        final extractionRules = File(
          'android/app/src/main/res/xml/data_extraction_rules.xml',
        );
        expect(extractionRules.existsSync(), isTrue);
        final extractionContent = extractionRules.readAsStringSync();
        expect(
          extractionContent,
          contains('<exclude domain="database" path="flowos.sqlite" />'),
        );
        expect(
          extractionContent,
          contains(
            '<exclude domain="sharedpref" path="flowos_active_session_id.xml" />',
          ),
        );

        final fullBackup = File(
          'android/app/src/main/res/xml/full_backup_content.xml',
        );
        expect(fullBackup.existsSync(), isTrue);
        final backupContent = fullBackup.readAsStringSync();
        expect(
          backupContent,
          contains('<exclude domain="database" path="flowos.sqlite" />'),
        );
      },
    );
  });
}
