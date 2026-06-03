import 'package:drift/drift.dart';

/// Attention costs — affects Daily Score only, NOT lifetime XP.
/// Separate from XP ledger to keep the "XP only goes up" guarantee.
class AttentionCosts extends Table {
  TextColumn get id => text()();

  TextColumn get costType => textEnum<AttentionCostTypeColumn>()();
  IntColumn get minutesOrCount => integer()();
  IntColumn get dailyScoreImpact => integer()(); // negative value

  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

enum AttentionCostTypeColumn {
  scroll,
  abandonedSession,
  incompleteMit,
}
