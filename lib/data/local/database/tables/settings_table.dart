part of '../app_database.dart';

@DataClassName('SettingRow')
@TableIndex(name: 'idx_settings_tenant_key', columns: {#tenantId, #key})
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get valueJson => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
