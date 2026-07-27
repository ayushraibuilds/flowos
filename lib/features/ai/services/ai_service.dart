import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_exception.dart';

/// Interceptor that attaches JWT authorization, serializes token refresh on 401,
/// retries at most once, and maps DioExceptions into normalized AiExceptions.
class AuthenticatedAiInterceptor extends Interceptor {
  final Dio dio;
  final Future<String?> Function()? tokenSupplier;
  final Future<String?> Function()? refreshTokenSupplier;

  static Future<String?>? _sharedRefreshFuture;

  AuthenticatedAiInterceptor({
    required this.dio,
    this.tokenSupplier,
    this.refreshTokenSupplier,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Retried request already has updated Bearer token from onError refresh
    if (options.extra['retried'] == true && options.headers.containsKey('Authorization')) {
      if (!options.headers.containsKey('X-Request-ID')) {
        options.headers['X-Request-ID'] =
            'ai_req_${DateTime.now().microsecondsSinceEpoch}';
      }
      return handler.next(options);
    }
    if (tokenSupplier != null) {
      try {
        final token = await tokenSupplier!();
        if (token == null || token.isEmpty) {
          // Logged-out call: do NOT hit paid cloud endpoints under invented identity
          return handler.reject(
            DioException(
              requestOptions: options,
              error: const AiException(
                type: AiErrorType.unauthenticated,
                message: 'Cloud AI features require sign-in.',
              ),
              type: DioExceptionType.cancel,
            ),
          );
        }
        options.headers['Authorization'] = 'Bearer $token';
      } catch (e) {
        return handler.reject(
          DioException(
            requestOptions: options,
            error: AiException(
              type: AiErrorType.unauthenticated,
              message: 'Failed to retrieve auth token: $e',
            ),
            type: DioExceptionType.cancel,
          ),
        );
      }
    } else {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: const AiException(
            type: AiErrorType.unauthenticated,
            message: 'Cloud AI features require sign-in.',
          ),
          type: DioExceptionType.cancel,
        ),
      );
    }

    if (!options.headers.containsKey('X-Request-ID')) {
      options.headers['X-Request-ID'] =
          'ai_req_${DateTime.now().microsecondsSinceEpoch}';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;

    // Check 401 Unauthorized for retry
    if (statusCode == 401 && refreshTokenSupplier != null) {
      final isAlreadyRetried = err.requestOptions.extra['retried'] == true;
      if (!isAlreadyRetried) {
        err.requestOptions.extra['retried'] = true;

        try {
          // Serialize concurrent 401 token refreshes to avoid refresh storms
          _sharedRefreshFuture ??= refreshTokenSupplier!().whenComplete(() {
            _sharedRefreshFuture = null;
          });

          final newToken = await _sharedRefreshFuture;
          if (newToken != null && newToken.isNotEmpty) {
            final retryHeaders = Map<String, dynamic>.from(err.requestOptions.headers);
            retryHeaders['Authorization'] = 'Bearer $newToken';

            final retryExtra = Map<String, dynamic>.from(err.requestOptions.extra);
            retryExtra['retried'] = true;

            final retryOptions = err.requestOptions.copyWith(
              headers: retryHeaders,
              extra: retryExtra,
            );

            final response = await dio.fetch(retryOptions);
            return handler.resolve(response);
          }
        } catch (e, st) {
          debugPrint('Retry failed in AuthenticatedAiInterceptor: $e\n$st');
        }
      }
    }

    final normalized = mapDioException(err);
    return handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: normalized,
      ),
    );
  }

  static AiException mapDioException(DioException err) {
    if (err.error is AiException) {
      return err.error as AiException;
    }

    final statusCode = err.response?.statusCode;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return AiException(
        type: AiErrorType.timeout,
        message: 'AI request timed out.',
        statusCode: statusCode,
      );
    }

    if (err.type == DioExceptionType.connectionError ||
        err.error is TimeoutException ||
        err.message?.contains('SocketException') == true) {
      return const AiException(
        type: AiErrorType.offline,
        message: 'Network unavailable or AI backend unreachable.',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return AiException(
        type: AiErrorType.unauthorized,
        message: 'Authentication failed or expired.',
        statusCode: statusCode,
      );
    }

    if (statusCode == 429) {
      return AiException(
        type: AiErrorType.quotaExceeded,
        message: 'AI rate limit reached. Please try again shortly.',
        statusCode: statusCode,
      );
    }

    if (statusCode == 422) {
      return AiException(
        type: AiErrorType.validationError,
        message: 'Invalid AI prompt payload format.',
        statusCode: statusCode,
      );
    }

    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return AiException(
        type: AiErrorType.serverError,
        message: 'AI backend service error ($statusCode).',
        statusCode: statusCode,
      );
    }

    return AiException(
      type: AiErrorType.unknown,
      message: err.message ?? 'An unexpected AI error occurred.',
      statusCode: statusCode,
    );
  }
}

/// FlowOS AI Service — calls the FastAPI backend proxy.
/// Never calls AI providers directly. All LLM traffic goes through the proxy.
class AiService {
  late final Dio _dio;
  AiException? _lastError;

  AiException? get lastError => _lastError;

  /// Base URL for the AI backend.
  static const _devUrl = 'http://10.0.2.2:8000'; // Android emulator -> host
  static const _iosDevUrl = 'http://localhost:8000';
  static const _prodUrl = String.fromEnvironment(
    'AI_BACKEND_URL',
    defaultValue: 'https://flowos-api.railway.app',
  );

  AiService({
    Future<String?> Function()? tokenSupplier,
    Future<String?> Function()? refreshTokenSupplier,
    Dio? dio,
  }) {
    if (dio != null) {
      _dio = dio;
    } else {
      final baseUrl = kDebugMode
          ? (defaultTargetPlatform == TargetPlatform.iOS ? _iosDevUrl : _devUrl)
          : _prodUrl;

      _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ));

      _dio.interceptors.add(AuthenticatedAiInterceptor(
        dio: _dio,
        tokenSupplier: tokenSupplier,
        refreshTokenSupplier: refreshTokenSupplier,
      ));
    }
  }

  // ─── Daily Report ──────────────────────────────────────────────

  /// Generate AI daily report. Returns null on failure (caller uses local fallback).
  Future<DailyReportInsight?> generateDailyReport({
    required Map<String, dynamic> dailyData,
  }) async {
    _lastError = null;
    try {
      final response = await _dio.post('/ai/daily-report', data: dailyData);
      if (response.statusCode == 200) {
        final data = response.data;
        return DailyReportInsight.fromJson(data['insight']);
      }
    } on DioException catch (e) {
      _lastError = e.error is AiException
          ? (e.error as AiException)
          : AuthenticatedAiInterceptor.mapDioException(e);
      debugPrint('AI daily report failed: $_lastError');
    } catch (e) {
      _lastError = AiException(
        type: AiErrorType.unknown,
        message: e.toString(),
      );
      debugPrint('AI daily report failed: $e');
    }
    return null;
  }

  // ─── Break Suggestion ─────────────────────────────────────────

  /// Get break content suggestion. Returns null on failure (caller uses local fallback).
  Future<BreakContent?> getBreakSuggestion({
    required Map<String, dynamic> sessionData,
  }) async {
    _lastError = null;
    try {
      final response =
          await _dio.post('/ai/break-suggestion', data: sessionData);
      if (response.statusCode == 200) {
        return BreakContent.fromJson(response.data);
      }
    } on DioException catch (e) {
      _lastError = e.error is AiException
          ? (e.error as AiException)
          : AuthenticatedAiInterceptor.mapDioException(e);
      debugPrint('AI break suggestion failed: $_lastError');
    } catch (e) {
      _lastError = AiException(
        type: AiErrorType.unknown,
        message: e.toString(),
      );
      debugPrint('AI break suggestion failed: $e');
    }
    return null;
  }

  // ─── Brain Dump ────────────────────────────────────────────────

  /// Process brain dump text into sorted tasks. Returns null on failure.
  Future<List<BrainDumpTask>?> processBrainDump({
    required String rawText,
    int? currentEnergy,
  }) async {
    _lastError = null;
    try {
      final response = await _dio.post('/ai/brain-dump', data: {
        'raw_text': rawText,
        'current_energy': currentEnergy,
        'prompt_version': 1,
      });
      if (response.statusCode == 200) {
        final tasks = (response.data['tasks'] as List)
            .map((t) => BrainDumpTask.fromJson(t))
            .toList();
        return tasks;
      }
    } on DioException catch (e) {
      _lastError = e.error is AiException
          ? (e.error as AiException)
          : AuthenticatedAiInterceptor.mapDioException(e);
      debugPrint('AI brain dump failed: $_lastError');
    } catch (e) {
      _lastError = AiException(
        type: AiErrorType.unknown,
        message: e.toString(),
      );
      debugPrint('AI brain dump failed: $e');
    }
    return null;
  }

  // ─── Weekly Review ─────────────────────────────────────────────

  /// Generate weekly review insights. Returns null on failure.
  Future<WeeklyReview?> generateWeeklyReview({
    required Map<String, dynamic> weekData,
  }) async {
    _lastError = null;
    try {
      final response = await _dio.post('/ai/weekly-review', data: weekData);
      if (response.statusCode == 200) {
        return WeeklyReview.fromJson(response.data);
      }
    } on DioException catch (e) {
      _lastError = e.error is AiException
          ? (e.error as AiException)
          : AuthenticatedAiInterceptor.mapDioException(e);
      debugPrint('AI weekly review failed: $_lastError');
    } catch (e) {
      _lastError = AiException(
        type: AiErrorType.unknown,
        message: e.toString(),
      );
      debugPrint('AI weekly review failed: $e');
    }
    return null;
  }

  // ─── Health ────────────────────────────────────────────────────

  Future<bool> isBackendReachable() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ─── Data classes (simple, no Freezed needed for API responses) ──

class DailyReportInsight {
  final String headline;
  final String highlight;
  final String growthArea;
  final String energyInsight;
  final String tomorrowTip;

  DailyReportInsight({
    required this.headline,
    required this.highlight,
    required this.growthArea,
    required this.energyInsight,
    required this.tomorrowTip,
  });

  factory DailyReportInsight.fromJson(Map<String, dynamic> json) {
    return DailyReportInsight(
      headline: json['headline'] ?? '',
      highlight: json['highlight'] ?? '',
      growthArea: json['growth_area'] ?? '',
      energyInsight: json['energy_insight'] ?? '',
      tomorrowTip: json['tomorrow_tip'] ?? '',
    );
  }

  /// Local fallback when AI is unreachable
  factory DailyReportInsight.fallback() {
    return DailyReportInsight(
      headline: 'Day in review — check your stats below.',
      highlight: 'You showed up today. That matters more than any score.',
      growthArea: 'Try setting your MITs before 9 AM tomorrow.',
      energyInsight: 'Track energy 3x daily to unlock personalized insights.',
      tomorrowTip: 'Pick one deep task first thing. Momentum builds from there.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'highlight': highlight,
      'growth_area': growthArea,
      'energy_insight': energyInsight,
      'tomorrow_tip': tomorrowTip,
    };
  }
}

class BreakContent {
  final String contentType;
  final String content;
  final String? answer;
  final String? source;

  BreakContent({
    required this.contentType,
    required this.content,
    this.answer,
    this.source,
  });

  factory BreakContent.fromJson(Map<String, dynamic> json) {
    return BreakContent(
      contentType: json['content_type'] ?? 'riddle',
      content: json['content'] ?? '',
      answer: json['answer'],
      source: json['source'],
    );
  }
}

class BrainDumpTask {
  final String title;
  final String energyLevel;
  final int estimatedMinutes;
  final double frictionScore;
  final int suggestedOrder;
  final String reasoning;

  BrainDumpTask({
    required this.title,
    required this.energyLevel,
    required this.estimatedMinutes,
    required this.frictionScore,
    required this.suggestedOrder,
    required this.reasoning,
  });

  factory BrainDumpTask.fromJson(Map<String, dynamic> json) {
    return BrainDumpTask(
      title: json['title'] ?? '',
      energyLevel: json['energy_level'] ?? 'medium',
      estimatedMinutes: json['estimated_minutes'] ?? 25,
      frictionScore: (json['friction_score'] ?? 0.5).toDouble(),
      suggestedOrder: json['suggested_order'] ?? 0,
      reasoning: json['reasoning'] ?? '',
    );
  }
}

class WeeklyReview {
  final String summary;
  final List<String> wins;
  final List<String> growthAreas;
  final List<String> reflectionQuestions;
  final String nextWeekFocus;

  WeeklyReview({
    required this.summary,
    required this.wins,
    required this.growthAreas,
    required this.reflectionQuestions,
    required this.nextWeekFocus,
  });

  factory WeeklyReview.fromJson(Map<String, dynamic> json) {
    return WeeklyReview(
      summary: json['summary'] ?? '',
      wins: List<String>.from(json['wins'] ?? []),
      growthAreas: List<String>.from(json['growth_areas'] ?? []),
      reflectionQuestions: List<String>.from(json['reflection_questions'] ?? []),
      nextWeekFocus: json['next_week_focus'] ?? '',
    );
  }
}
