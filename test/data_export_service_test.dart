import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/tasks_table.dart';
import 'package:flowos/features/export/services/data_export_service.dart';

void main() {
  group('DataExportService', () {
    late AppDatabase db;
    late DataExportService service;

    setUp(() {
      db = AppDatabase.forTesting(DatabaseConnection(NativeDatabase.memory()));
      service = DataExportService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('serializes all 8 tables and includes version & timestamps', () async {
      // Add a mock task
      await db.tasksDao.insertTask(TasksCompanion(
        id: const Value('test-task-123'),
        title: const Value('Test Data Export Task'),
        energyLevel: const Value(EnergyLevelColumn.deep),
        category: const Value(TaskCategoryColumn.work),
        isCompleted: const Value(false),
      ));

      final jsonStr = await service.serializeData();
      final Map<String, dynamic> data = json.decode(jsonStr);

      expect(data['export_version'], 1);
      expect(data.containsKey('exported_at'), true);
      expect(data.containsKey('tasks'), true);
      expect(data.containsKey('focus_sessions'), true);
      expect(data.containsKey('xp_ledger'), true);
      expect(data.containsKey('attention_costs'), true);
      expect(data.containsKey('scroll_logs'), true);
      expect(data.containsKey('energy_checkins'), true);
      expect(data.containsKey('daily_plans'), true);
      expect(data.containsKey('daily_reports'), true);
      expect(data.containsKey('achievements'), true);

      final List tasksList = data['tasks'];
      expect(tasksList.length, 1);
      expect(tasksList.first['title'], 'Test Data Export Task');
      expect(tasksList.first['id'], 'test-task-123');
    });
  });
}
