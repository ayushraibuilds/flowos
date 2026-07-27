import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/local/database/app_database.dart';

final dataExportServiceProvider = Provider<DataExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return DataExportService(db);
});

class DataExportService {
  final AppDatabase db;

  DataExportService(this.db);

  Future<Map<String, dynamic>> buildExportMap() async {
    final tasks = await db.select(db.tasks).get();
    final focusSessions = await db.select(db.focusSessions).get();
    final xpLedger = await db.select(db.xpLedgerEntries).get();
    final scrollLogs = await db.select(db.scrollLogs).get();
    final energyCheckIns = await db.select(db.energyCheckIns).get();
    final dailyPlans = await db.select(db.dailyPlans).get();
    final dailyReports = await db.select(db.dailyReports).get();
    final achievements = await db.select(db.achievements).get();
    final dailyScores = await db.select(db.dailyScores).get();
    final unlockAttempts = await db.select(db.unlockAttempts).get();
    final deviceUsage = await db.select(db.deviceUsageRecords).get();
    final deviceMetrics = await db.select(db.deviceDayMetrics).get();
    final protectedApps = await db.select(db.protectedApps).get();
    final sleepSchedules = await db.select(db.sleepSchedules).get();

    return {
      'export_version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'manifest': {
        'app': 'FlowOS',
        'schema_version': 10,
        'privacy_notice':
            'Contains sensitive task titles, energy check-ins, focus session metrics, and device attention data. Store securely.',
        'included_tables': [
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
        ],
        'excluded_tables': {
          'attention_costs': 'Static system configuration cost matrix',
          'notification_daily_counts': 'Transient local OS notification queue',
          'processed_notification_batches':
              'Transient local OS notification processing queue',
          'sync_outbox': 'Internal transient syncing outbox queue',
        },
      },
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'focus_sessions': focusSessions.map((s) => s.toJson()).toList(),
      'xp_ledger': xpLedger.map((x) => x.toJson()).toList(),
      'scroll_logs': scrollLogs.map((l) => l.toJson()).toList(),
      'energy_checkins': energyCheckIns.map((e) => e.toJson()).toList(),
      'daily_plans': dailyPlans.map((p) => p.toJson()).toList(),
      'daily_reports': dailyReports.map((r) => r.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'daily_scores': dailyScores.map((s) => s.toJson()).toList(),
      'unlock_attempts': unlockAttempts.map((u) => u.toJson()).toList(),
      'device_usage_records': deviceUsage.map((u) => u.toJson()).toList(),
      'device_day_metrics': deviceMetrics.map((m) => m.toJson()).toList(),
      'protected_apps': protectedApps.map((a) => a.toJson()).toList(),
      'sleep_schedules': sleepSchedules.map((s) => s.toJson()).toList(),
    };
  }

  Future<String> serializeData() async {
    final exportMap = await buildExportMap();
    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  Future<File> generateExportFile() async {
    final tempDir = await getTemporaryDirectory();
    await cleanupOldExportFiles(tempDir);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = p.join(tempDir.path, 'flowos_data_export_$timestamp.json');
    final file = File(filePath);
    final jsonStr = await serializeData();
    await file.writeAsString(jsonStr);
    return file;
  }

  Future<void> cleanupOldExportFiles([Directory? dir]) async {
    try {
      final tempDir = dir ?? await getTemporaryDirectory();
      final entities = tempDir.listSync();
      for (final entity in entities) {
        if (entity is File &&
            p.basename(entity.path).startsWith('flowos_data_export_')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up export files: $e');
    }
  }

  Future<void> exportAndShare() async {
    final file = await generateExportFile();
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'FlowOS Data Export'),
    );
  }
}
