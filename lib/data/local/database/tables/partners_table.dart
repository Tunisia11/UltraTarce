part of '../app_database.dart';

@DataClassName('PartnerRow')
@TableIndex(
  name: 'idx_partners_tenant_type_name',
  columns: {#tenantId, #type, #name},
)
class Partners extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get type => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get taxId => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get customerType =>
      text().withDefault(const Constant('entreprise'))();
  TextColumn get companyName => text().withDefault(const Constant(''))();
  TextColumn get contactName => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
