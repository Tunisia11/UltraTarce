part of '../app_database.dart';

@DriftAccessor(tables: [Products])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<ProductRow>> getAllProducts({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final query = select(products)
      ..where((table) => table.tenantId.equals(tenantId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (!includeArchived) {
      query.where((table) => table.isActive.equals(true));
    }
    return query.get();
  }

  Stream<List<ProductRow>> watchAllProducts({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final query = select(products)
      ..where((table) => table.tenantId.equals(tenantId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (!includeArchived) {
      query.where((table) => table.isActive.equals(true));
    }
    return query.watch();
  }

  Future<ProductRow?> getProductById(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (select(products)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .getSingleOrNull();
  }

  Future<void> upsertProduct(ProductsCompanion product) {
    return into(products).insertOnConflictUpdate(product);
  }

  Future<void> archiveProduct(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (update(products)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .write(
          ProductsCompanion(
            isActive: const Value(false),
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );
  }

  Future<void> deleteProduct(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (delete(products)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .go();
  }

  Future<List<ProductRow>> searchProducts(
    String query, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final normalized = '%${query.trim().toLowerCase()}%';
    if (query.trim().isEmpty) return getAllProducts(tenantId: tenantId);
    return (select(products)
          ..where(
            (table) =>
                table.tenantId.equals(tenantId) &
                (table.name.lower().like(normalized) |
                    table.sku.lower().like(normalized) |
                    table.categoryName.lower().like(normalized) |
                    table.brand.lower().like(normalized) |
                    table.barcode.lower().like(normalized)),
          )
          ..orderBy([(table) => OrderingTerm.asc(table.name)]))
        .get();
  }
}
