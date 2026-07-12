// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_checkins_dao.dart';

// ignore_for_file: type=lint
mixin _$EnergyCheckInsDaoMixin on DatabaseAccessor<AppDatabase> {
  $EnergyCheckInsTable get energyCheckIns => attachedDatabase.energyCheckIns;
  EnergyCheckInsDaoManager get managers => EnergyCheckInsDaoManager(this);
}

class EnergyCheckInsDaoManager {
  final _$EnergyCheckInsDaoMixin _db;
  EnergyCheckInsDaoManager(this._db);
  $$EnergyCheckInsTableTableManager get energyCheckIns =>
      $$EnergyCheckInsTableTableManager(
        _db.attachedDatabase,
        _db.energyCheckIns,
      );
}
