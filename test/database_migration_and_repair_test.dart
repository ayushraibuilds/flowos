import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as ffi;

import 'package:flowos/data/local/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-007: Database Migration Fixtures & Schema Repair Tests', () {
    test(
      'Fresh database initializes cleanly at current schema version 10',
      () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final versionResult = await db
            .customSelect('PRAGMA user_version;')
            .getSingle();
        final version = versionResult.read<int>('user_version');
        expect(version, equals(10));

        final tasks = await db.select(db.tasks).get();
        expect(tasks, isEmpty);
      },
    );

    test(
      'v1 database fixture upgrades to v10 while preserving legacy rows',
      () async {
        final rawDb = ffi.sqlite3.openInMemory();
        rawDb.execute('PRAGMA user_version = 1;');

        // Create v1 tables
        rawDb.execute('''
        CREATE TABLE tasks (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
      ''');
        rawDb.execute('''
        CREATE TABLE focus_sessions (
          id TEXT NOT NULL PRIMARY KEY,
          duration_minutes INTEGER NOT NULL,
          completed_at INTEGER NOT NULL
        );
      ''');
        rawDb.execute('''
        CREATE TABLE scroll_logs (
          id TEXT NOT NULL PRIMARY KEY,
          app_name TEXT NOT NULL,
          duration_seconds INTEGER NOT NULL,
          timestamp INTEGER NOT NULL
        );
      ''');
        rawDb.execute('''
        CREATE TABLE daily_plans (
          id TEXT NOT NULL PRIMARY KEY,
          date TEXT NOT NULL,
          created_at INTEGER NOT NULL
        );
      ''');

        // Insert legacy rows
        rawDb.execute('''
        INSERT INTO tasks (id, title, is_completed, created_at)
        VALUES ('task_v1_1', 'Legacy Task 1', 0, 1600000000);
      ''');
        rawDb.execute('''
        INSERT INTO focus_sessions (id, duration_minutes, completed_at)
        VALUES ('focus_v1_1', 25, 1600000500);
      ''');

        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(db.close);

        // Verify upgraded user_version
        final versionResult = await db
            .customSelect('PRAGMA user_version;')
            .getSingle();
        expect(versionResult.read<int>('user_version'), equals(10));

        // Verify legacy row preservation
        final tasks = await db.select(db.tasks).get();
        expect(tasks.length, equals(1));
        expect(tasks.first.id, equals('task_v1_1'));
        expect(tasks.first.title, equals('Legacy Task 1'));
      },
    );

    test(
      'v5 database fixture upgrades to v10 preserving data and adding v10 ownerId',
      () async {
        final rawDb = ffi.sqlite3.openInMemory();
        rawDb.execute('PRAGMA user_version = 5;');

        rawDb.execute('''
        CREATE TABLE tasks (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
      ''');
        rawDb.execute('''
        CREATE TABLE device_usage_records (
          id TEXT NOT NULL PRIMARY KEY,
          package_name TEXT NOT NULL,
          usage_seconds INTEGER NOT NULL,
          recorded_at INTEGER NOT NULL
        );
      ''');

        rawDb.execute('''
        INSERT INTO device_usage_records (id, package_name, usage_seconds, recorded_at)
        VALUES ('usage_1', 'com.example.social', 120, 1600000000);
      ''');

        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(db.close);

        final versionResult = await db
            .customSelect('PRAGMA user_version;')
            .getSingle();
        expect(versionResult.read<int>('user_version'), equals(10));

        final records = await db.select(db.deviceUsageRecords).get();
        expect(records.length, equals(1));
        expect(records.first.packageName, equals('com.example.social'));
      },
    );

    test(
      'Divergent database (observed duplicate column state) repairs without crashing',
      () async {
        final rawDb = ffi.sqlite3.openInMemory();
        // user_version is 4, but physical tables ALREADY contain columns added in future versions
        rawDb.execute('PRAGMA user_version = 4;');

        rawDb.execute('''
        CREATE TABLE device_usage_records (
          id TEXT NOT NULL PRIMARY KEY,
          package_name TEXT NOT NULL,
          usage_seconds INTEGER NOT NULL,
          recorded_at INTEGER NOT NULL,
          source TEXT,
          category TEXT,
          is_distracting INTEGER NOT NULL DEFAULT 0
        );
      ''');
        rawDb.execute('''
        CREATE TABLE device_day_metrics (
          id TEXT NOT NULL PRIMARY KEY,
          date TEXT NOT NULL,
          notification_observed_from INTEGER
        );
      ''');

        rawDb.execute('''
        INSERT INTO device_usage_records (id, package_name, usage_seconds, recorded_at, source)
        VALUES ('div_1', 'com.example.app', 300, 1600000000, 'android_usage');
      ''');

        // Attempting standard addColumn on this DB would fail with "duplicate column name".
        // AppDatabase must handle physical schema check safely.
        final db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
        addTearDown(db.close);

        final versionResult = await db
            .customSelect('PRAGMA user_version;')
            .getSingle();
        expect(versionResult.read<int>('user_version'), equals(10));

        final records = await db.select(db.deviceUsageRecords).get();
        expect(records.length, equals(1));
        expect(records.first.id, equals('div_1'));
      },
    );

    test('Reopening upgraded database is idempotent', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'db_idempotent_test_',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final file = File('${tempDir.path}/test_idem.sqlite');

      final rawDb = ffi.sqlite3.open(file.path);
      rawDb.execute('PRAGMA user_version = 8;');
      rawDb.execute('''
        CREATE TABLE tasks (
          id TEXT NOT NULL PRIMARY KEY,
          title TEXT NOT NULL,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL
        );
      ''');
      rawDb.close();

      final db1 = AppDatabase.forTesting(NativeDatabase(file));
      final version1 =
          (await db1.customSelect('PRAGMA user_version;').getSingle())
              .read<int>('user_version');
      expect(version1, equals(10));
      await db1.close();

      // Second open on same file
      final db2 = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db2.close);
      final version2 =
          (await db2.customSelect('PRAGMA user_version;').getSingle())
              .read<int>('user_version');
      expect(version2, equals(10));
    });

    test(
      'quarantineCorruptDatabase preserves corrupt file copy before reset',
      () {
        final tempDir = Directory.systemTemp.createTempSync('db_corrupt_test_');
        addTearDown(() => tempDir.deleteSync(recursive: true));

        final dbFile = File('${tempDir.path}/test_corrupt.sqlite');
        dbFile.writeAsStringSync('MALFORMED_CORRUPTED_SQLITE_HEADER_DATA');

        quarantineCorruptDatabase(dbFile, 'malformed header');

        expect(dbFile.existsSync(), isFalse); // Original file deleted
        final corruptFiles = tempDir.listSync().where(
          (f) => f.path.contains('.corrupt_'),
        );
        expect(corruptFiles.length, equals(1));
        expect(
          File(corruptFiles.first.path).readAsStringSync(),
          equals('MALFORMED_CORRUPTED_SQLITE_HEADER_DATA'),
        );
      },
    );
  });
}
