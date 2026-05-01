part of '../app_database.dart';

@DriftAccessor(tables: [StockMovements, Products])
class StockDao extends DatabaseAccessor<AppDatabase> with _$StockDaoMixin {
  StockDao(super.db);

  Future<List<StockMovementRow>> getMovements({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(stockMovements)
          ..where((table) => table.tenantId.equals(tenantId))
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();
  }

  Stream<List<StockMovementRow>> watchMovements({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(stockMovements)
          ..where((table) => table.tenantId.equals(tenantId))
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .watch();
  }

  Future<void> addMovement(StockMovementsCompanion movement) {
    return into(stockMovements).insertOnConflictUpdate(movement);
  }

  Future<List<StockMovementRow>> getMovementsForProduct(
    String productId, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final rowProductId = TenantRowScope.rowId(tenantId, productId);
    return (select(stockMovements)
          ..where(
            (table) =>
                table.tenantId.equals(tenantId) &
                table.productId.equals(rowProductId),
          )
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();
  }

  Future<int> getCurrentStock(
    String productId,
    String warehouseId, {
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    final rowProductId = TenantRowScope.rowId(tenantId, productId);
    final rowWarehouseId = TenantRowScope.rowId(tenantId, warehouseId);
    final rows =
        await (select(stockMovements)..where(
              (table) =>
                  table.tenantId.equals(tenantId) &
                  table.productId.equals(rowProductId) &
                  table.warehouseId.equals(rowWarehouseId),
            ))
            .get();
    return rows.fold<int>(0, (total, row) => total + row.quantityDelta);
  }

  Future<Map<String, int>> getStockByProduct({
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    final rows = await getMovements(tenantId: tenantId);
    final totals = <String, int>{};
    for (final row in rows) {
      final productId = TenantRowScope.domainId(tenantId, row.productId);
      totals[productId] = (totals[productId] ?? 0) + row.quantityDelta;
    }
    return totals;
  }

  Future<List<ProductRow>> getLowStockProducts({
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    final rows = await (select(
      products,
    )..where((table) => table.tenantId.equals(tenantId))).get();
    return rows.where((row) {
      final stock = _stockTotalFromJson(row.stockByWarehouseJson);
      return row.stockTracked && row.isActive && stock <= row.stockMinimum;
    }).toList();
  }

  int _stockTotalFromJson(String raw) {
    final matches = RegExp(r':\s*(-?\d+)').allMatches(raw);
    return matches.fold<int>(
      0,
      (total, match) => total + int.parse(match.group(1)!),
    );
  }
}
