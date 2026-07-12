import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/tasks_table.dart';
import 'package:flowos/features/tasks/services/task_completion_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late TaskCompletionService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    service = TaskCompletionService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskCompletionService Recurrence Tests', () {
    test('Completing standard task does not spawn new task', () async {
      final task = Task(
        id: 'task-1',
        title: 'Simple Task',
        description: '',
        energyLevel: EnergyLevelColumn.medium,
        estimatedMinutes: 25,
        frictionScore: 0,
        category: TaskCategoryColumn.work,
        dueDate: null,
        sortOrder: 0,
        isMIT: false,
        isCompleted: false,
        completedAt: null,
        xpEarned: 0,
        parentTaskId: null,
        recurrenceRule: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      // Seed the database
      await db.tasksDao.insertTask(TasksCompanion.insert(
        id: 'task-1',
        title: 'Simple Task',
        energyLevel: EnergyLevelColumn.medium,
        category: TaskCategoryColumn.work,
      ));

      await service.completeTask(task);

      final activeTasks = await db.tasksDao.getAllActive();
      // Only the completed task should exist (getAllActive only shows active, but completed tasks are still active unless deleted)
      expect(activeTasks.length, 1);
      expect(activeTasks.first.isCompleted, true);
    });

    test('Completing daily task spawns new task for tomorrow', () async {
      final baseDate = DateTime(2026, 7, 10, 10, 0, 0); // Friday
      final task = Task(
        id: 'task-2',
        title: 'Daily Routine',
        description: '',
        energyLevel: EnergyLevelColumn.light,
        estimatedMinutes: 15,
        frictionScore: 1,
        category: TaskCategoryColumn.personal,
        dueDate: baseDate,
        sortOrder: 0,
        isMIT: false,
        isCompleted: false,
        completedAt: null,
        xpEarned: 0,
        parentTaskId: null,
        recurrenceRule: RecurrenceRuleColumn.daily,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      await db.tasksDao.insertTask(TasksCompanion.insert(
        id: 'task-2',
        title: 'Daily Routine',
        energyLevel: EnergyLevelColumn.light,
        category: TaskCategoryColumn.personal,
        dueDate: Value(baseDate),
        recurrenceRule: const Value(RecurrenceRuleColumn.daily),
      ));

      await service.completeTask(task);

      final activeTasks = await db.tasksDao.getAllActive();
      // Should now have 2 tasks: 1 completed, 1 new incomplete
      expect(activeTasks.length, 2);

      final incomplete = activeTasks.firstWhere((t) => !t.isCompleted);
      expect(incomplete.title, 'Daily Routine');
      expect(incomplete.dueDate, DateTime(2026, 7, 11, 10, 0, 0)); // Saturday
    });

    test('Completing weekday task on Friday spawns new task for Monday', () async {
      final baseDate = DateTime(2026, 7, 10, 10, 0, 0); // Friday
      final task = Task(
        id: 'task-3',
        title: 'Weekday standup',
        description: '',
        energyLevel: EnergyLevelColumn.light,
        estimatedMinutes: 15,
        frictionScore: 1,
        category: TaskCategoryColumn.work,
        dueDate: baseDate,
        sortOrder: 0,
        isMIT: false,
        isCompleted: false,
        completedAt: null,
        xpEarned: 0,
        parentTaskId: null,
        recurrenceRule: RecurrenceRuleColumn.weekdays,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      await db.tasksDao.insertTask(TasksCompanion.insert(
        id: 'task-3',
        title: 'Weekday standup',
        energyLevel: EnergyLevelColumn.light,
        category: TaskCategoryColumn.work,
        dueDate: Value(baseDate),
        recurrenceRule: const Value(RecurrenceRuleColumn.weekdays),
      ));

      await service.completeTask(task);

      final activeTasks = await db.tasksDao.getAllActive();
      expect(activeTasks.length, 2);

      final incomplete = activeTasks.firstWhere((t) => !t.isCompleted);
      expect(incomplete.dueDate, DateTime(2026, 7, 13, 10, 0, 0)); // Monday
    });

    test('Completing weekly task spawns new task in +7 days', () async {
      final baseDate = DateTime(2026, 7, 10, 10, 0, 0); // Friday
      final task = Task(
        id: 'task-4',
        title: 'Weekly Report',
        description: '',
        energyLevel: EnergyLevelColumn.medium,
        estimatedMinutes: 45,
        frictionScore: 2,
        category: TaskCategoryColumn.work,
        dueDate: baseDate,
        sortOrder: 0,
        isMIT: false,
        isCompleted: false,
        completedAt: null,
        xpEarned: 0,
        parentTaskId: null,
        recurrenceRule: RecurrenceRuleColumn.weekly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      await db.tasksDao.insertTask(TasksCompanion.insert(
        id: 'task-4',
        title: 'Weekly Report',
        energyLevel: EnergyLevelColumn.medium,
        category: TaskCategoryColumn.work,
        dueDate: Value(baseDate),
        recurrenceRule: const Value(RecurrenceRuleColumn.weekly),
      ));

      await service.completeTask(task);

      final activeTasks = await db.tasksDao.getAllActive();
      expect(activeTasks.length, 2);

      final incomplete = activeTasks.firstWhere((t) => !t.isCompleted);
      expect(incomplete.dueDate, DateTime(2026, 7, 17, 10, 0, 0)); // Next Friday
    });

    test('Completing monthly task on Jan 31st clamps to Feb 28th', () async {
      final baseDate = DateTime(2026, 1, 31, 12, 0, 0);
      final task = Task(
        id: 'task-5',
        title: 'Monthly Review',
        description: '',
        energyLevel: EnergyLevelColumn.medium,
        estimatedMinutes: 60,
        frictionScore: 2,
        category: TaskCategoryColumn.personal,
        dueDate: baseDate,
        sortOrder: 0,
        isMIT: false,
        isCompleted: false,
        completedAt: null,
        xpEarned: 0,
        parentTaskId: null,
        recurrenceRule: RecurrenceRuleColumn.monthly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        deletedAt: null,
      );

      await db.tasksDao.insertTask(TasksCompanion.insert(
        id: 'task-5',
        title: 'Monthly Review',
        energyLevel: EnergyLevelColumn.medium,
        category: TaskCategoryColumn.personal,
        dueDate: Value(baseDate),
        recurrenceRule: const Value(RecurrenceRuleColumn.monthly),
      ));

      await service.completeTask(task);

      final activeTasks = await db.tasksDao.getAllActive();
      expect(activeTasks.length, 2);

      final incomplete = activeTasks.firstWhere((t) => !t.isCompleted);
      expect(incomplete.dueDate, DateTime(2026, 2, 28, 12, 0, 0)); // Clamped to Feb 28th
    });
  });
}
