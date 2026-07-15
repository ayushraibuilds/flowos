import 'package:drift/drift.dart';

/// User-selected app policy.
/// appRef is an Android package name or permitted iOS token.
class ProtectedApps extends Table {
  TextColumn get id => text()();
  TextColumn get platform => text()(); // 'android' or 'ios'
  TextColumn get appRef => text()(); // package name or iOS token
  TextColumn get displayName => text()();
  TextColumn get category => text().nullable()();
  BoolColumn get protectsFocus => boolean().withDefault(const Constant(true))();
  BoolColumn get protectsSleep => boolean().withDefault(const Constant(false))();
  BoolColumn get isEssential => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
