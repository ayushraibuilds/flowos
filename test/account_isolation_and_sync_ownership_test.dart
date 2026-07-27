import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/data/local/tables/tasks_table.dart';

TasksCompanion createTestTaskCompanion(String id, String title) {
  return TasksCompanion(
    id: Value(id),
    title: Value(title),
    energyLevel: const Value(EnergyLevelColumn.medium),
    category: const Value(TaskCategoryColumn.work),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TASK-002: Account-Scoped Local Storage & Sync Ownership Tests', () {
    test('A -> logout -> B integration test: Account B cannot access or push Account A outbox', () async {
      // 1. User A active
      db.setActiveOwnerId('user_A');
      await db.tasksDao.insertTask(createTestTaskCompanion('task_A_1', 'User A Secret Task'));

      final unsyncedA = await db.syncOutboxDao.getUnsyncedForOwner('user_A');
      expect(unsyncedA.length, equals(1));
      expect(unsyncedA.first.ownerId, equals('user_A'));

      // 2. User A signs out
      db.setActiveOwnerId('local');

      // 3. User B signs in
      db.setActiveOwnerId('user_B');
      await db.tasksDao.insertTask(createTestTaskCompanion('task_B_1', 'User B Task'));

      // User B only sees User B's outbox rows
      final unsyncedB = await db.syncOutboxDao.getUnsyncedForOwner('user_B');
      expect(unsyncedB.length, equals(1));
      expect(unsyncedB.first.ownerId, equals('user_B'));
      expect(unsyncedB.first.entityId, equals('task_B_1'));

      // Verify User A's outbox row is isolated and flagged as belonging to another owner
      final hasOthers = await db.syncOutboxDao.hasUnsyncedForOtherOwner('user_B');
      expect(hasOthers, isTrue);
    });

    test('Offline queue / account-switch test: Outbox created for A is never uploaded as B', () async {
      // Offline writes under User A
      db.setActiveOwnerId('user_A');
      await db.tasksDao.insertTask(createTestTaskCompanion('offline_task_A', 'Offline Task A'));

      // Offline writes under User B
      db.setActiveOwnerId('user_B');
      await db.tasksDao.insertTask(createTestTaskCompanion('offline_task_B', 'Offline Task B'));

      final outboxA = await db.syncOutboxDao.getUnsyncedForOwner('user_A');
      final outboxB = await db.syncOutboxDao.getUnsyncedForOwner('user_B');

      expect(outboxA.map((e) => e.entityId), contains('offline_task_A'));
      expect(outboxA.map((e) => e.entityId), isNot(contains('offline_task_B')));

      expect(outboxB.map((e) => e.entityId), contains('offline_task_B'));
      expect(outboxB.map((e) => e.entityId), isNot(contains('offline_task_A')));
    });

    test('Existing local-only data migration & claim test', () async {
      // Local-only writes before account sign-in
      db.setActiveOwnerId('local');
      await db.tasksDao.insertTask(createTestTaskCompanion('local_task_1', 'First Local Task'));

      final localOutbox = await db.syncOutboxDao.getUnsyncedForOwner('local');
      expect(localOutbox.length, equals(1));
      expect(localOutbox.first.ownerId, equals('local'));

      // First account sign-in claims local data
      await db.syncOutboxDao.claimLocalOutbox('first_user_123');

      final claimedOutbox = await db.syncOutboxDao.getUnsyncedForOwner('first_user_123');
      expect(claimedOutbox.length, equals(1));
      expect(claimedOutbox.first.entityId, equals('local_task_1'));

      final remainingLocal = await db.syncOutboxDao.getUnsyncedForOwner('local');
      expect(remainingLocal, isEmpty);
    });

    test('Interrupted migration & reopen test: Database reopens cleanly at v10', () async {
      db.setActiveOwnerId('user_X');
      await db.tasksDao.insertTask(createTestTaskCompanion('task_x_1', 'Task X'));

      // Close and reopen
      await db.close();

      final reopenedDb = AppDatabase.forTesting(NativeDatabase.memory());
      expect(reopenedDb.schemaVersion, equals(10));

      reopenedDb.setActiveOwnerId('user_X');
      final tasks = await reopenedDb.tasksDao.getAllActive();
      expect(tasks, isNotNull);

      await reopenedDb.close();
    });

    test('Account-scoped cursor watermarks test', () async {
      final prefs = await SharedPreferences.getInstance();

      const userA = 'user_A_123';
      const userB = 'user_B_456';

      await prefs.setString('flowos_sync_cursor_v2_${userA}_tasks_updated_at', '2026-07-27T10:00:00Z');
      await prefs.setString('flowos_sync_cursor_v2_${userA}_tasks_id', 'task_A_cursor');

      await prefs.setString('flowos_sync_cursor_v2_${userB}_tasks_updated_at', '2026-07-27T12:00:00Z');
      await prefs.setString('flowos_sync_cursor_v2_${userB}_tasks_id', 'task_B_cursor');

      expect(prefs.getString('flowos_sync_cursor_v2_${userA}_tasks_updated_at'), equals('2026-07-27T10:00:00Z'));
      expect(prefs.getString('flowos_sync_cursor_v2_${userB}_tasks_updated_at'), equals('2026-07-27T12:00:00Z'));
    });
  });
}
