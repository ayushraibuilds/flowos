// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attention_costs_dao.dart';

// ignore_for_file: type=lint
mixin _$AttentionCostsDaoMixin on DatabaseAccessor<AppDatabase> {
  $AttentionCostsTable get attentionCosts => attachedDatabase.attentionCosts;
  AttentionCostsDaoManager get managers => AttentionCostsDaoManager(this);
}

class AttentionCostsDaoManager {
  final _$AttentionCostsDaoMixin _db;
  AttentionCostsDaoManager(this._db);
  $$AttentionCostsTableTableManager get attentionCosts =>
      $$AttentionCostsTableTableManager(
        _db.attachedDatabase,
        _db.attentionCosts,
      );
}
