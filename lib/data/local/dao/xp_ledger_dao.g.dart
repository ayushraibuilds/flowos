// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'xp_ledger_dao.dart';

// ignore_for_file: type=lint
mixin _$XpLedgerDaoMixin on DatabaseAccessor<AppDatabase> {
  $XpLedgerEntriesTable get xpLedgerEntries => attachedDatabase.xpLedgerEntries;
  XpLedgerDaoManager get managers => XpLedgerDaoManager(this);
}

class XpLedgerDaoManager {
  final _$XpLedgerDaoMixin _db;
  XpLedgerDaoManager(this._db);
  $$XpLedgerEntriesTableTableManager get xpLedgerEntries =>
      $$XpLedgerEntriesTableTableManager(
        _db.attachedDatabase,
        _db.xpLedgerEntries,
      );
}
