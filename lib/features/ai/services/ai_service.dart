import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// FlowOS AI Service — calls the FastAPI backend proxy.
/// Never calls AI providers directly. All LLM traffic goes through the proxy.
class AiService {
  late final Dio _dio;

  /// Base URL for the AI backend.
  /// In development: http://localhost:8000
  /// In production: https://flowos-api.railway.app (or similar)
  static const _devUrl = 'http://10.0.2.2:8000'; // Android emulator → host
  static const _iosDevUrl = 'http://localhost:8000';
  static const _prodUrl = 'https://flowos-api.railway.app'; // TODO: set in .env

  AiService() {
    final baseUrl = kDebugMode
        ? (defaultTargetPlatform == TargetPlatform.iOS ? _iosDevUrl : _devUrl)
        : _prodUrl;

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  // ─── Daily Report ──────────────────────────────────────────────

  /// Generate AI daily report. Returns null on failure (caller uses local fallback).
  Future<DailyReportInsight?> generateDailyReport({
    required Map<String, dynamic> dailyData,
  }) async {
    try {
      final response = await _dio.post('/ai/daily-report', data: dailyData);
      if (response.statusCode == 200) {
        final data = response.data;
        return DailyReportInsight.fromJson(data['insight']);
      }
    } on DioException catch (e) {
      debugPrint('AI daily report failed: ${e.message}');
    }
    return null;
  }

  // ─── Break Suggestion ─────────────────────────────────────────

  /// Get break content suggestion. Returns null on failure (caller uses local fallback).
  Future<BreakContent?> getBreakSuggestion({
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      final response = await _dio.post('/ai/break-suggestion', data: sessionData);
      if (response.statusCode == 200) {
        return BreakContent.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('AI break suggestion failed: ${e.message}');
    }
    return null;
  }

  // ─── Brain Dump ────────────────────────────────────────────────

  /// Process brain dump text into sorted tasks. Returns null on failure.
  Future<List<BrainDumpTask>?> processBrainDump({
    required String rawText,
    int? currentEnergy,
  }) async {
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
      debugPrint('AI brain dump failed: ${e.message}');
    }
    return null;
  }

  // ─── Weekly Review ─────────────────────────────────────────────

  /// Generate weekly review insights. Returns null on failure.
  Future<WeeklyReview?> generateWeeklyReview({
    required Map<String, dynamic> weekData,
  }) async {
    try {
      final response = await _dio.post('/ai/weekly-review', data: weekData);
      if (response.statusCode == 200) {
        return WeeklyReview.fromJson(response.data);
      }
    } on DioException catch (e) {
      debugPrint('AI weekly review failed: ${e.message}');
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
