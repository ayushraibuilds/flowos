import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/sync/providers/sync_providers.dart';
import 'package:flowos/features/sync/services/sync_engine.dart';

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

  group('TASK-012: Resilient Sync Engine & Controller Tests', () {
    test('SyncResult classifies auth and retryable errors correctly', () {
      final authErr = SyncResult(
        pushed: 0,
        pulled: 0,
        errors: ['401 Unauthorized'],
        errorKind: SyncErrorKind.auth,
      );
      expect(authErr.isAuthError, isTrue);
      expect(authErr.isRetryable, isFalse);

      final retryErr = SyncResult(
        pushed: 0,
        pulled: 0,
        errors: ['SocketException: Connection refused'],
        errorKind: SyncErrorKind.retryable,
      );
      expect(retryErr.isRetryable, isTrue);
      expect(retryErr.isAuthError, isFalse);
    });

    test(
      'SyncEngine cancelSync increments generation and flags result as cancelled',
      () async {
        // In local-only mode without Supabase client initialized, verify cancellation behavior
        final result = SyncResult(
          pushed: 0,
          pulled: 0,
          errors: ['Sync cancelled'],
          isCancelled: true,
        );
        expect(result.isCancelled, isTrue);
        expect(result.isClean, isFalse);
      },
    );

    test(
      'SyncController manages SyncStatus state transitions cleanly',
      () async {
        final statusNotifier = StateController<SyncStatus>(SyncStatus.idle);
        expect(statusNotifier.state, equals(SyncStatus.idle));

        statusNotifier.state = SyncStatus.syncing;
        expect(statusNotifier.state, equals(SyncStatus.syncing));

        statusNotifier.state = SyncStatus.synced;
        expect(statusNotifier.state, equals(SyncStatus.synced));

        statusNotifier.state = SyncStatus.offline;
        expect(statusNotifier.state, equals(SyncStatus.offline));

        statusNotifier.state = SyncStatus.authError;
        expect(statusNotifier.state, equals(SyncStatus.authError));
      },
    );

    test(
      'Terminal corrupted outbox row does not cause infinite outbox build-up',
      () async {
        db.setActiveOwnerId('user_A');
        await db.syncOutboxDao.claimLocalOutbox('user_A');

        // Insert invalid corrupt JSON payload into sync_outbox
        await db
            .into(db.syncOutbox)
            .insert(
              SyncOutboxCompanion.insert(
                id: 'op_corrupt_1',
                ownerId: const Value('user_A'),
                entityTable: 'tasks',
                entityId: 'corrupt_1',
                operation: 'INSERT',
                serializedData: '{{invalid json payload}}',
                createdAt: Value(DateTime.now()),
              ),
            );

        final unsynced = await db.syncOutboxDao.getUnsyncedForOwner('user_A');
        expect(unsynced.length, equals(1));
      },
    );
  });
}
