part of '../app_database.dart';

@DataClassName('PaymentRow')
@TableIndex(
  name: 'idx_payments_tenant_document',
  columns: {#tenantId, #documentId},
)
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get documentId => text()();
  RealColumn get amount => real().withDefault(const Constant(0))();
  TextColumn get method => text().withDefault(const Constant('cash'))();
  DateTimeColumn get date => dateTime()();
  TextColumn get reference => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
