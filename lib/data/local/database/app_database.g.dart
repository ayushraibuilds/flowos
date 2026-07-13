// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<EnergyLevelColumn, int>
  energyLevel = GeneratedColumn<int>(
    'energy_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  ).withConverter<EnergyLevelColumn>($TasksTable.$converterenergyLevel);
  static const VerificationMeta _estimatedMinutesMeta = const VerificationMeta(
    'estimatedMinutes',
  );
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
    'estimated_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  static const VerificationMeta _frictionScoreMeta = const VerificationMeta(
    'frictionScore',
  );
  @override
  late final GeneratedColumn<int> frictionScore = GeneratedColumn<int>(
    'friction_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskCategoryColumn, String>
  category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TaskCategoryColumn>($TasksTable.$convertercategory);
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isMITMeta = const VerificationMeta('isMIT');
  @override
  late final GeneratedColumn<bool> isMIT = GeneratedColumn<bool>(
    'is_m_i_t',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_m_i_t" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xpEarnedMeta = const VerificationMeta(
    'xpEarned',
  );
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
    'xp_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  @override
  late final GeneratedColumn<String> parentTaskId = GeneratedColumn<String>(
    'parent_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceRuleColumn?, String>
  recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<RecurrenceRuleColumn?>($TasksTable.$converterrecurrenceRulen);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    energyLevel,
    estimatedMinutes,
    frictionScore,
    category,
    dueDate,
    sortOrder,
    isMIT,
    isCompleted,
    completedAt,
    xpEarned,
    parentTaskId,
    recurrenceRule,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
        _estimatedMinutesMeta,
        estimatedMinutes.isAcceptableOrUnknown(
          data['estimated_minutes']!,
          _estimatedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('friction_score')) {
      context.handle(
        _frictionScoreMeta,
        frictionScore.isAcceptableOrUnknown(
          data['friction_score']!,
          _frictionScoreMeta,
        ),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_m_i_t')) {
      context.handle(
        _isMITMeta,
        isMIT.isAcceptableOrUnknown(data['is_m_i_t']!, _isMITMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('xp_earned')) {
      context.handle(
        _xpEarnedMeta,
        xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta),
      );
    }
    if (data.containsKey('parent_task_id')) {
      context.handle(
        _parentTaskIdMeta,
        parentTaskId.isAcceptableOrUnknown(
          data['parent_task_id']!,
          _parentTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      energyLevel: $TasksTable.$converterenergyLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}energy_level'],
        )!,
      ),
      estimatedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_minutes'],
      )!,
      frictionScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}friction_score'],
      )!,
      category: $TasksTable.$convertercategory.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}category'],
        )!,
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isMIT: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_m_i_t'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      xpEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_earned'],
      )!,
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      recurrenceRule: $TasksTable.$converterrecurrenceRulen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}recurrence_rule'],
        ),
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<EnergyLevelColumn, int, int> $converterenergyLevel =
      const EnumIndexConverter<EnergyLevelColumn>(EnergyLevelColumn.values);
  static JsonTypeConverter2<TaskCategoryColumn, String, String>
  $convertercategory = const EnumNameConverter<TaskCategoryColumn>(
    TaskCategoryColumn.values,
  );
  static JsonTypeConverter2<RecurrenceRuleColumn, String, String>
  $converterrecurrenceRule = const EnumNameConverter<RecurrenceRuleColumn>(
    RecurrenceRuleColumn.values,
  );
  static JsonTypeConverter2<RecurrenceRuleColumn?, String?, String?>
  $converterrecurrenceRulen = JsonTypeConverter2.asNullable(
    $converterrecurrenceRule,
  );
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String description;
  final EnergyLevelColumn energyLevel;
  final int estimatedMinutes;
  final int frictionScore;
  final TaskCategoryColumn category;
  final DateTime? dueDate;
  final int sortOrder;
  final bool isMIT;
  final bool isCompleted;
  final DateTime? completedAt;
  final int xpEarned;
  final String? parentTaskId;
  final RecurrenceRuleColumn? recurrenceRule;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.energyLevel,
    required this.estimatedMinutes,
    required this.frictionScore,
    required this.category,
    this.dueDate,
    required this.sortOrder,
    required this.isMIT,
    required this.isCompleted,
    this.completedAt,
    required this.xpEarned,
    this.parentTaskId,
    this.recurrenceRule,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    {
      map['energy_level'] = Variable<int>(
        $TasksTable.$converterenergyLevel.toSql(energyLevel),
      );
    }
    map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    map['friction_score'] = Variable<int>(frictionScore);
    {
      map['category'] = Variable<String>(
        $TasksTable.$convertercategory.toSql(category),
      );
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_m_i_t'] = Variable<bool>(isMIT);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['xp_earned'] = Variable<int>(xpEarned);
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(
        $TasksTable.$converterrecurrenceRulen.toSql(recurrenceRule),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      energyLevel: Value(energyLevel),
      estimatedMinutes: Value(estimatedMinutes),
      frictionScore: Value(frictionScore),
      category: Value(category),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      sortOrder: Value(sortOrder),
      isMIT: Value(isMIT),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      xpEarned: Value(xpEarned),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      energyLevel: $TasksTable.$converterenergyLevel.fromJson(
        serializer.fromJson<int>(json['energyLevel']),
      ),
      estimatedMinutes: serializer.fromJson<int>(json['estimatedMinutes']),
      frictionScore: serializer.fromJson<int>(json['frictionScore']),
      category: $TasksTable.$convertercategory.fromJson(
        serializer.fromJson<String>(json['category']),
      ),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isMIT: serializer.fromJson<bool>(json['isMIT']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      parentTaskId: serializer.fromJson<String?>(json['parentTaskId']),
      recurrenceRule: $TasksTable.$converterrecurrenceRulen.fromJson(
        serializer.fromJson<String?>(json['recurrenceRule']),
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'energyLevel': serializer.toJson<int>(
        $TasksTable.$converterenergyLevel.toJson(energyLevel),
      ),
      'estimatedMinutes': serializer.toJson<int>(estimatedMinutes),
      'frictionScore': serializer.toJson<int>(frictionScore),
      'category': serializer.toJson<String>(
        $TasksTable.$convertercategory.toJson(category),
      ),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isMIT': serializer.toJson<bool>(isMIT),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'parentTaskId': serializer.toJson<String?>(parentTaskId),
      'recurrenceRule': serializer.toJson<String?>(
        $TasksTable.$converterrecurrenceRulen.toJson(recurrenceRule),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    EnergyLevelColumn? energyLevel,
    int? estimatedMinutes,
    int? frictionScore,
    TaskCategoryColumn? category,
    Value<DateTime?> dueDate = const Value.absent(),
    int? sortOrder,
    bool? isMIT,
    bool? isCompleted,
    Value<DateTime?> completedAt = const Value.absent(),
    int? xpEarned,
    Value<String?> parentTaskId = const Value.absent(),
    Value<RecurrenceRuleColumn?> recurrenceRule = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    energyLevel: energyLevel ?? this.energyLevel,
    estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    frictionScore: frictionScore ?? this.frictionScore,
    category: category ?? this.category,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    sortOrder: sortOrder ?? this.sortOrder,
    isMIT: isMIT ?? this.isMIT,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    xpEarned: xpEarned ?? this.xpEarned,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      energyLevel: data.energyLevel.present
          ? data.energyLevel.value
          : this.energyLevel,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
      frictionScore: data.frictionScore.present
          ? data.frictionScore.value
          : this.frictionScore,
      category: data.category.present ? data.category.value : this.category,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isMIT: data.isMIT.present ? data.isMIT.value : this.isMIT,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('frictionScore: $frictionScore, ')
          ..write('category: $category, ')
          ..write('dueDate: $dueDate, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isMIT: $isMIT, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    energyLevel,
    estimatedMinutes,
    frictionScore,
    category,
    dueDate,
    sortOrder,
    isMIT,
    isCompleted,
    completedAt,
    xpEarned,
    parentTaskId,
    recurrenceRule,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.energyLevel == this.energyLevel &&
          other.estimatedMinutes == this.estimatedMinutes &&
          other.frictionScore == this.frictionScore &&
          other.category == this.category &&
          other.dueDate == this.dueDate &&
          other.sortOrder == this.sortOrder &&
          other.isMIT == this.isMIT &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.xpEarned == this.xpEarned &&
          other.parentTaskId == this.parentTaskId &&
          other.recurrenceRule == this.recurrenceRule &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<EnergyLevelColumn> energyLevel;
  final Value<int> estimatedMinutes;
  final Value<int> frictionScore;
  final Value<TaskCategoryColumn> category;
  final Value<DateTime?> dueDate;
  final Value<int> sortOrder;
  final Value<bool> isMIT;
  final Value<bool> isCompleted;
  final Value<DateTime?> completedAt;
  final Value<int> xpEarned;
  final Value<String?> parentTaskId;
  final Value<RecurrenceRuleColumn?> recurrenceRule;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.energyLevel = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.frictionScore = const Value.absent(),
    this.category = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isMIT = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required EnergyLevelColumn energyLevel,
    this.estimatedMinutes = const Value.absent(),
    this.frictionScore = const Value.absent(),
    required TaskCategoryColumn category,
    this.dueDate = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isMIT = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       energyLevel = Value(energyLevel),
       category = Value(category);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? energyLevel,
    Expression<int>? estimatedMinutes,
    Expression<int>? frictionScore,
    Expression<String>? category,
    Expression<DateTime>? dueDate,
    Expression<int>? sortOrder,
    Expression<bool>? isMIT,
    Expression<bool>? isCompleted,
    Expression<DateTime>? completedAt,
    Expression<int>? xpEarned,
    Expression<String>? parentTaskId,
    Expression<String>? recurrenceRule,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (energyLevel != null) 'energy_level': energyLevel,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (frictionScore != null) 'friction_score': frictionScore,
      if (category != null) 'category': category,
      if (dueDate != null) 'due_date': dueDate,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isMIT != null) 'is_m_i_t': isMIT,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<EnergyLevelColumn>? energyLevel,
    Value<int>? estimatedMinutes,
    Value<int>? frictionScore,
    Value<TaskCategoryColumn>? category,
    Value<DateTime?>? dueDate,
    Value<int>? sortOrder,
    Value<bool>? isMIT,
    Value<bool>? isCompleted,
    Value<DateTime?>? completedAt,
    Value<int>? xpEarned,
    Value<String?>? parentTaskId,
    Value<RecurrenceRuleColumn?>? recurrenceRule,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      energyLevel: energyLevel ?? this.energyLevel,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      frictionScore: frictionScore ?? this.frictionScore,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      sortOrder: sortOrder ?? this.sortOrder,
      isMIT: isMIT ?? this.isMIT,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      xpEarned: xpEarned ?? this.xpEarned,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (energyLevel.present) {
      map['energy_level'] = Variable<int>(
        $TasksTable.$converterenergyLevel.toSql(energyLevel.value),
      );
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (frictionScore.present) {
      map['friction_score'] = Variable<int>(frictionScore.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
        $TasksTable.$convertercategory.toSql(category.value),
      );
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isMIT.present) {
      map['is_m_i_t'] = Variable<bool>(isMIT.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(
        $TasksTable.$converterrecurrenceRulen.toSql(recurrenceRule.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('energyLevel: $energyLevel, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('frictionScore: $frictionScore, ')
          ..write('category: $category, ')
          ..write('dueDate: $dueDate, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isMIT: $isMIT, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FocusSessionsTable extends FocusSessions
    with TableInfo<$FocusSessionsTable, FocusSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FocusSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionTypeColumn, String>
  sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<SessionTypeColumn>($FocusSessionsTable.$convertersessionType);
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actualMinutesMeta = const VerificationMeta(
    'actualMinutes',
  );
  @override
  late final GeneratedColumn<int> actualMinutes = GeneratedColumn<int>(
    'actual_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pauseCountMeta = const VerificationMeta(
    'pauseCount',
  );
  @override
  late final GeneratedColumn<int> pauseCount = GeneratedColumn<int>(
    'pause_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _appBackgroundCountMeta =
      const VerificationMeta('appBackgroundCount');
  @override
  late final GeneratedColumn<int> appBackgroundCount = GeneratedColumn<int>(
    'app_background_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ambientSoundMeta = const VerificationMeta(
    'ambientSound',
  );
  @override
  late final GeneratedColumn<String> ambientSound = GeneratedColumn<String>(
    'ambient_sound',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyBeforeMeta = const VerificationMeta(
    'energyBefore',
  );
  @override
  late final GeneratedColumn<int> energyBefore = GeneratedColumn<int>(
    'energy_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyAfterMeta = const VerificationMeta(
    'energyAfter',
  );
  @override
  late final GeneratedColumn<int> energyAfter = GeneratedColumn<int>(
    'energy_after',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _xpEarnedMeta = const VerificationMeta(
    'xpEarned',
  );
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
    'xp_earned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _qualityScoreMeta = const VerificationMeta(
    'qualityScore',
  );
  @override
  late final GeneratedColumn<String> qualityScore = GeneratedColumn<String>(
    'quality_score',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    taskId,
    sessionType,
    durationMinutes,
    actualMinutes,
    pauseCount,
    appBackgroundCount,
    ambientSound,
    energyBefore,
    energyAfter,
    xpEarned,
    qualityScore,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'focus_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<FocusSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('actual_minutes')) {
      context.handle(
        _actualMinutesMeta,
        actualMinutes.isAcceptableOrUnknown(
          data['actual_minutes']!,
          _actualMinutesMeta,
        ),
      );
    }
    if (data.containsKey('pause_count')) {
      context.handle(
        _pauseCountMeta,
        pauseCount.isAcceptableOrUnknown(data['pause_count']!, _pauseCountMeta),
      );
    }
    if (data.containsKey('app_background_count')) {
      context.handle(
        _appBackgroundCountMeta,
        appBackgroundCount.isAcceptableOrUnknown(
          data['app_background_count']!,
          _appBackgroundCountMeta,
        ),
      );
    }
    if (data.containsKey('ambient_sound')) {
      context.handle(
        _ambientSoundMeta,
        ambientSound.isAcceptableOrUnknown(
          data['ambient_sound']!,
          _ambientSoundMeta,
        ),
      );
    }
    if (data.containsKey('energy_before')) {
      context.handle(
        _energyBeforeMeta,
        energyBefore.isAcceptableOrUnknown(
          data['energy_before']!,
          _energyBeforeMeta,
        ),
      );
    }
    if (data.containsKey('energy_after')) {
      context.handle(
        _energyAfterMeta,
        energyAfter.isAcceptableOrUnknown(
          data['energy_after']!,
          _energyAfterMeta,
        ),
      );
    }
    if (data.containsKey('xp_earned')) {
      context.handle(
        _xpEarnedMeta,
        xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta),
      );
    }
    if (data.containsKey('quality_score')) {
      context.handle(
        _qualityScoreMeta,
        qualityScore.isAcceptableOrUnknown(
          data['quality_score']!,
          _qualityScoreMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FocusSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FocusSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      sessionType: $FocusSessionsTable.$convertersessionType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}session_type'],
        )!,
      ),
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      actualMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual_minutes'],
      )!,
      pauseCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pause_count'],
      )!,
      appBackgroundCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}app_background_count'],
      )!,
      ambientSound: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ambient_sound'],
      ),
      energyBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energy_before'],
      ),
      energyAfter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energy_after'],
      ),
      xpEarned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_earned'],
      )!,
      qualityScore: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_score'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $FocusSessionsTable createAlias(String alias) {
    return $FocusSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionTypeColumn, String, String>
  $convertersessionType = const EnumNameConverter<SessionTypeColumn>(
    SessionTypeColumn.values,
  );
}

class FocusSession extends DataClass implements Insertable<FocusSession> {
  final String id;
  final String? taskId;
  final SessionTypeColumn sessionType;
  final int durationMinutes;
  final int actualMinutes;
  final int pauseCount;
  final int appBackgroundCount;
  final String? ambientSound;
  final int? energyBefore;
  final int? energyAfter;
  final int xpEarned;
  final String qualityScore;
  final DateTime startedAt;
  final DateTime? completedAt;
  const FocusSession({
    required this.id,
    this.taskId,
    required this.sessionType,
    required this.durationMinutes,
    required this.actualMinutes,
    required this.pauseCount,
    required this.appBackgroundCount,
    this.ambientSound,
    this.energyBefore,
    this.energyAfter,
    required this.xpEarned,
    required this.qualityScore,
    required this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    {
      map['session_type'] = Variable<String>(
        $FocusSessionsTable.$convertersessionType.toSql(sessionType),
      );
    }
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['actual_minutes'] = Variable<int>(actualMinutes);
    map['pause_count'] = Variable<int>(pauseCount);
    map['app_background_count'] = Variable<int>(appBackgroundCount);
    if (!nullToAbsent || ambientSound != null) {
      map['ambient_sound'] = Variable<String>(ambientSound);
    }
    if (!nullToAbsent || energyBefore != null) {
      map['energy_before'] = Variable<int>(energyBefore);
    }
    if (!nullToAbsent || energyAfter != null) {
      map['energy_after'] = Variable<int>(energyAfter);
    }
    map['xp_earned'] = Variable<int>(xpEarned);
    map['quality_score'] = Variable<String>(qualityScore);
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  FocusSessionsCompanion toCompanion(bool nullToAbsent) {
    return FocusSessionsCompanion(
      id: Value(id),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      sessionType: Value(sessionType),
      durationMinutes: Value(durationMinutes),
      actualMinutes: Value(actualMinutes),
      pauseCount: Value(pauseCount),
      appBackgroundCount: Value(appBackgroundCount),
      ambientSound: ambientSound == null && nullToAbsent
          ? const Value.absent()
          : Value(ambientSound),
      energyBefore: energyBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(energyBefore),
      energyAfter: energyAfter == null && nullToAbsent
          ? const Value.absent()
          : Value(energyAfter),
      xpEarned: Value(xpEarned),
      qualityScore: Value(qualityScore),
      startedAt: Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory FocusSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FocusSession(
      id: serializer.fromJson<String>(json['id']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      sessionType: $FocusSessionsTable.$convertersessionType.fromJson(
        serializer.fromJson<String>(json['sessionType']),
      ),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      actualMinutes: serializer.fromJson<int>(json['actualMinutes']),
      pauseCount: serializer.fromJson<int>(json['pauseCount']),
      appBackgroundCount: serializer.fromJson<int>(json['appBackgroundCount']),
      ambientSound: serializer.fromJson<String?>(json['ambientSound']),
      energyBefore: serializer.fromJson<int?>(json['energyBefore']),
      energyAfter: serializer.fromJson<int?>(json['energyAfter']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      qualityScore: serializer.fromJson<String>(json['qualityScore']),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'taskId': serializer.toJson<String?>(taskId),
      'sessionType': serializer.toJson<String>(
        $FocusSessionsTable.$convertersessionType.toJson(sessionType),
      ),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'actualMinutes': serializer.toJson<int>(actualMinutes),
      'pauseCount': serializer.toJson<int>(pauseCount),
      'appBackgroundCount': serializer.toJson<int>(appBackgroundCount),
      'ambientSound': serializer.toJson<String?>(ambientSound),
      'energyBefore': serializer.toJson<int?>(energyBefore),
      'energyAfter': serializer.toJson<int?>(energyAfter),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'qualityScore': serializer.toJson<String>(qualityScore),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  FocusSession copyWith({
    String? id,
    Value<String?> taskId = const Value.absent(),
    SessionTypeColumn? sessionType,
    int? durationMinutes,
    int? actualMinutes,
    int? pauseCount,
    int? appBackgroundCount,
    Value<String?> ambientSound = const Value.absent(),
    Value<int?> energyBefore = const Value.absent(),
    Value<int?> energyAfter = const Value.absent(),
    int? xpEarned,
    String? qualityScore,
    DateTime? startedAt,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => FocusSession(
    id: id ?? this.id,
    taskId: taskId.present ? taskId.value : this.taskId,
    sessionType: sessionType ?? this.sessionType,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    actualMinutes: actualMinutes ?? this.actualMinutes,
    pauseCount: pauseCount ?? this.pauseCount,
    appBackgroundCount: appBackgroundCount ?? this.appBackgroundCount,
    ambientSound: ambientSound.present ? ambientSound.value : this.ambientSound,
    energyBefore: energyBefore.present ? energyBefore.value : this.energyBefore,
    energyAfter: energyAfter.present ? energyAfter.value : this.energyAfter,
    xpEarned: xpEarned ?? this.xpEarned,
    qualityScore: qualityScore ?? this.qualityScore,
    startedAt: startedAt ?? this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  FocusSession copyWithCompanion(FocusSessionsCompanion data) {
    return FocusSession(
      id: data.id.present ? data.id.value : this.id,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      actualMinutes: data.actualMinutes.present
          ? data.actualMinutes.value
          : this.actualMinutes,
      pauseCount: data.pauseCount.present
          ? data.pauseCount.value
          : this.pauseCount,
      appBackgroundCount: data.appBackgroundCount.present
          ? data.appBackgroundCount.value
          : this.appBackgroundCount,
      ambientSound: data.ambientSound.present
          ? data.ambientSound.value
          : this.ambientSound,
      energyBefore: data.energyBefore.present
          ? data.energyBefore.value
          : this.energyBefore,
      energyAfter: data.energyAfter.present
          ? data.energyAfter.value
          : this.energyAfter,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      qualityScore: data.qualityScore.present
          ? data.qualityScore.value
          : this.qualityScore,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FocusSession(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('sessionType: $sessionType, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('pauseCount: $pauseCount, ')
          ..write('appBackgroundCount: $appBackgroundCount, ')
          ..write('ambientSound: $ambientSound, ')
          ..write('energyBefore: $energyBefore, ')
          ..write('energyAfter: $energyAfter, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    taskId,
    sessionType,
    durationMinutes,
    actualMinutes,
    pauseCount,
    appBackgroundCount,
    ambientSound,
    energyBefore,
    energyAfter,
    xpEarned,
    qualityScore,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FocusSession &&
          other.id == this.id &&
          other.taskId == this.taskId &&
          other.sessionType == this.sessionType &&
          other.durationMinutes == this.durationMinutes &&
          other.actualMinutes == this.actualMinutes &&
          other.pauseCount == this.pauseCount &&
          other.appBackgroundCount == this.appBackgroundCount &&
          other.ambientSound == this.ambientSound &&
          other.energyBefore == this.energyBefore &&
          other.energyAfter == this.energyAfter &&
          other.xpEarned == this.xpEarned &&
          other.qualityScore == this.qualityScore &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class FocusSessionsCompanion extends UpdateCompanion<FocusSession> {
  final Value<String> id;
  final Value<String?> taskId;
  final Value<SessionTypeColumn> sessionType;
  final Value<int> durationMinutes;
  final Value<int> actualMinutes;
  final Value<int> pauseCount;
  final Value<int> appBackgroundCount;
  final Value<String?> ambientSound;
  final Value<int?> energyBefore;
  final Value<int?> energyAfter;
  final Value<int> xpEarned;
  final Value<String> qualityScore;
  final Value<DateTime> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const FocusSessionsCompanion({
    this.id = const Value.absent(),
    this.taskId = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.actualMinutes = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.appBackgroundCount = const Value.absent(),
    this.ambientSound = const Value.absent(),
    this.energyBefore = const Value.absent(),
    this.energyAfter = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.qualityScore = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FocusSessionsCompanion.insert({
    required String id,
    this.taskId = const Value.absent(),
    required SessionTypeColumn sessionType,
    required int durationMinutes,
    this.actualMinutes = const Value.absent(),
    this.pauseCount = const Value.absent(),
    this.appBackgroundCount = const Value.absent(),
    this.ambientSound = const Value.absent(),
    this.energyBefore = const Value.absent(),
    this.energyAfter = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.qualityScore = const Value.absent(),
    required DateTime startedAt,
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sessionType = Value(sessionType),
       durationMinutes = Value(durationMinutes),
       startedAt = Value(startedAt);
  static Insertable<FocusSession> custom({
    Expression<String>? id,
    Expression<String>? taskId,
    Expression<String>? sessionType,
    Expression<int>? durationMinutes,
    Expression<int>? actualMinutes,
    Expression<int>? pauseCount,
    Expression<int>? appBackgroundCount,
    Expression<String>? ambientSound,
    Expression<int>? energyBefore,
    Expression<int>? energyAfter,
    Expression<int>? xpEarned,
    Expression<String>? qualityScore,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (taskId != null) 'task_id': taskId,
      if (sessionType != null) 'session_type': sessionType,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (actualMinutes != null) 'actual_minutes': actualMinutes,
      if (pauseCount != null) 'pause_count': pauseCount,
      if (appBackgroundCount != null)
        'app_background_count': appBackgroundCount,
      if (ambientSound != null) 'ambient_sound': ambientSound,
      if (energyBefore != null) 'energy_before': energyBefore,
      if (energyAfter != null) 'energy_after': energyAfter,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (qualityScore != null) 'quality_score': qualityScore,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FocusSessionsCompanion copyWith({
    Value<String>? id,
    Value<String?>? taskId,
    Value<SessionTypeColumn>? sessionType,
    Value<int>? durationMinutes,
    Value<int>? actualMinutes,
    Value<int>? pauseCount,
    Value<int>? appBackgroundCount,
    Value<String?>? ambientSound,
    Value<int?>? energyBefore,
    Value<int?>? energyAfter,
    Value<int>? xpEarned,
    Value<String>? qualityScore,
    Value<DateTime>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return FocusSessionsCompanion(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      sessionType: sessionType ?? this.sessionType,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      pauseCount: pauseCount ?? this.pauseCount,
      appBackgroundCount: appBackgroundCount ?? this.appBackgroundCount,
      ambientSound: ambientSound ?? this.ambientSound,
      energyBefore: energyBefore ?? this.energyBefore,
      energyAfter: energyAfter ?? this.energyAfter,
      xpEarned: xpEarned ?? this.xpEarned,
      qualityScore: qualityScore ?? this.qualityScore,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(
        $FocusSessionsTable.$convertersessionType.toSql(sessionType.value),
      );
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (actualMinutes.present) {
      map['actual_minutes'] = Variable<int>(actualMinutes.value);
    }
    if (pauseCount.present) {
      map['pause_count'] = Variable<int>(pauseCount.value);
    }
    if (appBackgroundCount.present) {
      map['app_background_count'] = Variable<int>(appBackgroundCount.value);
    }
    if (ambientSound.present) {
      map['ambient_sound'] = Variable<String>(ambientSound.value);
    }
    if (energyBefore.present) {
      map['energy_before'] = Variable<int>(energyBefore.value);
    }
    if (energyAfter.present) {
      map['energy_after'] = Variable<int>(energyAfter.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (qualityScore.present) {
      map['quality_score'] = Variable<String>(qualityScore.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FocusSessionsCompanion(')
          ..write('id: $id, ')
          ..write('taskId: $taskId, ')
          ..write('sessionType: $sessionType, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('actualMinutes: $actualMinutes, ')
          ..write('pauseCount: $pauseCount, ')
          ..write('appBackgroundCount: $appBackgroundCount, ')
          ..write('ambientSound: $ambientSound, ')
          ..write('energyBefore: $energyBefore, ')
          ..write('energyAfter: $energyAfter, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('qualityScore: $qualityScore, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $XpLedgerEntriesTable extends XpLedgerEntries
    with TableInfo<$XpLedgerEntriesTable, XpLedgerEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $XpLedgerEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<XpActionTypeColumn, String>
  actionType =
      GeneratedColumn<String>(
        'action_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<XpActionTypeColumn>(
        $XpLedgerEntriesTable.$converteractionType,
      );
  static const VerificationMeta _pointsDeltaMeta = const VerificationMeta(
    'pointsDelta',
  );
  @override
  late final GeneratedColumn<int> pointsDelta = GeneratedColumn<int>(
    'points_delta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceEntityIdMeta = const VerificationMeta(
    'sourceEntityId',
  );
  @override
  late final GeneratedColumn<String> sourceEntityId = GeneratedColumn<String>(
    'source_entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _explanationMeta = const VerificationMeta(
    'explanation',
  );
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
    'explanation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isReversibleMeta = const VerificationMeta(
    'isReversible',
  );
  @override
  late final GeneratedColumn<bool> isReversible = GeneratedColumn<bool>(
    'is_reversible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_reversible" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  @override
  late final GeneratedColumn<int> promptVersion = GeneratedColumn<int>(
    'prompt_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    actionType,
    pointsDelta,
    sourceEntityId,
    explanation,
    isReversible,
    promptVersion,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'xp_ledger_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<XpLedgerEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('points_delta')) {
      context.handle(
        _pointsDeltaMeta,
        pointsDelta.isAcceptableOrUnknown(
          data['points_delta']!,
          _pointsDeltaMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pointsDeltaMeta);
    }
    if (data.containsKey('source_entity_id')) {
      context.handle(
        _sourceEntityIdMeta,
        sourceEntityId.isAcceptableOrUnknown(
          data['source_entity_id']!,
          _sourceEntityIdMeta,
        ),
      );
    }
    if (data.containsKey('explanation')) {
      context.handle(
        _explanationMeta,
        explanation.isAcceptableOrUnknown(
          data['explanation']!,
          _explanationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_explanationMeta);
    }
    if (data.containsKey('is_reversible')) {
      context.handle(
        _isReversibleMeta,
        isReversible.isAcceptableOrUnknown(
          data['is_reversible']!,
          _isReversibleMeta,
        ),
      );
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  XpLedgerEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return XpLedgerEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      actionType: $XpLedgerEntriesTable.$converteractionType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}action_type'],
        )!,
      ),
      pointsDelta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}points_delta'],
      )!,
      sourceEntityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_entity_id'],
      ),
      explanation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}explanation'],
      )!,
      isReversible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_reversible'],
      )!,
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_version'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $XpLedgerEntriesTable createAlias(String alias) {
    return $XpLedgerEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<XpActionTypeColumn, String, String>
  $converteractionType = const EnumNameConverter<XpActionTypeColumn>(
    XpActionTypeColumn.values,
  );
}

class XpLedgerEntry extends DataClass implements Insertable<XpLedgerEntry> {
  final String id;
  final XpActionTypeColumn actionType;
  final int pointsDelta;
  final String? sourceEntityId;
  final String explanation;
  final bool isReversible;
  final int? promptVersion;
  final DateTime timestamp;
  const XpLedgerEntry({
    required this.id,
    required this.actionType,
    required this.pointsDelta,
    this.sourceEntityId,
    required this.explanation,
    required this.isReversible,
    this.promptVersion,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['action_type'] = Variable<String>(
        $XpLedgerEntriesTable.$converteractionType.toSql(actionType),
      );
    }
    map['points_delta'] = Variable<int>(pointsDelta);
    if (!nullToAbsent || sourceEntityId != null) {
      map['source_entity_id'] = Variable<String>(sourceEntityId);
    }
    map['explanation'] = Variable<String>(explanation);
    map['is_reversible'] = Variable<bool>(isReversible);
    if (!nullToAbsent || promptVersion != null) {
      map['prompt_version'] = Variable<int>(promptVersion);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  XpLedgerEntriesCompanion toCompanion(bool nullToAbsent) {
    return XpLedgerEntriesCompanion(
      id: Value(id),
      actionType: Value(actionType),
      pointsDelta: Value(pointsDelta),
      sourceEntityId: sourceEntityId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceEntityId),
      explanation: Value(explanation),
      isReversible: Value(isReversible),
      promptVersion: promptVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(promptVersion),
      timestamp: Value(timestamp),
    );
  }

  factory XpLedgerEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return XpLedgerEntry(
      id: serializer.fromJson<String>(json['id']),
      actionType: $XpLedgerEntriesTable.$converteractionType.fromJson(
        serializer.fromJson<String>(json['actionType']),
      ),
      pointsDelta: serializer.fromJson<int>(json['pointsDelta']),
      sourceEntityId: serializer.fromJson<String?>(json['sourceEntityId']),
      explanation: serializer.fromJson<String>(json['explanation']),
      isReversible: serializer.fromJson<bool>(json['isReversible']),
      promptVersion: serializer.fromJson<int?>(json['promptVersion']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'actionType': serializer.toJson<String>(
        $XpLedgerEntriesTable.$converteractionType.toJson(actionType),
      ),
      'pointsDelta': serializer.toJson<int>(pointsDelta),
      'sourceEntityId': serializer.toJson<String?>(sourceEntityId),
      'explanation': serializer.toJson<String>(explanation),
      'isReversible': serializer.toJson<bool>(isReversible),
      'promptVersion': serializer.toJson<int?>(promptVersion),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  XpLedgerEntry copyWith({
    String? id,
    XpActionTypeColumn? actionType,
    int? pointsDelta,
    Value<String?> sourceEntityId = const Value.absent(),
    String? explanation,
    bool? isReversible,
    Value<int?> promptVersion = const Value.absent(),
    DateTime? timestamp,
  }) => XpLedgerEntry(
    id: id ?? this.id,
    actionType: actionType ?? this.actionType,
    pointsDelta: pointsDelta ?? this.pointsDelta,
    sourceEntityId: sourceEntityId.present
        ? sourceEntityId.value
        : this.sourceEntityId,
    explanation: explanation ?? this.explanation,
    isReversible: isReversible ?? this.isReversible,
    promptVersion: promptVersion.present
        ? promptVersion.value
        : this.promptVersion,
    timestamp: timestamp ?? this.timestamp,
  );
  XpLedgerEntry copyWithCompanion(XpLedgerEntriesCompanion data) {
    return XpLedgerEntry(
      id: data.id.present ? data.id.value : this.id,
      actionType: data.actionType.present
          ? data.actionType.value
          : this.actionType,
      pointsDelta: data.pointsDelta.present
          ? data.pointsDelta.value
          : this.pointsDelta,
      sourceEntityId: data.sourceEntityId.present
          ? data.sourceEntityId.value
          : this.sourceEntityId,
      explanation: data.explanation.present
          ? data.explanation.value
          : this.explanation,
      isReversible: data.isReversible.present
          ? data.isReversible.value
          : this.isReversible,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('XpLedgerEntry(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('pointsDelta: $pointsDelta, ')
          ..write('sourceEntityId: $sourceEntityId, ')
          ..write('explanation: $explanation, ')
          ..write('isReversible: $isReversible, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    actionType,
    pointsDelta,
    sourceEntityId,
    explanation,
    isReversible,
    promptVersion,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is XpLedgerEntry &&
          other.id == this.id &&
          other.actionType == this.actionType &&
          other.pointsDelta == this.pointsDelta &&
          other.sourceEntityId == this.sourceEntityId &&
          other.explanation == this.explanation &&
          other.isReversible == this.isReversible &&
          other.promptVersion == this.promptVersion &&
          other.timestamp == this.timestamp);
}

class XpLedgerEntriesCompanion extends UpdateCompanion<XpLedgerEntry> {
  final Value<String> id;
  final Value<XpActionTypeColumn> actionType;
  final Value<int> pointsDelta;
  final Value<String?> sourceEntityId;
  final Value<String> explanation;
  final Value<bool> isReversible;
  final Value<int?> promptVersion;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const XpLedgerEntriesCompanion({
    this.id = const Value.absent(),
    this.actionType = const Value.absent(),
    this.pointsDelta = const Value.absent(),
    this.sourceEntityId = const Value.absent(),
    this.explanation = const Value.absent(),
    this.isReversible = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  XpLedgerEntriesCompanion.insert({
    required String id,
    required XpActionTypeColumn actionType,
    required int pointsDelta,
    this.sourceEntityId = const Value.absent(),
    required String explanation,
    this.isReversible = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       actionType = Value(actionType),
       pointsDelta = Value(pointsDelta),
       explanation = Value(explanation);
  static Insertable<XpLedgerEntry> custom({
    Expression<String>? id,
    Expression<String>? actionType,
    Expression<int>? pointsDelta,
    Expression<String>? sourceEntityId,
    Expression<String>? explanation,
    Expression<bool>? isReversible,
    Expression<int>? promptVersion,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (actionType != null) 'action_type': actionType,
      if (pointsDelta != null) 'points_delta': pointsDelta,
      if (sourceEntityId != null) 'source_entity_id': sourceEntityId,
      if (explanation != null) 'explanation': explanation,
      if (isReversible != null) 'is_reversible': isReversible,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  XpLedgerEntriesCompanion copyWith({
    Value<String>? id,
    Value<XpActionTypeColumn>? actionType,
    Value<int>? pointsDelta,
    Value<String?>? sourceEntityId,
    Value<String>? explanation,
    Value<bool>? isReversible,
    Value<int?>? promptVersion,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return XpLedgerEntriesCompanion(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      pointsDelta: pointsDelta ?? this.pointsDelta,
      sourceEntityId: sourceEntityId ?? this.sourceEntityId,
      explanation: explanation ?? this.explanation,
      isReversible: isReversible ?? this.isReversible,
      promptVersion: promptVersion ?? this.promptVersion,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (actionType.present) {
      map['action_type'] = Variable<String>(
        $XpLedgerEntriesTable.$converteractionType.toSql(actionType.value),
      );
    }
    if (pointsDelta.present) {
      map['points_delta'] = Variable<int>(pointsDelta.value);
    }
    if (sourceEntityId.present) {
      map['source_entity_id'] = Variable<String>(sourceEntityId.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (isReversible.present) {
      map['is_reversible'] = Variable<bool>(isReversible.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<int>(promptVersion.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('XpLedgerEntriesCompanion(')
          ..write('id: $id, ')
          ..write('actionType: $actionType, ')
          ..write('pointsDelta: $pointsDelta, ')
          ..write('sourceEntityId: $sourceEntityId, ')
          ..write('explanation: $explanation, ')
          ..write('isReversible: $isReversible, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttentionCostsTable extends AttentionCosts
    with TableInfo<$AttentionCostsTable, AttentionCost> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttentionCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AttentionCostTypeColumn, String>
  costType =
      GeneratedColumn<String>(
        'cost_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AttentionCostTypeColumn>(
        $AttentionCostsTable.$convertercostType,
      );
  static const VerificationMeta _minutesOrCountMeta = const VerificationMeta(
    'minutesOrCount',
  );
  @override
  late final GeneratedColumn<int> minutesOrCount = GeneratedColumn<int>(
    'minutes_or_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyScoreImpactMeta = const VerificationMeta(
    'dailyScoreImpact',
  );
  @override
  late final GeneratedColumn<int> dailyScoreImpact = GeneratedColumn<int>(
    'daily_score_impact',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    costType,
    minutesOrCount,
    dailyScoreImpact,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attention_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttentionCost> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('minutes_or_count')) {
      context.handle(
        _minutesOrCountMeta,
        minutesOrCount.isAcceptableOrUnknown(
          data['minutes_or_count']!,
          _minutesOrCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minutesOrCountMeta);
    }
    if (data.containsKey('daily_score_impact')) {
      context.handle(
        _dailyScoreImpactMeta,
        dailyScoreImpact.isAcceptableOrUnknown(
          data['daily_score_impact']!,
          _dailyScoreImpactMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyScoreImpactMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttentionCost map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttentionCost(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      costType: $AttentionCostsTable.$convertercostType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}cost_type'],
        )!,
      ),
      minutesOrCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_or_count'],
      )!,
      dailyScoreImpact: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_score_impact'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $AttentionCostsTable createAlias(String alias) {
    return $AttentionCostsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AttentionCostTypeColumn, String, String>
  $convertercostType = const EnumNameConverter<AttentionCostTypeColumn>(
    AttentionCostTypeColumn.values,
  );
}

class AttentionCost extends DataClass implements Insertable<AttentionCost> {
  final String id;
  final AttentionCostTypeColumn costType;
  final int minutesOrCount;
  final int dailyScoreImpact;
  final DateTime timestamp;
  const AttentionCost({
    required this.id,
    required this.costType,
    required this.minutesOrCount,
    required this.dailyScoreImpact,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['cost_type'] = Variable<String>(
        $AttentionCostsTable.$convertercostType.toSql(costType),
      );
    }
    map['minutes_or_count'] = Variable<int>(minutesOrCount);
    map['daily_score_impact'] = Variable<int>(dailyScoreImpact);
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  AttentionCostsCompanion toCompanion(bool nullToAbsent) {
    return AttentionCostsCompanion(
      id: Value(id),
      costType: Value(costType),
      minutesOrCount: Value(minutesOrCount),
      dailyScoreImpact: Value(dailyScoreImpact),
      timestamp: Value(timestamp),
    );
  }

  factory AttentionCost.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttentionCost(
      id: serializer.fromJson<String>(json['id']),
      costType: $AttentionCostsTable.$convertercostType.fromJson(
        serializer.fromJson<String>(json['costType']),
      ),
      minutesOrCount: serializer.fromJson<int>(json['minutesOrCount']),
      dailyScoreImpact: serializer.fromJson<int>(json['dailyScoreImpact']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'costType': serializer.toJson<String>(
        $AttentionCostsTable.$convertercostType.toJson(costType),
      ),
      'minutesOrCount': serializer.toJson<int>(minutesOrCount),
      'dailyScoreImpact': serializer.toJson<int>(dailyScoreImpact),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  AttentionCost copyWith({
    String? id,
    AttentionCostTypeColumn? costType,
    int? minutesOrCount,
    int? dailyScoreImpact,
    DateTime? timestamp,
  }) => AttentionCost(
    id: id ?? this.id,
    costType: costType ?? this.costType,
    minutesOrCount: minutesOrCount ?? this.minutesOrCount,
    dailyScoreImpact: dailyScoreImpact ?? this.dailyScoreImpact,
    timestamp: timestamp ?? this.timestamp,
  );
  AttentionCost copyWithCompanion(AttentionCostsCompanion data) {
    return AttentionCost(
      id: data.id.present ? data.id.value : this.id,
      costType: data.costType.present ? data.costType.value : this.costType,
      minutesOrCount: data.minutesOrCount.present
          ? data.minutesOrCount.value
          : this.minutesOrCount,
      dailyScoreImpact: data.dailyScoreImpact.present
          ? data.dailyScoreImpact.value
          : this.dailyScoreImpact,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttentionCost(')
          ..write('id: $id, ')
          ..write('costType: $costType, ')
          ..write('minutesOrCount: $minutesOrCount, ')
          ..write('dailyScoreImpact: $dailyScoreImpact, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, costType, minutesOrCount, dailyScoreImpact, timestamp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttentionCost &&
          other.id == this.id &&
          other.costType == this.costType &&
          other.minutesOrCount == this.minutesOrCount &&
          other.dailyScoreImpact == this.dailyScoreImpact &&
          other.timestamp == this.timestamp);
}

class AttentionCostsCompanion extends UpdateCompanion<AttentionCost> {
  final Value<String> id;
  final Value<AttentionCostTypeColumn> costType;
  final Value<int> minutesOrCount;
  final Value<int> dailyScoreImpact;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const AttentionCostsCompanion({
    this.id = const Value.absent(),
    this.costType = const Value.absent(),
    this.minutesOrCount = const Value.absent(),
    this.dailyScoreImpact = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttentionCostsCompanion.insert({
    required String id,
    required AttentionCostTypeColumn costType,
    required int minutesOrCount,
    required int dailyScoreImpact,
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       costType = Value(costType),
       minutesOrCount = Value(minutesOrCount),
       dailyScoreImpact = Value(dailyScoreImpact);
  static Insertable<AttentionCost> custom({
    Expression<String>? id,
    Expression<String>? costType,
    Expression<int>? minutesOrCount,
    Expression<int>? dailyScoreImpact,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (costType != null) 'cost_type': costType,
      if (minutesOrCount != null) 'minutes_or_count': minutesOrCount,
      if (dailyScoreImpact != null) 'daily_score_impact': dailyScoreImpact,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttentionCostsCompanion copyWith({
    Value<String>? id,
    Value<AttentionCostTypeColumn>? costType,
    Value<int>? minutesOrCount,
    Value<int>? dailyScoreImpact,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return AttentionCostsCompanion(
      id: id ?? this.id,
      costType: costType ?? this.costType,
      minutesOrCount: minutesOrCount ?? this.minutesOrCount,
      dailyScoreImpact: dailyScoreImpact ?? this.dailyScoreImpact,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (costType.present) {
      map['cost_type'] = Variable<String>(
        $AttentionCostsTable.$convertercostType.toSql(costType.value),
      );
    }
    if (minutesOrCount.present) {
      map['minutes_or_count'] = Variable<int>(minutesOrCount.value);
    }
    if (dailyScoreImpact.present) {
      map['daily_score_impact'] = Variable<int>(dailyScoreImpact.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttentionCostsCompanion(')
          ..write('id: $id, ')
          ..write('costType: $costType, ')
          ..write('minutesOrCount: $minutesOrCount, ')
          ..write('dailyScoreImpact: $dailyScoreImpact, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ScrollLogsTable extends ScrollLogs
    with TableInfo<$ScrollLogsTable, ScrollLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ScrollLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyScoreImpactMeta = const VerificationMeta(
    'dailyScoreImpact',
  );
  @override
  late final GeneratedColumn<int> dailyScoreImpact = GeneratedColumn<int>(
    'daily_score_impact',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recoveryActionTakenMeta =
      const VerificationMeta('recoveryActionTaken');
  @override
  late final GeneratedColumn<bool> recoveryActionTaken = GeneratedColumn<bool>(
    'recovery_action_taken',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recovery_action_taken" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _recoveryActionTypeMeta =
      const VerificationMeta('recoveryActionType');
  @override
  late final GeneratedColumn<String> recoveryActionType =
      GeneratedColumn<String>(
        'recovery_action_type',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _intentMeta = const VerificationMeta('intent');
  @override
  late final GeneratedColumn<String> intent = GeneratedColumn<String>(
    'intent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wasTimeboxedMeta = const VerificationMeta(
    'wasTimeboxed',
  );
  @override
  late final GeneratedColumn<bool> wasTimeboxed = GeneratedColumn<bool>(
    'was_timeboxed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_timeboxed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _plannedMinutesMeta = const VerificationMeta(
    'plannedMinutes',
  );
  @override
  late final GeneratedColumn<int> plannedMinutes = GeneratedColumn<int>(
    'planned_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    appName,
    durationMinutes,
    dailyScoreImpact,
    recoveryActionTaken,
    recoveryActionType,
    intent,
    wasTimeboxed,
    plannedMinutes,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scroll_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScrollLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('daily_score_impact')) {
      context.handle(
        _dailyScoreImpactMeta,
        dailyScoreImpact.isAcceptableOrUnknown(
          data['daily_score_impact']!,
          _dailyScoreImpactMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyScoreImpactMeta);
    }
    if (data.containsKey('recovery_action_taken')) {
      context.handle(
        _recoveryActionTakenMeta,
        recoveryActionTaken.isAcceptableOrUnknown(
          data['recovery_action_taken']!,
          _recoveryActionTakenMeta,
        ),
      );
    }
    if (data.containsKey('recovery_action_type')) {
      context.handle(
        _recoveryActionTypeMeta,
        recoveryActionType.isAcceptableOrUnknown(
          data['recovery_action_type']!,
          _recoveryActionTypeMeta,
        ),
      );
    }
    if (data.containsKey('intent')) {
      context.handle(
        _intentMeta,
        intent.isAcceptableOrUnknown(data['intent']!, _intentMeta),
      );
    }
    if (data.containsKey('was_timeboxed')) {
      context.handle(
        _wasTimeboxedMeta,
        wasTimeboxed.isAcceptableOrUnknown(
          data['was_timeboxed']!,
          _wasTimeboxedMeta,
        ),
      );
    }
    if (data.containsKey('planned_minutes')) {
      context.handle(
        _plannedMinutesMeta,
        plannedMinutes.isAcceptableOrUnknown(
          data['planned_minutes']!,
          _plannedMinutesMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScrollLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScrollLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      dailyScoreImpact: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_score_impact'],
      )!,
      recoveryActionTaken: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recovery_action_taken'],
      )!,
      recoveryActionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recovery_action_type'],
      ),
      intent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intent'],
      ),
      wasTimeboxed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_timeboxed'],
      )!,
      plannedMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_minutes'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $ScrollLogsTable createAlias(String alias) {
    return $ScrollLogsTable(attachedDatabase, alias);
  }
}

class ScrollLog extends DataClass implements Insertable<ScrollLog> {
  final String id;
  final String appName;
  final int durationMinutes;
  final int dailyScoreImpact;
  final bool recoveryActionTaken;
  final String? recoveryActionType;
  final String? intent;
  final bool wasTimeboxed;
  final int? plannedMinutes;
  final DateTime timestamp;
  const ScrollLog({
    required this.id,
    required this.appName,
    required this.durationMinutes,
    required this.dailyScoreImpact,
    required this.recoveryActionTaken,
    this.recoveryActionType,
    this.intent,
    required this.wasTimeboxed,
    this.plannedMinutes,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['app_name'] = Variable<String>(appName);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['daily_score_impact'] = Variable<int>(dailyScoreImpact);
    map['recovery_action_taken'] = Variable<bool>(recoveryActionTaken);
    if (!nullToAbsent || recoveryActionType != null) {
      map['recovery_action_type'] = Variable<String>(recoveryActionType);
    }
    if (!nullToAbsent || intent != null) {
      map['intent'] = Variable<String>(intent);
    }
    map['was_timeboxed'] = Variable<bool>(wasTimeboxed);
    if (!nullToAbsent || plannedMinutes != null) {
      map['planned_minutes'] = Variable<int>(plannedMinutes);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  ScrollLogsCompanion toCompanion(bool nullToAbsent) {
    return ScrollLogsCompanion(
      id: Value(id),
      appName: Value(appName),
      durationMinutes: Value(durationMinutes),
      dailyScoreImpact: Value(dailyScoreImpact),
      recoveryActionTaken: Value(recoveryActionTaken),
      recoveryActionType: recoveryActionType == null && nullToAbsent
          ? const Value.absent()
          : Value(recoveryActionType),
      intent: intent == null && nullToAbsent
          ? const Value.absent()
          : Value(intent),
      wasTimeboxed: Value(wasTimeboxed),
      plannedMinutes: plannedMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedMinutes),
      timestamp: Value(timestamp),
    );
  }

  factory ScrollLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScrollLog(
      id: serializer.fromJson<String>(json['id']),
      appName: serializer.fromJson<String>(json['appName']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      dailyScoreImpact: serializer.fromJson<int>(json['dailyScoreImpact']),
      recoveryActionTaken: serializer.fromJson<bool>(
        json['recoveryActionTaken'],
      ),
      recoveryActionType: serializer.fromJson<String?>(
        json['recoveryActionType'],
      ),
      intent: serializer.fromJson<String?>(json['intent']),
      wasTimeboxed: serializer.fromJson<bool>(json['wasTimeboxed']),
      plannedMinutes: serializer.fromJson<int?>(json['plannedMinutes']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'appName': serializer.toJson<String>(appName),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'dailyScoreImpact': serializer.toJson<int>(dailyScoreImpact),
      'recoveryActionTaken': serializer.toJson<bool>(recoveryActionTaken),
      'recoveryActionType': serializer.toJson<String?>(recoveryActionType),
      'intent': serializer.toJson<String?>(intent),
      'wasTimeboxed': serializer.toJson<bool>(wasTimeboxed),
      'plannedMinutes': serializer.toJson<int?>(plannedMinutes),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  ScrollLog copyWith({
    String? id,
    String? appName,
    int? durationMinutes,
    int? dailyScoreImpact,
    bool? recoveryActionTaken,
    Value<String?> recoveryActionType = const Value.absent(),
    Value<String?> intent = const Value.absent(),
    bool? wasTimeboxed,
    Value<int?> plannedMinutes = const Value.absent(),
    DateTime? timestamp,
  }) => ScrollLog(
    id: id ?? this.id,
    appName: appName ?? this.appName,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    dailyScoreImpact: dailyScoreImpact ?? this.dailyScoreImpact,
    recoveryActionTaken: recoveryActionTaken ?? this.recoveryActionTaken,
    recoveryActionType: recoveryActionType.present
        ? recoveryActionType.value
        : this.recoveryActionType,
    intent: intent.present ? intent.value : this.intent,
    wasTimeboxed: wasTimeboxed ?? this.wasTimeboxed,
    plannedMinutes: plannedMinutes.present
        ? plannedMinutes.value
        : this.plannedMinutes,
    timestamp: timestamp ?? this.timestamp,
  );
  ScrollLog copyWithCompanion(ScrollLogsCompanion data) {
    return ScrollLog(
      id: data.id.present ? data.id.value : this.id,
      appName: data.appName.present ? data.appName.value : this.appName,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      dailyScoreImpact: data.dailyScoreImpact.present
          ? data.dailyScoreImpact.value
          : this.dailyScoreImpact,
      recoveryActionTaken: data.recoveryActionTaken.present
          ? data.recoveryActionTaken.value
          : this.recoveryActionTaken,
      recoveryActionType: data.recoveryActionType.present
          ? data.recoveryActionType.value
          : this.recoveryActionType,
      intent: data.intent.present ? data.intent.value : this.intent,
      wasTimeboxed: data.wasTimeboxed.present
          ? data.wasTimeboxed.value
          : this.wasTimeboxed,
      plannedMinutes: data.plannedMinutes.present
          ? data.plannedMinutes.value
          : this.plannedMinutes,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScrollLog(')
          ..write('id: $id, ')
          ..write('appName: $appName, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('dailyScoreImpact: $dailyScoreImpact, ')
          ..write('recoveryActionTaken: $recoveryActionTaken, ')
          ..write('recoveryActionType: $recoveryActionType, ')
          ..write('intent: $intent, ')
          ..write('wasTimeboxed: $wasTimeboxed, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    appName,
    durationMinutes,
    dailyScoreImpact,
    recoveryActionTaken,
    recoveryActionType,
    intent,
    wasTimeboxed,
    plannedMinutes,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScrollLog &&
          other.id == this.id &&
          other.appName == this.appName &&
          other.durationMinutes == this.durationMinutes &&
          other.dailyScoreImpact == this.dailyScoreImpact &&
          other.recoveryActionTaken == this.recoveryActionTaken &&
          other.recoveryActionType == this.recoveryActionType &&
          other.intent == this.intent &&
          other.wasTimeboxed == this.wasTimeboxed &&
          other.plannedMinutes == this.plannedMinutes &&
          other.timestamp == this.timestamp);
}

class ScrollLogsCompanion extends UpdateCompanion<ScrollLog> {
  final Value<String> id;
  final Value<String> appName;
  final Value<int> durationMinutes;
  final Value<int> dailyScoreImpact;
  final Value<bool> recoveryActionTaken;
  final Value<String?> recoveryActionType;
  final Value<String?> intent;
  final Value<bool> wasTimeboxed;
  final Value<int?> plannedMinutes;
  final Value<DateTime> timestamp;
  final Value<int> rowid;
  const ScrollLogsCompanion({
    this.id = const Value.absent(),
    this.appName = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.dailyScoreImpact = const Value.absent(),
    this.recoveryActionTaken = const Value.absent(),
    this.recoveryActionType = const Value.absent(),
    this.intent = const Value.absent(),
    this.wasTimeboxed = const Value.absent(),
    this.plannedMinutes = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScrollLogsCompanion.insert({
    required String id,
    required String appName,
    required int durationMinutes,
    required int dailyScoreImpact,
    this.recoveryActionTaken = const Value.absent(),
    this.recoveryActionType = const Value.absent(),
    this.intent = const Value.absent(),
    this.wasTimeboxed = const Value.absent(),
    this.plannedMinutes = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       appName = Value(appName),
       durationMinutes = Value(durationMinutes),
       dailyScoreImpact = Value(dailyScoreImpact);
  static Insertable<ScrollLog> custom({
    Expression<String>? id,
    Expression<String>? appName,
    Expression<int>? durationMinutes,
    Expression<int>? dailyScoreImpact,
    Expression<bool>? recoveryActionTaken,
    Expression<String>? recoveryActionType,
    Expression<String>? intent,
    Expression<bool>? wasTimeboxed,
    Expression<int>? plannedMinutes,
    Expression<DateTime>? timestamp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appName != null) 'app_name': appName,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (dailyScoreImpact != null) 'daily_score_impact': dailyScoreImpact,
      if (recoveryActionTaken != null)
        'recovery_action_taken': recoveryActionTaken,
      if (recoveryActionType != null)
        'recovery_action_type': recoveryActionType,
      if (intent != null) 'intent': intent,
      if (wasTimeboxed != null) 'was_timeboxed': wasTimeboxed,
      if (plannedMinutes != null) 'planned_minutes': plannedMinutes,
      if (timestamp != null) 'timestamp': timestamp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScrollLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? appName,
    Value<int>? durationMinutes,
    Value<int>? dailyScoreImpact,
    Value<bool>? recoveryActionTaken,
    Value<String?>? recoveryActionType,
    Value<String?>? intent,
    Value<bool>? wasTimeboxed,
    Value<int?>? plannedMinutes,
    Value<DateTime>? timestamp,
    Value<int>? rowid,
  }) {
    return ScrollLogsCompanion(
      id: id ?? this.id,
      appName: appName ?? this.appName,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      dailyScoreImpact: dailyScoreImpact ?? this.dailyScoreImpact,
      recoveryActionTaken: recoveryActionTaken ?? this.recoveryActionTaken,
      recoveryActionType: recoveryActionType ?? this.recoveryActionType,
      intent: intent ?? this.intent,
      wasTimeboxed: wasTimeboxed ?? this.wasTimeboxed,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      timestamp: timestamp ?? this.timestamp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (dailyScoreImpact.present) {
      map['daily_score_impact'] = Variable<int>(dailyScoreImpact.value);
    }
    if (recoveryActionTaken.present) {
      map['recovery_action_taken'] = Variable<bool>(recoveryActionTaken.value);
    }
    if (recoveryActionType.present) {
      map['recovery_action_type'] = Variable<String>(recoveryActionType.value);
    }
    if (intent.present) {
      map['intent'] = Variable<String>(intent.value);
    }
    if (wasTimeboxed.present) {
      map['was_timeboxed'] = Variable<bool>(wasTimeboxed.value);
    }
    if (plannedMinutes.present) {
      map['planned_minutes'] = Variable<int>(plannedMinutes.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScrollLogsCompanion(')
          ..write('id: $id, ')
          ..write('appName: $appName, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('dailyScoreImpact: $dailyScoreImpact, ')
          ..write('recoveryActionTaken: $recoveryActionTaken, ')
          ..write('recoveryActionType: $recoveryActionType, ')
          ..write('intent: $intent, ')
          ..write('wasTimeboxed: $wasTimeboxed, ')
          ..write('plannedMinutes: $plannedMinutes, ')
          ..write('timestamp: $timestamp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EnergyCheckInsTable extends EnergyCheckIns
    with TableInfo<$EnergyCheckInsTable, EnergyCheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EnergyCheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TimeOfDayColumn, String>
  timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TimeOfDayColumn>($EnergyCheckInsTable.$convertertimeOfDay);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, timeOfDay, value, date];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'energy_check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<EnergyCheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EnergyCheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EnergyCheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      timeOfDay: $EnergyCheckInsTable.$convertertimeOfDay.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}time_of_day'],
        )!,
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
    );
  }

  @override
  $EnergyCheckInsTable createAlias(String alias) {
    return $EnergyCheckInsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TimeOfDayColumn, String, String>
  $convertertimeOfDay = const EnumNameConverter<TimeOfDayColumn>(
    TimeOfDayColumn.values,
  );
}

class EnergyCheckIn extends DataClass implements Insertable<EnergyCheckIn> {
  final String id;
  final TimeOfDayColumn timeOfDay;
  final int value;
  final DateTime date;
  const EnergyCheckIn({
    required this.id,
    required this.timeOfDay,
    required this.value,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    {
      map['time_of_day'] = Variable<String>(
        $EnergyCheckInsTable.$convertertimeOfDay.toSql(timeOfDay),
      );
    }
    map['value'] = Variable<int>(value);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  EnergyCheckInsCompanion toCompanion(bool nullToAbsent) {
    return EnergyCheckInsCompanion(
      id: Value(id),
      timeOfDay: Value(timeOfDay),
      value: Value(value),
      date: Value(date),
    );
  }

  factory EnergyCheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EnergyCheckIn(
      id: serializer.fromJson<String>(json['id']),
      timeOfDay: $EnergyCheckInsTable.$convertertimeOfDay.fromJson(
        serializer.fromJson<String>(json['timeOfDay']),
      ),
      value: serializer.fromJson<int>(json['value']),
      date: serializer.fromJson<DateTime>(json['date']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'timeOfDay': serializer.toJson<String>(
        $EnergyCheckInsTable.$convertertimeOfDay.toJson(timeOfDay),
      ),
      'value': serializer.toJson<int>(value),
      'date': serializer.toJson<DateTime>(date),
    };
  }

  EnergyCheckIn copyWith({
    String? id,
    TimeOfDayColumn? timeOfDay,
    int? value,
    DateTime? date,
  }) => EnergyCheckIn(
    id: id ?? this.id,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    value: value ?? this.value,
    date: date ?? this.date,
  );
  EnergyCheckIn copyWithCompanion(EnergyCheckInsCompanion data) {
    return EnergyCheckIn(
      id: data.id.present ? data.id.value : this.id,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      value: data.value.present ? data.value.value : this.value,
      date: data.date.present ? data.date.value : this.date,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EnergyCheckIn(')
          ..write('id: $id, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('value: $value, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timeOfDay, value, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EnergyCheckIn &&
          other.id == this.id &&
          other.timeOfDay == this.timeOfDay &&
          other.value == this.value &&
          other.date == this.date);
}

class EnergyCheckInsCompanion extends UpdateCompanion<EnergyCheckIn> {
  final Value<String> id;
  final Value<TimeOfDayColumn> timeOfDay;
  final Value<int> value;
  final Value<DateTime> date;
  final Value<int> rowid;
  const EnergyCheckInsCompanion({
    this.id = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.value = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EnergyCheckInsCompanion.insert({
    required String id,
    required TimeOfDayColumn timeOfDay,
    required int value,
    required DateTime date,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       timeOfDay = Value(timeOfDay),
       value = Value(value),
       date = Value(date);
  static Insertable<EnergyCheckIn> custom({
    Expression<String>? id,
    Expression<String>? timeOfDay,
    Expression<int>? value,
    Expression<DateTime>? date,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (value != null) 'value': value,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EnergyCheckInsCompanion copyWith({
    Value<String>? id,
    Value<TimeOfDayColumn>? timeOfDay,
    Value<int>? value,
    Value<DateTime>? date,
    Value<int>? rowid,
  }) {
    return EnergyCheckInsCompanion(
      id: id ?? this.id,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      value: value ?? this.value,
      date: date ?? this.date,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(
        $EnergyCheckInsTable.$convertertimeOfDay.toSql(timeOfDay.value),
      );
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EnergyCheckInsCompanion(')
          ..write('id: $id, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('value: $value, ')
          ..write('date: $date, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyReportsTable extends DailyReports
    with TableInfo<$DailyReportsTable, DailyReport> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reportJsonMeta = const VerificationMeta(
    'reportJson',
  );
  @override
  late final GeneratedColumn<String> reportJson = GeneratedColumn<String>(
    'report_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyScoreMeta = const VerificationMeta(
    'dailyScore',
  );
  @override
  late final GeneratedColumn<int> dailyScore = GeneratedColumn<int>(
    'daily_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpEarnedTodayMeta = const VerificationMeta(
    'xpEarnedToday',
  );
  @override
  late final GeneratedColumn<int> xpEarnedToday = GeneratedColumn<int>(
    'xp_earned_today',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attentionCostTodayMeta =
      const VerificationMeta('attentionCostToday');
  @override
  late final GeneratedColumn<int> attentionCostToday = GeneratedColumn<int>(
    'attention_cost_today',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _promptVersionMeta = const VerificationMeta(
    'promptVersion',
  );
  @override
  late final GeneratedColumn<int> promptVersion = GeneratedColumn<int>(
    'prompt_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    reportJson,
    dailyScore,
    xpEarnedToday,
    attentionCostToday,
    promptVersion,
    generatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_reports';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyReport> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('report_json')) {
      context.handle(
        _reportJsonMeta,
        reportJson.isAcceptableOrUnknown(data['report_json']!, _reportJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_reportJsonMeta);
    }
    if (data.containsKey('daily_score')) {
      context.handle(
        _dailyScoreMeta,
        dailyScore.isAcceptableOrUnknown(data['daily_score']!, _dailyScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_dailyScoreMeta);
    }
    if (data.containsKey('xp_earned_today')) {
      context.handle(
        _xpEarnedTodayMeta,
        xpEarnedToday.isAcceptableOrUnknown(
          data['xp_earned_today']!,
          _xpEarnedTodayMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_xpEarnedTodayMeta);
    }
    if (data.containsKey('attention_cost_today')) {
      context.handle(
        _attentionCostTodayMeta,
        attentionCostToday.isAcceptableOrUnknown(
          data['attention_cost_today']!,
          _attentionCostTodayMeta,
        ),
      );
    }
    if (data.containsKey('prompt_version')) {
      context.handle(
        _promptVersionMeta,
        promptVersion.isAcceptableOrUnknown(
          data['prompt_version']!,
          _promptVersionMeta,
        ),
      );
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyReport map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyReport(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      reportJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}report_json'],
      )!,
      dailyScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_score'],
      )!,
      xpEarnedToday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_earned_today'],
      )!,
      attentionCostToday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attention_cost_today'],
      )!,
      promptVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prompt_version'],
      ),
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
    );
  }

  @override
  $DailyReportsTable createAlias(String alias) {
    return $DailyReportsTable(attachedDatabase, alias);
  }
}

class DailyReport extends DataClass implements Insertable<DailyReport> {
  final String id;
  final DateTime date;
  final String reportJson;
  final int dailyScore;
  final int xpEarnedToday;
  final int attentionCostToday;
  final int? promptVersion;
  final DateTime generatedAt;
  const DailyReport({
    required this.id,
    required this.date,
    required this.reportJson,
    required this.dailyScore,
    required this.xpEarnedToday,
    required this.attentionCostToday,
    this.promptVersion,
    required this.generatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    map['report_json'] = Variable<String>(reportJson);
    map['daily_score'] = Variable<int>(dailyScore);
    map['xp_earned_today'] = Variable<int>(xpEarnedToday);
    map['attention_cost_today'] = Variable<int>(attentionCostToday);
    if (!nullToAbsent || promptVersion != null) {
      map['prompt_version'] = Variable<int>(promptVersion);
    }
    map['generated_at'] = Variable<DateTime>(generatedAt);
    return map;
  }

  DailyReportsCompanion toCompanion(bool nullToAbsent) {
    return DailyReportsCompanion(
      id: Value(id),
      date: Value(date),
      reportJson: Value(reportJson),
      dailyScore: Value(dailyScore),
      xpEarnedToday: Value(xpEarnedToday),
      attentionCostToday: Value(attentionCostToday),
      promptVersion: promptVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(promptVersion),
      generatedAt: Value(generatedAt),
    );
  }

  factory DailyReport.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyReport(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      reportJson: serializer.fromJson<String>(json['reportJson']),
      dailyScore: serializer.fromJson<int>(json['dailyScore']),
      xpEarnedToday: serializer.fromJson<int>(json['xpEarnedToday']),
      attentionCostToday: serializer.fromJson<int>(json['attentionCostToday']),
      promptVersion: serializer.fromJson<int?>(json['promptVersion']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'reportJson': serializer.toJson<String>(reportJson),
      'dailyScore': serializer.toJson<int>(dailyScore),
      'xpEarnedToday': serializer.toJson<int>(xpEarnedToday),
      'attentionCostToday': serializer.toJson<int>(attentionCostToday),
      'promptVersion': serializer.toJson<int?>(promptVersion),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
    };
  }

  DailyReport copyWith({
    String? id,
    DateTime? date,
    String? reportJson,
    int? dailyScore,
    int? xpEarnedToday,
    int? attentionCostToday,
    Value<int?> promptVersion = const Value.absent(),
    DateTime? generatedAt,
  }) => DailyReport(
    id: id ?? this.id,
    date: date ?? this.date,
    reportJson: reportJson ?? this.reportJson,
    dailyScore: dailyScore ?? this.dailyScore,
    xpEarnedToday: xpEarnedToday ?? this.xpEarnedToday,
    attentionCostToday: attentionCostToday ?? this.attentionCostToday,
    promptVersion: promptVersion.present
        ? promptVersion.value
        : this.promptVersion,
    generatedAt: generatedAt ?? this.generatedAt,
  );
  DailyReport copyWithCompanion(DailyReportsCompanion data) {
    return DailyReport(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      reportJson: data.reportJson.present
          ? data.reportJson.value
          : this.reportJson,
      dailyScore: data.dailyScore.present
          ? data.dailyScore.value
          : this.dailyScore,
      xpEarnedToday: data.xpEarnedToday.present
          ? data.xpEarnedToday.value
          : this.xpEarnedToday,
      attentionCostToday: data.attentionCostToday.present
          ? data.attentionCostToday.value
          : this.attentionCostToday,
      promptVersion: data.promptVersion.present
          ? data.promptVersion.value
          : this.promptVersion,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyReport(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('reportJson: $reportJson, ')
          ..write('dailyScore: $dailyScore, ')
          ..write('xpEarnedToday: $xpEarnedToday, ')
          ..write('attentionCostToday: $attentionCostToday, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('generatedAt: $generatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    reportJson,
    dailyScore,
    xpEarnedToday,
    attentionCostToday,
    promptVersion,
    generatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyReport &&
          other.id == this.id &&
          other.date == this.date &&
          other.reportJson == this.reportJson &&
          other.dailyScore == this.dailyScore &&
          other.xpEarnedToday == this.xpEarnedToday &&
          other.attentionCostToday == this.attentionCostToday &&
          other.promptVersion == this.promptVersion &&
          other.generatedAt == this.generatedAt);
}

class DailyReportsCompanion extends UpdateCompanion<DailyReport> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String> reportJson;
  final Value<int> dailyScore;
  final Value<int> xpEarnedToday;
  final Value<int> attentionCostToday;
  final Value<int?> promptVersion;
  final Value<DateTime> generatedAt;
  final Value<int> rowid;
  const DailyReportsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.reportJson = const Value.absent(),
    this.dailyScore = const Value.absent(),
    this.xpEarnedToday = const Value.absent(),
    this.attentionCostToday = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyReportsCompanion.insert({
    required String id,
    required DateTime date,
    required String reportJson,
    required int dailyScore,
    required int xpEarnedToday,
    this.attentionCostToday = const Value.absent(),
    this.promptVersion = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       reportJson = Value(reportJson),
       dailyScore = Value(dailyScore),
       xpEarnedToday = Value(xpEarnedToday);
  static Insertable<DailyReport> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? reportJson,
    Expression<int>? dailyScore,
    Expression<int>? xpEarnedToday,
    Expression<int>? attentionCostToday,
    Expression<int>? promptVersion,
    Expression<DateTime>? generatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (reportJson != null) 'report_json': reportJson,
      if (dailyScore != null) 'daily_score': dailyScore,
      if (xpEarnedToday != null) 'xp_earned_today': xpEarnedToday,
      if (attentionCostToday != null)
        'attention_cost_today': attentionCostToday,
      if (promptVersion != null) 'prompt_version': promptVersion,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyReportsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String>? reportJson,
    Value<int>? dailyScore,
    Value<int>? xpEarnedToday,
    Value<int>? attentionCostToday,
    Value<int?>? promptVersion,
    Value<DateTime>? generatedAt,
    Value<int>? rowid,
  }) {
    return DailyReportsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      reportJson: reportJson ?? this.reportJson,
      dailyScore: dailyScore ?? this.dailyScore,
      xpEarnedToday: xpEarnedToday ?? this.xpEarnedToday,
      attentionCostToday: attentionCostToday ?? this.attentionCostToday,
      promptVersion: promptVersion ?? this.promptVersion,
      generatedAt: generatedAt ?? this.generatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (reportJson.present) {
      map['report_json'] = Variable<String>(reportJson.value);
    }
    if (dailyScore.present) {
      map['daily_score'] = Variable<int>(dailyScore.value);
    }
    if (xpEarnedToday.present) {
      map['xp_earned_today'] = Variable<int>(xpEarnedToday.value);
    }
    if (attentionCostToday.present) {
      map['attention_cost_today'] = Variable<int>(attentionCostToday.value);
    }
    if (promptVersion.present) {
      map['prompt_version'] = Variable<int>(promptVersion.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyReportsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('reportJson: $reportJson, ')
          ..write('dailyScore: $dailyScore, ')
          ..write('xpEarnedToday: $xpEarnedToday, ')
          ..write('attentionCostToday: $attentionCostToday, ')
          ..write('promptVersion: $promptVersion, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievementKeyMeta = const VerificationMeta(
    'achievementKey',
  );
  @override
  late final GeneratedColumn<String> achievementKey = GeneratedColumn<String>(
    'achievement_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, achievementKey, unlockedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Achievement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('achievement_key')) {
      context.handle(
        _achievementKeyMeta,
        achievementKey.isAcceptableOrUnknown(
          data['achievement_key']!,
          _achievementKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementKeyMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      achievementKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_key'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final String id;
  final String achievementKey;
  final DateTime unlockedAt;
  const Achievement({
    required this.id,
    required this.achievementKey,
    required this.unlockedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['achievement_key'] = Variable<String>(achievementKey);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      achievementKey: Value(achievementKey),
      unlockedAt: Value(unlockedAt),
    );
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<String>(json['id']),
      achievementKey: serializer.fromJson<String>(json['achievementKey']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'achievementKey': serializer.toJson<String>(achievementKey),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
    };
  }

  Achievement copyWith({
    String? id,
    String? achievementKey,
    DateTime? unlockedAt,
  }) => Achievement(
    id: id ?? this.id,
    achievementKey: achievementKey ?? this.achievementKey,
    unlockedAt: unlockedAt ?? this.unlockedAt,
  );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      achievementKey: data.achievementKey.present
          ? data.achievementKey.value
          : this.achievementKey,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('achievementKey: $achievementKey, ')
          ..write('unlockedAt: $unlockedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, achievementKey, unlockedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.achievementKey == this.achievementKey &&
          other.unlockedAt == this.unlockedAt);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<String> id;
  final Value<String> achievementKey;
  final Value<DateTime> unlockedAt;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.achievementKey = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required String achievementKey,
    this.unlockedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       achievementKey = Value(achievementKey);
  static Insertable<Achievement> custom({
    Expression<String>? id,
    Expression<String>? achievementKey,
    Expression<DateTime>? unlockedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (achievementKey != null) 'achievement_key': achievementKey,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith({
    Value<String>? id,
    Value<String>? achievementKey,
    Value<DateTime>? unlockedAt,
    Value<int>? rowid,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      achievementKey: achievementKey ?? this.achievementKey,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (achievementKey.present) {
      map['achievement_key'] = Variable<String>(achievementKey.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('achievementKey: $achievementKey, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyPlansTable extends DailyPlans
    with TableInfo<$DailyPlansTable, DailyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mit1IdMeta = const VerificationMeta('mit1Id');
  @override
  late final GeneratedColumn<String> mit1Id = GeneratedColumn<String>(
    'mit1_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mit2IdMeta = const VerificationMeta('mit2Id');
  @override
  late final GeneratedColumn<String> mit2Id = GeneratedColumn<String>(
    'mit2_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mit3IdMeta = const VerificationMeta('mit3Id');
  @override
  late final GeneratedColumn<String> mit3Id = GeneratedColumn<String>(
    'mit3_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _morningEnergyMeta = const VerificationMeta(
    'morningEnergy',
  );
  @override
  late final GeneratedColumn<int> morningEnergy = GeneratedColumn<int>(
    'morning_energy',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _scrollBudgetMinutesMeta =
      const VerificationMeta('scrollBudgetMinutes');
  @override
  late final GeneratedColumn<int> scrollBudgetMinutes = GeneratedColumn<int>(
    'scroll_budget_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(30),
  );
  static const VerificationMeta _intentionCompletedMeta =
      const VerificationMeta('intentionCompleted');
  @override
  late final GeneratedColumn<bool> intentionCompleted = GeneratedColumn<bool>(
    'intention_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("intention_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _shutdownCompletedMeta = const VerificationMeta(
    'shutdownCompleted',
  );
  @override
  late final GeneratedColumn<bool> shutdownCompleted = GeneratedColumn<bool>(
    'shutdown_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("shutdown_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _intentionNoteMeta = const VerificationMeta(
    'intentionNote',
  );
  @override
  late final GeneratedColumn<String> intentionNote = GeneratedColumn<String>(
    'intention_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    mit1Id,
    mit2Id,
    mit3Id,
    morningEnergy,
    scrollBudgetMinutes,
    intentionCompleted,
    shutdownCompleted,
    intentionNote,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('mit1_id')) {
      context.handle(
        _mit1IdMeta,
        mit1Id.isAcceptableOrUnknown(data['mit1_id']!, _mit1IdMeta),
      );
    }
    if (data.containsKey('mit2_id')) {
      context.handle(
        _mit2IdMeta,
        mit2Id.isAcceptableOrUnknown(data['mit2_id']!, _mit2IdMeta),
      );
    }
    if (data.containsKey('mit3_id')) {
      context.handle(
        _mit3IdMeta,
        mit3Id.isAcceptableOrUnknown(data['mit3_id']!, _mit3IdMeta),
      );
    }
    if (data.containsKey('morning_energy')) {
      context.handle(
        _morningEnergyMeta,
        morningEnergy.isAcceptableOrUnknown(
          data['morning_energy']!,
          _morningEnergyMeta,
        ),
      );
    }
    if (data.containsKey('scroll_budget_minutes')) {
      context.handle(
        _scrollBudgetMinutesMeta,
        scrollBudgetMinutes.isAcceptableOrUnknown(
          data['scroll_budget_minutes']!,
          _scrollBudgetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('intention_completed')) {
      context.handle(
        _intentionCompletedMeta,
        intentionCompleted.isAcceptableOrUnknown(
          data['intention_completed']!,
          _intentionCompletedMeta,
        ),
      );
    }
    if (data.containsKey('shutdown_completed')) {
      context.handle(
        _shutdownCompletedMeta,
        shutdownCompleted.isAcceptableOrUnknown(
          data['shutdown_completed']!,
          _shutdownCompletedMeta,
        ),
      );
    }
    if (data.containsKey('intention_note')) {
      context.handle(
        _intentionNoteMeta,
        intentionNote.isAcceptableOrUnknown(
          data['intention_note']!,
          _intentionNoteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      mit1Id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mit1_id'],
      ),
      mit2Id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mit2_id'],
      ),
      mit3Id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mit3_id'],
      ),
      morningEnergy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}morning_energy'],
      )!,
      scrollBudgetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scroll_budget_minutes'],
      )!,
      intentionCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}intention_completed'],
      )!,
      shutdownCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}shutdown_completed'],
      )!,
      intentionNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intention_note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyPlansTable createAlias(String alias) {
    return $DailyPlansTable(attachedDatabase, alias);
  }
}

class DailyPlan extends DataClass implements Insertable<DailyPlan> {
  final String id;
  final DateTime date;
  final String? mit1Id;
  final String? mit2Id;
  final String? mit3Id;
  final int morningEnergy;
  final int scrollBudgetMinutes;
  final bool intentionCompleted;
  final bool shutdownCompleted;
  final String? intentionNote;
  final DateTime createdAt;
  const DailyPlan({
    required this.id,
    required this.date,
    this.mit1Id,
    this.mit2Id,
    this.mit3Id,
    required this.morningEnergy,
    required this.scrollBudgetMinutes,
    required this.intentionCompleted,
    required this.shutdownCompleted,
    this.intentionNote,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || mit1Id != null) {
      map['mit1_id'] = Variable<String>(mit1Id);
    }
    if (!nullToAbsent || mit2Id != null) {
      map['mit2_id'] = Variable<String>(mit2Id);
    }
    if (!nullToAbsent || mit3Id != null) {
      map['mit3_id'] = Variable<String>(mit3Id);
    }
    map['morning_energy'] = Variable<int>(morningEnergy);
    map['scroll_budget_minutes'] = Variable<int>(scrollBudgetMinutes);
    map['intention_completed'] = Variable<bool>(intentionCompleted);
    map['shutdown_completed'] = Variable<bool>(shutdownCompleted);
    if (!nullToAbsent || intentionNote != null) {
      map['intention_note'] = Variable<String>(intentionNote);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyPlansCompanion toCompanion(bool nullToAbsent) {
    return DailyPlansCompanion(
      id: Value(id),
      date: Value(date),
      mit1Id: mit1Id == null && nullToAbsent
          ? const Value.absent()
          : Value(mit1Id),
      mit2Id: mit2Id == null && nullToAbsent
          ? const Value.absent()
          : Value(mit2Id),
      mit3Id: mit3Id == null && nullToAbsent
          ? const Value.absent()
          : Value(mit3Id),
      morningEnergy: Value(morningEnergy),
      scrollBudgetMinutes: Value(scrollBudgetMinutes),
      intentionCompleted: Value(intentionCompleted),
      shutdownCompleted: Value(shutdownCompleted),
      intentionNote: intentionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(intentionNote),
      createdAt: Value(createdAt),
    );
  }

  factory DailyPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPlan(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<DateTime>(json['date']),
      mit1Id: serializer.fromJson<String?>(json['mit1Id']),
      mit2Id: serializer.fromJson<String?>(json['mit2Id']),
      mit3Id: serializer.fromJson<String?>(json['mit3Id']),
      morningEnergy: serializer.fromJson<int>(json['morningEnergy']),
      scrollBudgetMinutes: serializer.fromJson<int>(
        json['scrollBudgetMinutes'],
      ),
      intentionCompleted: serializer.fromJson<bool>(json['intentionCompleted']),
      shutdownCompleted: serializer.fromJson<bool>(json['shutdownCompleted']),
      intentionNote: serializer.fromJson<String?>(json['intentionNote']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<DateTime>(date),
      'mit1Id': serializer.toJson<String?>(mit1Id),
      'mit2Id': serializer.toJson<String?>(mit2Id),
      'mit3Id': serializer.toJson<String?>(mit3Id),
      'morningEnergy': serializer.toJson<int>(morningEnergy),
      'scrollBudgetMinutes': serializer.toJson<int>(scrollBudgetMinutes),
      'intentionCompleted': serializer.toJson<bool>(intentionCompleted),
      'shutdownCompleted': serializer.toJson<bool>(shutdownCompleted),
      'intentionNote': serializer.toJson<String?>(intentionNote),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyPlan copyWith({
    String? id,
    DateTime? date,
    Value<String?> mit1Id = const Value.absent(),
    Value<String?> mit2Id = const Value.absent(),
    Value<String?> mit3Id = const Value.absent(),
    int? morningEnergy,
    int? scrollBudgetMinutes,
    bool? intentionCompleted,
    bool? shutdownCompleted,
    Value<String?> intentionNote = const Value.absent(),
    DateTime? createdAt,
  }) => DailyPlan(
    id: id ?? this.id,
    date: date ?? this.date,
    mit1Id: mit1Id.present ? mit1Id.value : this.mit1Id,
    mit2Id: mit2Id.present ? mit2Id.value : this.mit2Id,
    mit3Id: mit3Id.present ? mit3Id.value : this.mit3Id,
    morningEnergy: morningEnergy ?? this.morningEnergy,
    scrollBudgetMinutes: scrollBudgetMinutes ?? this.scrollBudgetMinutes,
    intentionCompleted: intentionCompleted ?? this.intentionCompleted,
    shutdownCompleted: shutdownCompleted ?? this.shutdownCompleted,
    intentionNote: intentionNote.present
        ? intentionNote.value
        : this.intentionNote,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyPlan copyWithCompanion(DailyPlansCompanion data) {
    return DailyPlan(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      mit1Id: data.mit1Id.present ? data.mit1Id.value : this.mit1Id,
      mit2Id: data.mit2Id.present ? data.mit2Id.value : this.mit2Id,
      mit3Id: data.mit3Id.present ? data.mit3Id.value : this.mit3Id,
      morningEnergy: data.morningEnergy.present
          ? data.morningEnergy.value
          : this.morningEnergy,
      scrollBudgetMinutes: data.scrollBudgetMinutes.present
          ? data.scrollBudgetMinutes.value
          : this.scrollBudgetMinutes,
      intentionCompleted: data.intentionCompleted.present
          ? data.intentionCompleted.value
          : this.intentionCompleted,
      shutdownCompleted: data.shutdownCompleted.present
          ? data.shutdownCompleted.value
          : this.shutdownCompleted,
      intentionNote: data.intentionNote.present
          ? data.intentionNote.value
          : this.intentionNote,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlan(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mit1Id: $mit1Id, ')
          ..write('mit2Id: $mit2Id, ')
          ..write('mit3Id: $mit3Id, ')
          ..write('morningEnergy: $morningEnergy, ')
          ..write('scrollBudgetMinutes: $scrollBudgetMinutes, ')
          ..write('intentionCompleted: $intentionCompleted, ')
          ..write('shutdownCompleted: $shutdownCompleted, ')
          ..write('intentionNote: $intentionNote, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    mit1Id,
    mit2Id,
    mit3Id,
    morningEnergy,
    scrollBudgetMinutes,
    intentionCompleted,
    shutdownCompleted,
    intentionNote,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPlan &&
          other.id == this.id &&
          other.date == this.date &&
          other.mit1Id == this.mit1Id &&
          other.mit2Id == this.mit2Id &&
          other.mit3Id == this.mit3Id &&
          other.morningEnergy == this.morningEnergy &&
          other.scrollBudgetMinutes == this.scrollBudgetMinutes &&
          other.intentionCompleted == this.intentionCompleted &&
          other.shutdownCompleted == this.shutdownCompleted &&
          other.intentionNote == this.intentionNote &&
          other.createdAt == this.createdAt);
}

class DailyPlansCompanion extends UpdateCompanion<DailyPlan> {
  final Value<String> id;
  final Value<DateTime> date;
  final Value<String?> mit1Id;
  final Value<String?> mit2Id;
  final Value<String?> mit3Id;
  final Value<int> morningEnergy;
  final Value<int> scrollBudgetMinutes;
  final Value<bool> intentionCompleted;
  final Value<bool> shutdownCompleted;
  final Value<String?> intentionNote;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const DailyPlansCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.mit1Id = const Value.absent(),
    this.mit2Id = const Value.absent(),
    this.mit3Id = const Value.absent(),
    this.morningEnergy = const Value.absent(),
    this.scrollBudgetMinutes = const Value.absent(),
    this.intentionCompleted = const Value.absent(),
    this.shutdownCompleted = const Value.absent(),
    this.intentionNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPlansCompanion.insert({
    required String id,
    required DateTime date,
    this.mit1Id = const Value.absent(),
    this.mit2Id = const Value.absent(),
    this.mit3Id = const Value.absent(),
    this.morningEnergy = const Value.absent(),
    this.scrollBudgetMinutes = const Value.absent(),
    this.intentionCompleted = const Value.absent(),
    this.shutdownCompleted = const Value.absent(),
    this.intentionNote = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date);
  static Insertable<DailyPlan> custom({
    Expression<String>? id,
    Expression<DateTime>? date,
    Expression<String>? mit1Id,
    Expression<String>? mit2Id,
    Expression<String>? mit3Id,
    Expression<int>? morningEnergy,
    Expression<int>? scrollBudgetMinutes,
    Expression<bool>? intentionCompleted,
    Expression<bool>? shutdownCompleted,
    Expression<String>? intentionNote,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (mit1Id != null) 'mit1_id': mit1Id,
      if (mit2Id != null) 'mit2_id': mit2Id,
      if (mit3Id != null) 'mit3_id': mit3Id,
      if (morningEnergy != null) 'morning_energy': morningEnergy,
      if (scrollBudgetMinutes != null)
        'scroll_budget_minutes': scrollBudgetMinutes,
      if (intentionCompleted != null) 'intention_completed': intentionCompleted,
      if (shutdownCompleted != null) 'shutdown_completed': shutdownCompleted,
      if (intentionNote != null) 'intention_note': intentionNote,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPlansCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? date,
    Value<String?>? mit1Id,
    Value<String?>? mit2Id,
    Value<String?>? mit3Id,
    Value<int>? morningEnergy,
    Value<int>? scrollBudgetMinutes,
    Value<bool>? intentionCompleted,
    Value<bool>? shutdownCompleted,
    Value<String?>? intentionNote,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return DailyPlansCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      mit1Id: mit1Id ?? this.mit1Id,
      mit2Id: mit2Id ?? this.mit2Id,
      mit3Id: mit3Id ?? this.mit3Id,
      morningEnergy: morningEnergy ?? this.morningEnergy,
      scrollBudgetMinutes: scrollBudgetMinutes ?? this.scrollBudgetMinutes,
      intentionCompleted: intentionCompleted ?? this.intentionCompleted,
      shutdownCompleted: shutdownCompleted ?? this.shutdownCompleted,
      intentionNote: intentionNote ?? this.intentionNote,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (mit1Id.present) {
      map['mit1_id'] = Variable<String>(mit1Id.value);
    }
    if (mit2Id.present) {
      map['mit2_id'] = Variable<String>(mit2Id.value);
    }
    if (mit3Id.present) {
      map['mit3_id'] = Variable<String>(mit3Id.value);
    }
    if (morningEnergy.present) {
      map['morning_energy'] = Variable<int>(morningEnergy.value);
    }
    if (scrollBudgetMinutes.present) {
      map['scroll_budget_minutes'] = Variable<int>(scrollBudgetMinutes.value);
    }
    if (intentionCompleted.present) {
      map['intention_completed'] = Variable<bool>(intentionCompleted.value);
    }
    if (shutdownCompleted.present) {
      map['shutdown_completed'] = Variable<bool>(shutdownCompleted.value);
    }
    if (intentionNote.present) {
      map['intention_note'] = Variable<String>(intentionNote.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlansCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('mit1Id: $mit1Id, ')
          ..write('mit2Id: $mit2Id, ')
          ..write('mit3Id: $mit3Id, ')
          ..write('morningEnergy: $morningEnergy, ')
          ..write('scrollBudgetMinutes: $scrollBudgetMinutes, ')
          ..write('intentionCompleted: $intentionCompleted, ')
          ..write('shutdownCompleted: $shutdownCompleted, ')
          ..write('intentionNote: $intentionNote, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $FocusSessionsTable focusSessions = $FocusSessionsTable(this);
  late final $XpLedgerEntriesTable xpLedgerEntries = $XpLedgerEntriesTable(
    this,
  );
  late final $AttentionCostsTable attentionCosts = $AttentionCostsTable(this);
  late final $ScrollLogsTable scrollLogs = $ScrollLogsTable(this);
  late final $EnergyCheckInsTable energyCheckIns = $EnergyCheckInsTable(this);
  late final $DailyReportsTable dailyReports = $DailyReportsTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $DailyPlansTable dailyPlans = $DailyPlansTable(this);
  late final TasksDao tasksDao = TasksDao(this as AppDatabase);
  late final FocusSessionsDao focusSessionsDao = FocusSessionsDao(
    this as AppDatabase,
  );
  late final XpLedgerDao xpLedgerDao = XpLedgerDao(this as AppDatabase);
  late final ScrollLogsDao scrollLogsDao = ScrollLogsDao(this as AppDatabase);
  late final EnergyCheckInsDao energyCheckInsDao = EnergyCheckInsDao(
    this as AppDatabase,
  );
  late final DailyPlansDao dailyPlansDao = DailyPlansDao(this as AppDatabase);
  late final DailyReportsDao dailyReportsDao = DailyReportsDao(
    this as AppDatabase,
  );
  late final AchievementsDao achievementsDao = AchievementsDao(
    this as AppDatabase,
  );
  late final AttentionCostsDao attentionCostsDao = AttentionCostsDao(
    this as AppDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    focusSessions,
    xpLedgerEntries,
    attentionCosts,
    scrollLogs,
    energyCheckIns,
    dailyReports,
    achievements,
    dailyPlans,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      Value<String> description,
      required EnergyLevelColumn energyLevel,
      Value<int> estimatedMinutes,
      Value<int> frictionScore,
      required TaskCategoryColumn category,
      Value<DateTime?> dueDate,
      Value<int> sortOrder,
      Value<bool> isMIT,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<int> xpEarned,
      Value<String?> parentTaskId,
      Value<RecurrenceRuleColumn?> recurrenceRule,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<EnergyLevelColumn> energyLevel,
      Value<int> estimatedMinutes,
      Value<int> frictionScore,
      Value<TaskCategoryColumn> category,
      Value<DateTime?> dueDate,
      Value<int> sortOrder,
      Value<bool> isMIT,
      Value<bool> isCompleted,
      Value<DateTime?> completedAt,
      Value<int> xpEarned,
      Value<String?> parentTaskId,
      Value<RecurrenceRuleColumn?> recurrenceRule,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<EnergyLevelColumn, EnergyLevelColumn, int>
  get energyLevel => $composableBuilder(
    column: $table.energyLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get frictionScore => $composableBuilder(
    column: $table.frictionScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskCategoryColumn, TaskCategoryColumn, String>
  get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMIT => $composableBuilder(
    column: $table.isMIT,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    RecurrenceRuleColumn?,
    RecurrenceRuleColumn,
    String
  >
  get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energyLevel => $composableBuilder(
    column: $table.energyLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get frictionScore => $composableBuilder(
    column: $table.frictionScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMIT => $composableBuilder(
    column: $table.isMIT,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<EnergyLevelColumn, int> get energyLevel =>
      $composableBuilder(
        column: $table.energyLevel,
        builder: (column) => column,
      );

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
    column: $table.estimatedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get frictionScore => $composableBuilder(
    column: $table.frictionScore,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<TaskCategoryColumn, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isMIT =>
      $composableBuilder(column: $table.isMIT, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<String> get parentTaskId => $composableBuilder(
    column: $table.parentTaskId,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RecurrenceRuleColumn?, String>
  get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<EnergyLevelColumn> energyLevel = const Value.absent(),
                Value<int> estimatedMinutes = const Value.absent(),
                Value<int> frictionScore = const Value.absent(),
                Value<TaskCategoryColumn> category = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isMIT = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<RecurrenceRuleColumn?> recurrenceRule =
                    const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                description: description,
                energyLevel: energyLevel,
                estimatedMinutes: estimatedMinutes,
                frictionScore: frictionScore,
                category: category,
                dueDate: dueDate,
                sortOrder: sortOrder,
                isMIT: isMIT,
                isCompleted: isCompleted,
                completedAt: completedAt,
                xpEarned: xpEarned,
                parentTaskId: parentTaskId,
                recurrenceRule: recurrenceRule,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String> description = const Value.absent(),
                required EnergyLevelColumn energyLevel,
                Value<int> estimatedMinutes = const Value.absent(),
                Value<int> frictionScore = const Value.absent(),
                required TaskCategoryColumn category,
                Value<DateTime?> dueDate = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isMIT = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<RecurrenceRuleColumn?> recurrenceRule =
                    const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                description: description,
                energyLevel: energyLevel,
                estimatedMinutes: estimatedMinutes,
                frictionScore: frictionScore,
                category: category,
                dueDate: dueDate,
                sortOrder: sortOrder,
                isMIT: isMIT,
                isCompleted: isCompleted,
                completedAt: completedAt,
                xpEarned: xpEarned,
                parentTaskId: parentTaskId,
                recurrenceRule: recurrenceRule,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AppDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$FocusSessionsTableCreateCompanionBuilder =
    FocusSessionsCompanion Function({
      required String id,
      Value<String?> taskId,
      required SessionTypeColumn sessionType,
      required int durationMinutes,
      Value<int> actualMinutes,
      Value<int> pauseCount,
      Value<int> appBackgroundCount,
      Value<String?> ambientSound,
      Value<int?> energyBefore,
      Value<int?> energyAfter,
      Value<int> xpEarned,
      Value<String> qualityScore,
      required DateTime startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$FocusSessionsTableUpdateCompanionBuilder =
    FocusSessionsCompanion Function({
      Value<String> id,
      Value<String?> taskId,
      Value<SessionTypeColumn> sessionType,
      Value<int> durationMinutes,
      Value<int> actualMinutes,
      Value<int> pauseCount,
      Value<int> appBackgroundCount,
      Value<String?> ambientSound,
      Value<int?> energyBefore,
      Value<int?> energyAfter,
      Value<int> xpEarned,
      Value<String> qualityScore,
      Value<DateTime> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$FocusSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionTypeColumn, SessionTypeColumn, String>
  get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get appBackgroundCount => $composableBuilder(
    column: $table.appBackgroundCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ambientSound => $composableBuilder(
    column: $table.ambientSound,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energyBefore => $composableBuilder(
    column: $table.energyBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energyAfter => $composableBuilder(
    column: $table.energyAfter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FocusSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get appBackgroundCount => $composableBuilder(
    column: $table.appBackgroundCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ambientSound => $composableBuilder(
    column: $table.ambientSound,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energyBefore => $composableBuilder(
    column: $table.energyBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energyAfter => $composableBuilder(
    column: $table.energyAfter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpEarned => $composableBuilder(
    column: $table.xpEarned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FocusSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FocusSessionsTable> {
  $$FocusSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionTypeColumn, String> get sessionType =>
      $composableBuilder(
        column: $table.sessionType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get actualMinutes => $composableBuilder(
    column: $table.actualMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pauseCount => $composableBuilder(
    column: $table.pauseCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get appBackgroundCount => $composableBuilder(
    column: $table.appBackgroundCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ambientSound => $composableBuilder(
    column: $table.ambientSound,
    builder: (column) => column,
  );

  GeneratedColumn<int> get energyBefore => $composableBuilder(
    column: $table.energyBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get energyAfter => $composableBuilder(
    column: $table.energyAfter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<String> get qualityScore => $composableBuilder(
    column: $table.qualityScore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$FocusSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FocusSessionsTable,
          FocusSession,
          $$FocusSessionsTableFilterComposer,
          $$FocusSessionsTableOrderingComposer,
          $$FocusSessionsTableAnnotationComposer,
          $$FocusSessionsTableCreateCompanionBuilder,
          $$FocusSessionsTableUpdateCompanionBuilder,
          (
            FocusSession,
            BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
          ),
          FocusSession,
          PrefetchHooks Function()
        > {
  $$FocusSessionsTableTableManager(_$AppDatabase db, $FocusSessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FocusSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FocusSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FocusSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<SessionTypeColumn> sessionType = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> actualMinutes = const Value.absent(),
                Value<int> pauseCount = const Value.absent(),
                Value<int> appBackgroundCount = const Value.absent(),
                Value<String?> ambientSound = const Value.absent(),
                Value<int?> energyBefore = const Value.absent(),
                Value<int?> energyAfter = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<String> qualityScore = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion(
                id: id,
                taskId: taskId,
                sessionType: sessionType,
                durationMinutes: durationMinutes,
                actualMinutes: actualMinutes,
                pauseCount: pauseCount,
                appBackgroundCount: appBackgroundCount,
                ambientSound: ambientSound,
                energyBefore: energyBefore,
                energyAfter: energyAfter,
                xpEarned: xpEarned,
                qualityScore: qualityScore,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> taskId = const Value.absent(),
                required SessionTypeColumn sessionType,
                required int durationMinutes,
                Value<int> actualMinutes = const Value.absent(),
                Value<int> pauseCount = const Value.absent(),
                Value<int> appBackgroundCount = const Value.absent(),
                Value<String?> ambientSound = const Value.absent(),
                Value<int?> energyBefore = const Value.absent(),
                Value<int?> energyAfter = const Value.absent(),
                Value<int> xpEarned = const Value.absent(),
                Value<String> qualityScore = const Value.absent(),
                required DateTime startedAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FocusSessionsCompanion.insert(
                id: id,
                taskId: taskId,
                sessionType: sessionType,
                durationMinutes: durationMinutes,
                actualMinutes: actualMinutes,
                pauseCount: pauseCount,
                appBackgroundCount: appBackgroundCount,
                ambientSound: ambientSound,
                energyBefore: energyBefore,
                energyAfter: energyAfter,
                xpEarned: xpEarned,
                qualityScore: qualityScore,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FocusSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FocusSessionsTable,
      FocusSession,
      $$FocusSessionsTableFilterComposer,
      $$FocusSessionsTableOrderingComposer,
      $$FocusSessionsTableAnnotationComposer,
      $$FocusSessionsTableCreateCompanionBuilder,
      $$FocusSessionsTableUpdateCompanionBuilder,
      (
        FocusSession,
        BaseReferences<_$AppDatabase, $FocusSessionsTable, FocusSession>,
      ),
      FocusSession,
      PrefetchHooks Function()
    >;
typedef $$XpLedgerEntriesTableCreateCompanionBuilder =
    XpLedgerEntriesCompanion Function({
      required String id,
      required XpActionTypeColumn actionType,
      required int pointsDelta,
      Value<String?> sourceEntityId,
      required String explanation,
      Value<bool> isReversible,
      Value<int?> promptVersion,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });
typedef $$XpLedgerEntriesTableUpdateCompanionBuilder =
    XpLedgerEntriesCompanion Function({
      Value<String> id,
      Value<XpActionTypeColumn> actionType,
      Value<int> pointsDelta,
      Value<String?> sourceEntityId,
      Value<String> explanation,
      Value<bool> isReversible,
      Value<int?> promptVersion,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

class $$XpLedgerEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $XpLedgerEntriesTable> {
  $$XpLedgerEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<XpActionTypeColumn, XpActionTypeColumn, String>
  get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get pointsDelta => $composableBuilder(
    column: $table.pointsDelta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceEntityId => $composableBuilder(
    column: $table.sourceEntityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isReversible => $composableBuilder(
    column: $table.isReversible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$XpLedgerEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $XpLedgerEntriesTable> {
  $$XpLedgerEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get actionType => $composableBuilder(
    column: $table.actionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pointsDelta => $composableBuilder(
    column: $table.pointsDelta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceEntityId => $composableBuilder(
    column: $table.sourceEntityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isReversible => $composableBuilder(
    column: $table.isReversible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$XpLedgerEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $XpLedgerEntriesTable> {
  $$XpLedgerEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<XpActionTypeColumn, String> get actionType =>
      $composableBuilder(
        column: $table.actionType,
        builder: (column) => column,
      );

  GeneratedColumn<int> get pointsDelta => $composableBuilder(
    column: $table.pointsDelta,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceEntityId => $composableBuilder(
    column: $table.sourceEntityId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get explanation => $composableBuilder(
    column: $table.explanation,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isReversible => $composableBuilder(
    column: $table.isReversible,
    builder: (column) => column,
  );

  GeneratedColumn<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$XpLedgerEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $XpLedgerEntriesTable,
          XpLedgerEntry,
          $$XpLedgerEntriesTableFilterComposer,
          $$XpLedgerEntriesTableOrderingComposer,
          $$XpLedgerEntriesTableAnnotationComposer,
          $$XpLedgerEntriesTableCreateCompanionBuilder,
          $$XpLedgerEntriesTableUpdateCompanionBuilder,
          (
            XpLedgerEntry,
            BaseReferences<_$AppDatabase, $XpLedgerEntriesTable, XpLedgerEntry>,
          ),
          XpLedgerEntry,
          PrefetchHooks Function()
        > {
  $$XpLedgerEntriesTableTableManager(
    _$AppDatabase db,
    $XpLedgerEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$XpLedgerEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$XpLedgerEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$XpLedgerEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<XpActionTypeColumn> actionType = const Value.absent(),
                Value<int> pointsDelta = const Value.absent(),
                Value<String?> sourceEntityId = const Value.absent(),
                Value<String> explanation = const Value.absent(),
                Value<bool> isReversible = const Value.absent(),
                Value<int?> promptVersion = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => XpLedgerEntriesCompanion(
                id: id,
                actionType: actionType,
                pointsDelta: pointsDelta,
                sourceEntityId: sourceEntityId,
                explanation: explanation,
                isReversible: isReversible,
                promptVersion: promptVersion,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required XpActionTypeColumn actionType,
                required int pointsDelta,
                Value<String?> sourceEntityId = const Value.absent(),
                required String explanation,
                Value<bool> isReversible = const Value.absent(),
                Value<int?> promptVersion = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => XpLedgerEntriesCompanion.insert(
                id: id,
                actionType: actionType,
                pointsDelta: pointsDelta,
                sourceEntityId: sourceEntityId,
                explanation: explanation,
                isReversible: isReversible,
                promptVersion: promptVersion,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$XpLedgerEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $XpLedgerEntriesTable,
      XpLedgerEntry,
      $$XpLedgerEntriesTableFilterComposer,
      $$XpLedgerEntriesTableOrderingComposer,
      $$XpLedgerEntriesTableAnnotationComposer,
      $$XpLedgerEntriesTableCreateCompanionBuilder,
      $$XpLedgerEntriesTableUpdateCompanionBuilder,
      (
        XpLedgerEntry,
        BaseReferences<_$AppDatabase, $XpLedgerEntriesTable, XpLedgerEntry>,
      ),
      XpLedgerEntry,
      PrefetchHooks Function()
    >;
typedef $$AttentionCostsTableCreateCompanionBuilder =
    AttentionCostsCompanion Function({
      required String id,
      required AttentionCostTypeColumn costType,
      required int minutesOrCount,
      required int dailyScoreImpact,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });
typedef $$AttentionCostsTableUpdateCompanionBuilder =
    AttentionCostsCompanion Function({
      Value<String> id,
      Value<AttentionCostTypeColumn> costType,
      Value<int> minutesOrCount,
      Value<int> dailyScoreImpact,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

class $$AttentionCostsTableFilterComposer
    extends Composer<_$AppDatabase, $AttentionCostsTable> {
  $$AttentionCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    AttentionCostTypeColumn,
    AttentionCostTypeColumn,
    String
  >
  get costType => $composableBuilder(
    column: $table.costType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get minutesOrCount => $composableBuilder(
    column: $table.minutesOrCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyScoreImpact => $composableBuilder(
    column: $table.dailyScoreImpact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttentionCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttentionCostsTable> {
  $$AttentionCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get costType => $composableBuilder(
    column: $table.costType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesOrCount => $composableBuilder(
    column: $table.minutesOrCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyScoreImpact => $composableBuilder(
    column: $table.dailyScoreImpact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttentionCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttentionCostsTable> {
  $$AttentionCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AttentionCostTypeColumn, String>
  get costType =>
      $composableBuilder(column: $table.costType, builder: (column) => column);

  GeneratedColumn<int> get minutesOrCount => $composableBuilder(
    column: $table.minutesOrCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyScoreImpact => $composableBuilder(
    column: $table.dailyScoreImpact,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$AttentionCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttentionCostsTable,
          AttentionCost,
          $$AttentionCostsTableFilterComposer,
          $$AttentionCostsTableOrderingComposer,
          $$AttentionCostsTableAnnotationComposer,
          $$AttentionCostsTableCreateCompanionBuilder,
          $$AttentionCostsTableUpdateCompanionBuilder,
          (
            AttentionCost,
            BaseReferences<_$AppDatabase, $AttentionCostsTable, AttentionCost>,
          ),
          AttentionCost,
          PrefetchHooks Function()
        > {
  $$AttentionCostsTableTableManager(
    _$AppDatabase db,
    $AttentionCostsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttentionCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttentionCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttentionCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<AttentionCostTypeColumn> costType = const Value.absent(),
                Value<int> minutesOrCount = const Value.absent(),
                Value<int> dailyScoreImpact = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttentionCostsCompanion(
                id: id,
                costType: costType,
                minutesOrCount: minutesOrCount,
                dailyScoreImpact: dailyScoreImpact,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required AttentionCostTypeColumn costType,
                required int minutesOrCount,
                required int dailyScoreImpact,
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttentionCostsCompanion.insert(
                id: id,
                costType: costType,
                minutesOrCount: minutesOrCount,
                dailyScoreImpact: dailyScoreImpact,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttentionCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttentionCostsTable,
      AttentionCost,
      $$AttentionCostsTableFilterComposer,
      $$AttentionCostsTableOrderingComposer,
      $$AttentionCostsTableAnnotationComposer,
      $$AttentionCostsTableCreateCompanionBuilder,
      $$AttentionCostsTableUpdateCompanionBuilder,
      (
        AttentionCost,
        BaseReferences<_$AppDatabase, $AttentionCostsTable, AttentionCost>,
      ),
      AttentionCost,
      PrefetchHooks Function()
    >;
typedef $$ScrollLogsTableCreateCompanionBuilder =
    ScrollLogsCompanion Function({
      required String id,
      required String appName,
      required int durationMinutes,
      required int dailyScoreImpact,
      Value<bool> recoveryActionTaken,
      Value<String?> recoveryActionType,
      Value<String?> intent,
      Value<bool> wasTimeboxed,
      Value<int?> plannedMinutes,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });
typedef $$ScrollLogsTableUpdateCompanionBuilder =
    ScrollLogsCompanion Function({
      Value<String> id,
      Value<String> appName,
      Value<int> durationMinutes,
      Value<int> dailyScoreImpact,
      Value<bool> recoveryActionTaken,
      Value<String?> recoveryActionType,
      Value<String?> intent,
      Value<bool> wasTimeboxed,
      Value<int?> plannedMinutes,
      Value<DateTime> timestamp,
      Value<int> rowid,
    });

class $$ScrollLogsTableFilterComposer
    extends Composer<_$AppDatabase, $ScrollLogsTable> {
  $$ScrollLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyScoreImpact => $composableBuilder(
    column: $table.dailyScoreImpact,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recoveryActionTaken => $composableBuilder(
    column: $table.recoveryActionTaken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recoveryActionType => $composableBuilder(
    column: $table.recoveryActionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intent => $composableBuilder(
    column: $table.intent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasTimeboxed => $composableBuilder(
    column: $table.wasTimeboxed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ScrollLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $ScrollLogsTable> {
  $$ScrollLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyScoreImpact => $composableBuilder(
    column: $table.dailyScoreImpact,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recoveryActionTaken => $composableBuilder(
    column: $table.recoveryActionTaken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recoveryActionType => $composableBuilder(
    column: $table.recoveryActionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intent => $composableBuilder(
    column: $table.intent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasTimeboxed => $composableBuilder(
    column: $table.wasTimeboxed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ScrollLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ScrollLogsTable> {
  $$ScrollLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyScoreImpact => $composableBuilder(
    column: $table.dailyScoreImpact,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get recoveryActionTaken => $composableBuilder(
    column: $table.recoveryActionTaken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recoveryActionType => $composableBuilder(
    column: $table.recoveryActionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intent =>
      $composableBuilder(column: $table.intent, builder: (column) => column);

  GeneratedColumn<bool> get wasTimeboxed => $composableBuilder(
    column: $table.wasTimeboxed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get plannedMinutes => $composableBuilder(
    column: $table.plannedMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$ScrollLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ScrollLogsTable,
          ScrollLog,
          $$ScrollLogsTableFilterComposer,
          $$ScrollLogsTableOrderingComposer,
          $$ScrollLogsTableAnnotationComposer,
          $$ScrollLogsTableCreateCompanionBuilder,
          $$ScrollLogsTableUpdateCompanionBuilder,
          (
            ScrollLog,
            BaseReferences<_$AppDatabase, $ScrollLogsTable, ScrollLog>,
          ),
          ScrollLog,
          PrefetchHooks Function()
        > {
  $$ScrollLogsTableTableManager(_$AppDatabase db, $ScrollLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ScrollLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ScrollLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ScrollLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<int> dailyScoreImpact = const Value.absent(),
                Value<bool> recoveryActionTaken = const Value.absent(),
                Value<String?> recoveryActionType = const Value.absent(),
                Value<String?> intent = const Value.absent(),
                Value<bool> wasTimeboxed = const Value.absent(),
                Value<int?> plannedMinutes = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScrollLogsCompanion(
                id: id,
                appName: appName,
                durationMinutes: durationMinutes,
                dailyScoreImpact: dailyScoreImpact,
                recoveryActionTaken: recoveryActionTaken,
                recoveryActionType: recoveryActionType,
                intent: intent,
                wasTimeboxed: wasTimeboxed,
                plannedMinutes: plannedMinutes,
                timestamp: timestamp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String appName,
                required int durationMinutes,
                required int dailyScoreImpact,
                Value<bool> recoveryActionTaken = const Value.absent(),
                Value<String?> recoveryActionType = const Value.absent(),
                Value<String?> intent = const Value.absent(),
                Value<bool> wasTimeboxed = const Value.absent(),
                Value<int?> plannedMinutes = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScrollLogsCompanion.insert(
                id: id,
                appName: appName,
                durationMinutes: durationMinutes,
                dailyScoreImpact: dailyScoreImpact,
                recoveryActionTaken: recoveryActionTaken,
                recoveryActionType: recoveryActionType,
                intent: intent,
                wasTimeboxed: wasTimeboxed,
                plannedMinutes: plannedMinutes,
                timestamp: timestamp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ScrollLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ScrollLogsTable,
      ScrollLog,
      $$ScrollLogsTableFilterComposer,
      $$ScrollLogsTableOrderingComposer,
      $$ScrollLogsTableAnnotationComposer,
      $$ScrollLogsTableCreateCompanionBuilder,
      $$ScrollLogsTableUpdateCompanionBuilder,
      (ScrollLog, BaseReferences<_$AppDatabase, $ScrollLogsTable, ScrollLog>),
      ScrollLog,
      PrefetchHooks Function()
    >;
typedef $$EnergyCheckInsTableCreateCompanionBuilder =
    EnergyCheckInsCompanion Function({
      required String id,
      required TimeOfDayColumn timeOfDay,
      required int value,
      required DateTime date,
      Value<int> rowid,
    });
typedef $$EnergyCheckInsTableUpdateCompanionBuilder =
    EnergyCheckInsCompanion Function({
      Value<String> id,
      Value<TimeOfDayColumn> timeOfDay,
      Value<int> value,
      Value<DateTime> date,
      Value<int> rowid,
    });

class $$EnergyCheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $EnergyCheckInsTable> {
  $$EnergyCheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TimeOfDayColumn, TimeOfDayColumn, String>
  get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EnergyCheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $EnergyCheckInsTable> {
  $$EnergyCheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EnergyCheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EnergyCheckInsTable> {
  $$EnergyCheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TimeOfDayColumn, String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);
}

class $$EnergyCheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EnergyCheckInsTable,
          EnergyCheckIn,
          $$EnergyCheckInsTableFilterComposer,
          $$EnergyCheckInsTableOrderingComposer,
          $$EnergyCheckInsTableAnnotationComposer,
          $$EnergyCheckInsTableCreateCompanionBuilder,
          $$EnergyCheckInsTableUpdateCompanionBuilder,
          (
            EnergyCheckIn,
            BaseReferences<_$AppDatabase, $EnergyCheckInsTable, EnergyCheckIn>,
          ),
          EnergyCheckIn,
          PrefetchHooks Function()
        > {
  $$EnergyCheckInsTableTableManager(
    _$AppDatabase db,
    $EnergyCheckInsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EnergyCheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EnergyCheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EnergyCheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<TimeOfDayColumn> timeOfDay = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EnergyCheckInsCompanion(
                id: id,
                timeOfDay: timeOfDay,
                value: value,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required TimeOfDayColumn timeOfDay,
                required int value,
                required DateTime date,
                Value<int> rowid = const Value.absent(),
              }) => EnergyCheckInsCompanion.insert(
                id: id,
                timeOfDay: timeOfDay,
                value: value,
                date: date,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EnergyCheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EnergyCheckInsTable,
      EnergyCheckIn,
      $$EnergyCheckInsTableFilterComposer,
      $$EnergyCheckInsTableOrderingComposer,
      $$EnergyCheckInsTableAnnotationComposer,
      $$EnergyCheckInsTableCreateCompanionBuilder,
      $$EnergyCheckInsTableUpdateCompanionBuilder,
      (
        EnergyCheckIn,
        BaseReferences<_$AppDatabase, $EnergyCheckInsTable, EnergyCheckIn>,
      ),
      EnergyCheckIn,
      PrefetchHooks Function()
    >;
typedef $$DailyReportsTableCreateCompanionBuilder =
    DailyReportsCompanion Function({
      required String id,
      required DateTime date,
      required String reportJson,
      required int dailyScore,
      required int xpEarnedToday,
      Value<int> attentionCostToday,
      Value<int?> promptVersion,
      Value<DateTime> generatedAt,
      Value<int> rowid,
    });
typedef $$DailyReportsTableUpdateCompanionBuilder =
    DailyReportsCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String> reportJson,
      Value<int> dailyScore,
      Value<int> xpEarnedToday,
      Value<int> attentionCostToday,
      Value<int?> promptVersion,
      Value<DateTime> generatedAt,
      Value<int> rowid,
    });

class $$DailyReportsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyReportsTable> {
  $$DailyReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reportJson => $composableBuilder(
    column: $table.reportJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyScore => $composableBuilder(
    column: $table.dailyScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpEarnedToday => $composableBuilder(
    column: $table.xpEarnedToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attentionCostToday => $composableBuilder(
    column: $table.attentionCostToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyReportsTable> {
  $$DailyReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reportJson => $composableBuilder(
    column: $table.reportJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyScore => $composableBuilder(
    column: $table.dailyScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpEarnedToday => $composableBuilder(
    column: $table.xpEarnedToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attentionCostToday => $composableBuilder(
    column: $table.attentionCostToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyReportsTable> {
  $$DailyReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get reportJson => $composableBuilder(
    column: $table.reportJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyScore => $composableBuilder(
    column: $table.dailyScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get xpEarnedToday => $composableBuilder(
    column: $table.xpEarnedToday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attentionCostToday => $composableBuilder(
    column: $table.attentionCostToday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get promptVersion => $composableBuilder(
    column: $table.promptVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );
}

class $$DailyReportsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyReportsTable,
          DailyReport,
          $$DailyReportsTableFilterComposer,
          $$DailyReportsTableOrderingComposer,
          $$DailyReportsTableAnnotationComposer,
          $$DailyReportsTableCreateCompanionBuilder,
          $$DailyReportsTableUpdateCompanionBuilder,
          (
            DailyReport,
            BaseReferences<_$AppDatabase, $DailyReportsTable, DailyReport>,
          ),
          DailyReport,
          PrefetchHooks Function()
        > {
  $$DailyReportsTableTableManager(_$AppDatabase db, $DailyReportsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> reportJson = const Value.absent(),
                Value<int> dailyScore = const Value.absent(),
                Value<int> xpEarnedToday = const Value.absent(),
                Value<int> attentionCostToday = const Value.absent(),
                Value<int?> promptVersion = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion(
                id: id,
                date: date,
                reportJson: reportJson,
                dailyScore: dailyScore,
                xpEarnedToday: xpEarnedToday,
                attentionCostToday: attentionCostToday,
                promptVersion: promptVersion,
                generatedAt: generatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                required String reportJson,
                required int dailyScore,
                required int xpEarnedToday,
                Value<int> attentionCostToday = const Value.absent(),
                Value<int?> promptVersion = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyReportsCompanion.insert(
                id: id,
                date: date,
                reportJson: reportJson,
                dailyScore: dailyScore,
                xpEarnedToday: xpEarnedToday,
                attentionCostToday: attentionCostToday,
                promptVersion: promptVersion,
                generatedAt: generatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyReportsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyReportsTable,
      DailyReport,
      $$DailyReportsTableFilterComposer,
      $$DailyReportsTableOrderingComposer,
      $$DailyReportsTableAnnotationComposer,
      $$DailyReportsTableCreateCompanionBuilder,
      $$DailyReportsTableUpdateCompanionBuilder,
      (
        DailyReport,
        BaseReferences<_$AppDatabase, $DailyReportsTable, DailyReport>,
      ),
      DailyReport,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      required String id,
      required String achievementKey,
      Value<DateTime> unlockedAt,
      Value<int> rowid,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<String> id,
      Value<String> achievementKey,
      Value<DateTime> unlockedAt,
      Value<int> rowid,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get achievementKey => $composableBuilder(
    column: $table.achievementKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievementKey => $composableBuilder(
    column: $table.achievementKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get achievementKey => $composableBuilder(
    column: $table.achievementKey,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementsTable,
          Achievement,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            Achievement,
            BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
          ),
          Achievement,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> achievementKey = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                achievementKey: achievementKey,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String achievementKey,
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                achievementKey: achievementKey,
                unlockedAt: unlockedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementsTable,
      Achievement,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        Achievement,
        BaseReferences<_$AppDatabase, $AchievementsTable, Achievement>,
      ),
      Achievement,
      PrefetchHooks Function()
    >;
typedef $$DailyPlansTableCreateCompanionBuilder =
    DailyPlansCompanion Function({
      required String id,
      required DateTime date,
      Value<String?> mit1Id,
      Value<String?> mit2Id,
      Value<String?> mit3Id,
      Value<int> morningEnergy,
      Value<int> scrollBudgetMinutes,
      Value<bool> intentionCompleted,
      Value<bool> shutdownCompleted,
      Value<String?> intentionNote,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$DailyPlansTableUpdateCompanionBuilder =
    DailyPlansCompanion Function({
      Value<String> id,
      Value<DateTime> date,
      Value<String?> mit1Id,
      Value<String?> mit2Id,
      Value<String?> mit3Id,
      Value<int> morningEnergy,
      Value<int> scrollBudgetMinutes,
      Value<bool> intentionCompleted,
      Value<bool> shutdownCompleted,
      Value<String?> intentionNote,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$DailyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mit1Id => $composableBuilder(
    column: $table.mit1Id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mit2Id => $composableBuilder(
    column: $table.mit2Id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mit3Id => $composableBuilder(
    column: $table.mit3Id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get morningEnergy => $composableBuilder(
    column: $table.morningEnergy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scrollBudgetMinutes => $composableBuilder(
    column: $table.scrollBudgetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get intentionCompleted => $composableBuilder(
    column: $table.intentionCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get shutdownCompleted => $composableBuilder(
    column: $table.shutdownCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intentionNote => $composableBuilder(
    column: $table.intentionNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mit1Id => $composableBuilder(
    column: $table.mit1Id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mit2Id => $composableBuilder(
    column: $table.mit2Id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mit3Id => $composableBuilder(
    column: $table.mit3Id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get morningEnergy => $composableBuilder(
    column: $table.morningEnergy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scrollBudgetMinutes => $composableBuilder(
    column: $table.scrollBudgetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get intentionCompleted => $composableBuilder(
    column: $table.intentionCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get shutdownCompleted => $composableBuilder(
    column: $table.shutdownCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intentionNote => $composableBuilder(
    column: $table.intentionNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get mit1Id =>
      $composableBuilder(column: $table.mit1Id, builder: (column) => column);

  GeneratedColumn<String> get mit2Id =>
      $composableBuilder(column: $table.mit2Id, builder: (column) => column);

  GeneratedColumn<String> get mit3Id =>
      $composableBuilder(column: $table.mit3Id, builder: (column) => column);

  GeneratedColumn<int> get morningEnergy => $composableBuilder(
    column: $table.morningEnergy,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scrollBudgetMinutes => $composableBuilder(
    column: $table.scrollBudgetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get intentionCompleted => $composableBuilder(
    column: $table.intentionCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get shutdownCompleted => $composableBuilder(
    column: $table.shutdownCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intentionNote => $composableBuilder(
    column: $table.intentionNote,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPlansTable,
          DailyPlan,
          $$DailyPlansTableFilterComposer,
          $$DailyPlansTableOrderingComposer,
          $$DailyPlansTableAnnotationComposer,
          $$DailyPlansTableCreateCompanionBuilder,
          $$DailyPlansTableUpdateCompanionBuilder,
          (
            DailyPlan,
            BaseReferences<_$AppDatabase, $DailyPlansTable, DailyPlan>,
          ),
          DailyPlan,
          PrefetchHooks Function()
        > {
  $$DailyPlansTableTableManager(_$AppDatabase db, $DailyPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> mit1Id = const Value.absent(),
                Value<String?> mit2Id = const Value.absent(),
                Value<String?> mit3Id = const Value.absent(),
                Value<int> morningEnergy = const Value.absent(),
                Value<int> scrollBudgetMinutes = const Value.absent(),
                Value<bool> intentionCompleted = const Value.absent(),
                Value<bool> shutdownCompleted = const Value.absent(),
                Value<String?> intentionNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPlansCompanion(
                id: id,
                date: date,
                mit1Id: mit1Id,
                mit2Id: mit2Id,
                mit3Id: mit3Id,
                morningEnergy: morningEnergy,
                scrollBudgetMinutes: scrollBudgetMinutes,
                intentionCompleted: intentionCompleted,
                shutdownCompleted: shutdownCompleted,
                intentionNote: intentionNote,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime date,
                Value<String?> mit1Id = const Value.absent(),
                Value<String?> mit2Id = const Value.absent(),
                Value<String?> mit3Id = const Value.absent(),
                Value<int> morningEnergy = const Value.absent(),
                Value<int> scrollBudgetMinutes = const Value.absent(),
                Value<bool> intentionCompleted = const Value.absent(),
                Value<bool> shutdownCompleted = const Value.absent(),
                Value<String?> intentionNote = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPlansCompanion.insert(
                id: id,
                date: date,
                mit1Id: mit1Id,
                mit2Id: mit2Id,
                mit3Id: mit3Id,
                morningEnergy: morningEnergy,
                scrollBudgetMinutes: scrollBudgetMinutes,
                intentionCompleted: intentionCompleted,
                shutdownCompleted: shutdownCompleted,
                intentionNote: intentionNote,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPlansTable,
      DailyPlan,
      $$DailyPlansTableFilterComposer,
      $$DailyPlansTableOrderingComposer,
      $$DailyPlansTableAnnotationComposer,
      $$DailyPlansTableCreateCompanionBuilder,
      $$DailyPlansTableUpdateCompanionBuilder,
      (DailyPlan, BaseReferences<_$AppDatabase, $DailyPlansTable, DailyPlan>),
      DailyPlan,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$FocusSessionsTableTableManager get focusSessions =>
      $$FocusSessionsTableTableManager(_db, _db.focusSessions);
  $$XpLedgerEntriesTableTableManager get xpLedgerEntries =>
      $$XpLedgerEntriesTableTableManager(_db, _db.xpLedgerEntries);
  $$AttentionCostsTableTableManager get attentionCosts =>
      $$AttentionCostsTableTableManager(_db, _db.attentionCosts);
  $$ScrollLogsTableTableManager get scrollLogs =>
      $$ScrollLogsTableTableManager(_db, _db.scrollLogs);
  $$EnergyCheckInsTableTableManager get energyCheckIns =>
      $$EnergyCheckInsTableTableManager(_db, _db.energyCheckIns);
  $$DailyReportsTableTableManager get dailyReports =>
      $$DailyReportsTableTableManager(_db, _db.dailyReports);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$DailyPlansTableTableManager get dailyPlans =>
      $$DailyPlansTableTableManager(_db, _db.dailyPlans);
}
