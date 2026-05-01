part of '../app_database.dart';

@DataClassName('ProductRow')
@TableIndex(name: 'idx_products_tenant_name', columns: {#tenantId, #name})
@TableIndex(name: 'idx_products_tenant_sku', columns: {#tenantId, #sku})
@TableIndex(name: 'idx_products_tenant_barcode', columns: {#tenantId, #barcode})
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get name => text()();
  TextColumn get sku => text().withDefault(const Constant(''))();
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName => text().withDefault(const Constant(''))();
  TextColumn get brand => text().withDefault(const Constant(''))();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get purchasePriceHt => real().withDefault(const Constant(0))();
  RealColumn get salePriceHt => real().withDefault(const Constant(0))();
  TextColumn get tvaRate => text().withDefault(const Constant('rate19'))();
  IntColumn get stockMinimum => integer().withDefault(const Constant(0))();
  TextColumn get imagePath => text().withDefault(const Constant(''))();
  TextColumn get stockByWarehouseJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get serialsByWarehouseJson =>
      text().withDefault(const Constant('{}'))();
  BoolColumn get serialTracked =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get stockTracked => boolean().withDefault(const Constant(true))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
