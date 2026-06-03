import 'package:drift/drift.dart';

/// Tasks table — the core productivity unit.
/// Each task carries cognitive load (energy), estimated time, and friction score.
class Tasks extends Table {
  // Primary key
  TextColumn get id => text()();

  // Content
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().withDefault(const Constant(''))();

  // Energy & effort
  IntColumn get energyLevel => intEnum<EnergyLevelColumn>()();
  IntColumn get estimatedMinutes => integer().withDefault(const Constant(25))();
  IntColumn get frictionScore => integer().withDefault(const Constant(0))();

  // Organization
  TextColumn get category => textEnum<TaskCategoryColumn>()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  // MIT (Most Important Task)
  BoolColumn get isMIT => boolean().withDefault(const Constant(false))();

  // Completion
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get xpEarned => integer().withDefault(const Constant(0))();

  // Subtasks
  TextColumn get parentTaskId => text().nullable()();

  // Recurrence
  TextColumn get recurrenceRule => textEnum<RecurrenceRuleColumn>().nullable()();

  // Sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Energy level for Drift column — maps to domain EnergyLevel
enum EnergyLevelColumn { deep, medium, light }

/// Task category for Drift column
enum TaskCategoryColumn { work, personal, health, learning, admin }

/// Recurrence rule for Drift column
enum RecurrenceRuleColumn { daily, weekdays, weekly, monthly }
