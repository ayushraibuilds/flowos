import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../tables/xp_ledger_table.dart';

part 'xp_ledger_dao.g.dart';

@DriftAccessor(tables: [XpLedgerEntries])
class XpLedgerDao extends DatabaseAccessor<AppDatabase>
    with _$XpLedgerDaoMixin {
  XpLedgerDao(super.db);

  final _uuid = const Uuid();

  Future<XpLedgerEntry?> getById(String id) =>
      (select(xpLedgerEntries)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<void> _recordOutboxUpsert(String id) async {
    final entry = await getById(id);
    if (entry != null) {
      await db.into(db.syncOutbox).insert(SyncOutboxCompanion(
        id: Value(_uuid.v4()),
        entityTable: const Value('xp_ledger'),
        entityId: Value(id),
        operation: const Value('upsert'),
        serializedData: Value(jsonEncode(entry.toJson())),
      ));
    }
  }

  /// APPEND ONLY — the only write operation allowed on the ledger.
  Future<void> appendEntry(XpLedgerEntriesCompanion entry) async {
    await transaction(() async {
      await into(xpLedgerEntries).insert(entry);
      await _recordOutboxUpsert(entry.id.value);
    });
  }

  // ─── Sync Bypass ───────────────────────────────────────────────

  Future<void> appendEntryFromSync(XpLedgerEntriesCompanion entry) => into(xpLedgerEntries).insert(entry);

  /// Get lifetime XP (sum of all pointsDelta)
  Future<int> getLifetimeXP() async {
    final entries = await select(xpLedgerEntries).get();
    return entries.fold<int>(0, (sum, e) => sum + e.pointsDelta);
  }

  /// Watch lifetime XP (reactive)
  Stream<int> watchLifetimeXP() {
    return select(xpLedgerEntries).watch().map(
        (entries) => entries.fold<int>(0, (sum, e) => sum + e.pointsDelta));
  }

  /// Get XP earned today
  Future<int> getDailyXP() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final entries = await (select(xpLedgerEntries)
          ..where((e) => e.timestamp.isBiggerOrEqualValue(start)))
        .get();
    return entries.fold<int>(0, (sum, e) => sum + e.pointsDelta);
  }

  /// Watch daily XP
  Stream<int> watchDailyXP() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return (select(xpLedgerEntries)
          ..where((e) => e.timestamp.isBiggerOrEqualValue(start)))
        .watch()
        .map((entries) =>
            entries.fold<int>(0, (sum, e) => sum + e.pointsDelta));
  }

  /// Get all entries for a date range (for reports)
  Future<List<XpLedgerEntry>> getByDateRange(DateTime start, DateTime end) =>
      (select(xpLedgerEntries)
            ..where((e) =>
                e.timestamp.isBiggerOrEqualValue(start) &
                e.timestamp.isSmallerThanValue(end))
            ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
          .get();

  /// Get recent entries (for drilldown UI)
  Future<List<XpLedgerEntry>> getRecent({int limit = 20}) =>
      (select(xpLedgerEntries)
            ..orderBy([(e) => OrderingTerm.desc(e.timestamp)])
            ..limit(limit))
          .get();

  /// Count entries of a specific type today (for anti-gaming caps)
  Future<int> countTodayByType(XpActionTypeColumn type) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final entries = await (select(xpLedgerEntries)
          ..where((e) =>
              e.timestamp.isBiggerOrEqualValue(start) &
              e.actionType.equalsValue(type)))
        .get();
    return entries.length;
  }

  /// Sum XP from a specific type today (for daily caps)
  Future<int> sumTodayByType(XpActionTypeColumn type) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final entries = await (select(xpLedgerEntries)
          ..where((e) =>
              e.timestamp.isBiggerOrEqualValue(start) &
              e.actionType.equalsValue(type)))
        .get();
    return entries.fold<int>(0, (sum, e) => sum + e.pointsDelta);
  }

  /// Watch lifetime recoveries count
  Stream<int> watchLifetimeRecoveriesCount() {
    return (select(xpLedgerEntries)..where((e) => e.actionType.equalsValue(XpActionTypeColumn.bounceBackBonus)))
        .watch()
        .map((entries) => entries.length);
  }
}
