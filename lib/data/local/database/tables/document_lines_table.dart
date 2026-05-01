part of '../app_database.dart';

@DataClassName('DocumentLineRow')
@TableIndex(
  name: 'idx_document_lines_tenant_document',
  columns: {#tenantId, #documentId},
)
class DocumentLines extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get documentId => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get productId => text().nullable()();
  TextColumn get label => text()();
  TextColumn get sku => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  RealColumn get unitPriceHt => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  TextColumn get tvaRate => text().withDefault(const Constant('rate19'))();
  RealColumn get totalHt => real().withDefault(const Constant(0))();
  RealColumn get totalTva => real().withDefault(const Constant(0))();
  RealColumn get totalTtc => real().withDefault(const Constant(0))();
  TextColumn get serialNumbersJson =>
      text().withDefault(const Constant('[]'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
