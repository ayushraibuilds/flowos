import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flowos/data/local/database/app_database.dart';
import 'package:flowos/features/ai/models/ai_exception.dart';
import 'package:flowos/features/ai/providers/ai_providers.dart';
import 'package:flowos/features/ai/services/ai_service.dart';
import 'package:flowos/features/auth/services/auth_service.dart';
import 'package:flowos/presentation/screens/brain_dump/brain_dump_screen.dart';

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) fetchHandler;

  MockHttpClientAdapter(this.fetchHandler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return fetchHandler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TASK-005: Authenticated & Offline-Aware AI Client Tests', () {
    test(
      'Logged-out calls reject with unauthenticated error without hitting network',
      () async {
        int adapterCallCount = 0;
        final dio = Dio();

        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          adapterCallCount++;
          return ResponseBody.fromString('{}', 200);
        });

        dio.interceptors.add(
          AuthenticatedAiInterceptor(
            dio: dio,
            tokenSupplier: () async => null, // Logged out
            refreshTokenSupplier: () async => null,
          ),
        );

        final aiService = AiService(dio: dio);
        final result = await aiService.processBrainDump(
          rawText: 'Write unit tests',
        );

        expect(result, isNull);
        expect(aiService.lastError, isNotNull);
        expect(aiService.lastError!.type, equals(AiErrorType.unauthenticated));
        expect(adapterCallCount, equals(0)); // Zero network calls made
      },
    );

    test('Signed-in calls attach Bearer JWT header', () async {
      String? capturedAuthHeader;
      final dio = Dio();

      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        capturedAuthHeader = options.headers['Authorization']?.toString();
        final jsonStr = jsonEncode({
          'tasks': [
            {
              'title': 'Write unit tests',
              'energy_level': 'high',
              'estimated_minutes': 20,
              'friction_score': 0.3,
              'suggested_order': 1,
              'reasoning': 'Priority task',
            },
          ],
        });
        return ResponseBody.fromString(
          jsonStr,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      dio.interceptors.add(
        AuthenticatedAiInterceptor(
          dio: dio,
          tokenSupplier: () async => 'valid_bearer_token_abc',
        ),
      );

      final aiService = AiService(dio: dio);
      final tasks = await aiService.processBrainDump(
        rawText: 'Write unit tests',
      );

      expect(tasks, isNotNull);
      expect(tasks!.length, equals(1));
      expect(capturedAuthHeader, equals('Bearer valid_bearer_token_abc'));
    });

    test('401 response triggers refresh and exactly one retry', () async {
      int adapterCallCount = 0;
      int refreshCount = 0;
      final dio = Dio();

      dio.httpClientAdapter = MockHttpClientAdapter((options) async {
        adapterCallCount++;
        final authHeader = options.headers['Authorization']?.toString();

        if (authHeader == 'Bearer initial_token_123') {
          return ResponseBody.fromString(
            jsonEncode({'detail': 'Unauthorized'}),
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        return ResponseBody.fromString(
          jsonEncode({
            'tasks': [
              {
                'title': 'Retried task',
                'energy_level': 'medium',
                'estimated_minutes': 15,
                'friction_score': 0.2,
                'suggested_order': 1,
                'reasoning': 'Retried successfully',
              },
            ],
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      dio.interceptors.add(
        AuthenticatedAiInterceptor(
          dio: dio,
          tokenSupplier: () async => 'initial_token_123',
          refreshTokenSupplier: () async {
            refreshCount++;
            return 'refreshed_token_456';
          },
        ),
      );

      final aiService = AiService(dio: dio);
      final tasks = await aiService.processBrainDump(rawText: 'Retried task');

      expect(tasks, isNotNull);
      expect(tasks!.length, equals(1));
      expect(adapterCallCount, equals(2)); // Initial 401 + 1 retry
      expect(refreshCount, equals(1)); // Exactly 1 refresh call
    });

    test(
      'Concurrent 401 responses serialize refresh so only 1 refresh executes',
      () async {
        int refreshCount = 0;
        final dio = Dio();

        dio.httpClientAdapter = MockHttpClientAdapter((options) async {
          final authHeader = options.headers['Authorization']?.toString();
          if (authHeader == 'Bearer token_stale') {
            return ResponseBody.fromString(
              jsonEncode({'detail': 'Unauthorized'}),
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }

          return ResponseBody.fromString(
            jsonEncode({
              'tasks': [
                {
                  'title': 'Task',
                  'energy_level': 'medium',
                  'estimated_minutes': 15,
                  'friction_score': 0.2,
                  'suggested_order': 1,
                  'reasoning': 'Ok',
                },
              ],
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        });

        dio.interceptors.add(
          AuthenticatedAiInterceptor(
            dio: dio,
            tokenSupplier: () async => 'token_stale',
            refreshTokenSupplier: () async {
              refreshCount++;
              await Future.delayed(const Duration(milliseconds: 50));
              return 'token_fresh';
            },
          ),
        );

        final aiService = AiService(dio: dio);

        final results = await Future.wait([
          aiService.processBrainDump(rawText: 'Task 1'),
          aiService.processBrainDump(rawText: 'Task 2'),
          aiService.processBrainDump(rawText: 'Task 3'),
        ]);

        expect(results.every((r) => r != null), isTrue);
        expect(
          refreshCount,
          equals(1),
        ); // Serialized refresh lock executed only ONCE!
      },
    );

    test(
      'DioException mapping for offline, timeout, quotaExceeded, serverError',
      () {
        final reqOptions = RequestOptions(path: '/ai/test');

        final offlineExc = AuthenticatedAiInterceptor.mapDioException(
          DioException(
            requestOptions: reqOptions,
            type: DioExceptionType.connectionError,
          ),
        );
        expect(offlineExc.type, equals(AiErrorType.offline));

        final timeoutExc = AuthenticatedAiInterceptor.mapDioException(
          DioException(
            requestOptions: reqOptions,
            type: DioExceptionType.receiveTimeout,
          ),
        );
        expect(timeoutExc.type, equals(AiErrorType.timeout));

        final quotaExc = AuthenticatedAiInterceptor.mapDioException(
          DioException(
            requestOptions: reqOptions,
            response: Response(requestOptions: reqOptions, statusCode: 429),
          ),
        );
        expect(quotaExc.type, equals(AiErrorType.quotaExceeded));

        final serverExc = AuthenticatedAiInterceptor.mapDioException(
          DioException(
            requestOptions: reqOptions,
            response: Response(requestOptions: reqOptions, statusCode: 500),
          ),
        );
        expect(serverExc.type, equals(AiErrorType.serverError));
      },
    );

    testWidgets(
      'BrainDumpScreen presents Local Mode feedback when logged out',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);

        final mockAiService = AiService(tokenSupplier: () async => null);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              isLoggedInProvider.overrideWithValue(false),
              aiServiceProvider.overrideWithValue(mockAiService),
            ],
            child: const MaterialApp(home: BrainDumpScreen()),
          ),
        );

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'Plan sprint tasks');
        await tester.pump();

        final submitBtn = find.byType(ElevatedButton);
        expect(submitBtn, findsOneWidget);
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('Local Mode'), findsOneWidget);
      },
    );
  });
}
