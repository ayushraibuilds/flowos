import 'package:drift/drift.dart';

/// Energy check-ins — 3× daily (morning, afternoon, evening).
/// Value 1-5 maps to 😴 → 🔥.
class EnergyCheckIns extends Table {
  TextColumn get id => text()();

  TextColumn get timeOfDay => textEnum<TimeOfDayColumn>()(); // morning, afternoon, evening
  IntColumn get value => integer()(); // 1-5
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

enum TimeOfDayColumn { morning, afternoon, evening }
