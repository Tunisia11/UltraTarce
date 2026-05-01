part of '../app_database.dart';

@DataClassName('StockMovementRow')
@TableIndex(
  name: 'idx_stock_movements_tenant_product_warehouse_created_at',
  columns: {#tenantId, #productId, #warehouseId, #createdAt},
)
class StockMovements extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get productId => text()();
  TextColumn get productName => text().withDefault(const Constant(''))();
  TextColumn get warehouseId => text().withDefault(const Constant(''))();
  IntColumn get quantityDelta => integer().withDefault(const Constant(0))();
  TextColumn get type => text().withDefault(const Constant('manual'))();
  TextColumn get reason => text().withDefault(const Constant(''))();
  TextColumn get direction => text().withDefault(const Constant('inbound'))();
  TextColumn get documentNumber => text().withDefault(const Constant(''))();
  TextColumn get sourceDocumentId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdBy => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get serialNumbersJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
