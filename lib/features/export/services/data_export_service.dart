import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/local/database/app_database.dart';

final dataExportServiceProvider = Provider<DataExportService>((ref) {
  final db = ref.watch(databaseProvider);
  return DataExportService(db);
});

class DataExportService {
  final AppDatabase db;

  DataExportService(this.db);

  Future<String> serializeData() async {
    final tasks = await db.select(db.tasks).get();
    final focusSessions = await db.select(db.focusSessions).get();
    final xpLedger = await db.select(db.xpLedgerEntries).get();
    final attentionCosts = await db.select(db.attentionCosts).get();
    final scrollLogs = await db.select(db.scrollLogs).get();
    final energyCheckIns = await db.select(db.energyCheckIns).get();
    final dailyPlans = await db.select(db.dailyPlans).get();
    final dailyReports = await db.select(db.dailyReports).get();
    final achievements = await db.select(db.achievements).get();

    final exportMap = {
      'export_version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'focus_sessions': focusSessions.map((s) => s.toJson()).toList(),
      'xp_ledger': xpLedger.map((x) => x.toJson()).toList(),
      'attention_costs': attentionCosts.map((c) => c.toJson()).toList(),
      'scroll_logs': scrollLogs.map((l) => l.toJson()).toList(),
      'energy_checkins': energyCheckIns.map((e) => e.toJson()).toList(),
      'daily_plans': dailyPlans.map((p) => p.toJson()).toList(),
      'daily_reports': dailyReports.map((r) => r.toJson()).toList(),
      'achievements': achievements.map((a) => a.toJson()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  Future<void> exportAndShare() async {
    final jsonStr = await serializeData();
    await SharePlus.instance.share(ShareParams(
      text: jsonStr,
      subject: 'FlowOS Backup Data',
    ));
  }
}
