part of '../app_database.dart';

@DriftAccessor(tables: [Warehouses])
class WarehouseDao extends DatabaseAccessor<AppDatabase>
    with _$WarehouseDaoMixin {
  WarehouseDao(super.db);

  Future<List<WarehouseRow>> getWarehouses({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final query = select(warehouses)
      ..where((table) => table.tenantId.equals(tenantId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (!includeArchived) {
      query.where((table) => table.isActive.equals(true));
    }
    return query.get();
  }

  Stream<List<WarehouseRow>> watchWarehouses({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final query = select(warehouses)
      ..where((table) => table.tenantId.equals(tenantId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (!includeArchived) {
      query.where((table) => table.isActive.equals(true));
    }
    return query.watch();
  }

  Future<WarehouseRow?> getDefaultWarehouse({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(warehouses)
          ..where(
            (table) =>
                table.tenantId.equals(tenantId) & table.isDefault.equals(true),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertWarehouse(WarehousesCompanion warehouse) {
    return into(warehouses).insertOnConflictUpdate(warehouse);
  }

  Future<void> archiveWarehouse(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (update(warehouses)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .write(
          WarehousesCompanion(
            isActive: const Value(false),
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );
  }

  Future<void> deleteWarehouse(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (delete(warehouses)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .go();
  }
}
