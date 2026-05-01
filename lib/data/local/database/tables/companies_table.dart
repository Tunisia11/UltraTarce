part of '../app_database.dart';

@DataClassName('CompanyRow')
@TableIndex(name: 'idx_companies_tenant_id', columns: {#tenantId})
class Companies extends Table {
  TextColumn get id => text().withDefault(const Constant('default'))();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get name => text()();
  TextColumn get legalName => text().nullable()();
  TextColumn get taxId => text().withDefault(const Constant(''))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get city => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  TextColumn get email => text().withDefault(const Constant(''))();
  TextColumn get logoPath => text().nullable()();
  TextColumn get logoSource => text().withDefault(const Constant(''))();
  TextColumn get invoiceFooter => text().withDefault(const Constant(''))();
  TextColumn get legalInfo => text().withDefault(const Constant(''))();
  BoolColumn get timbreFiscalEnabled =>
      boolean().withDefault(const Constant(true))();
  RealColumn get timbreFiscalAmount => real().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
