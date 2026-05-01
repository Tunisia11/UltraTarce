part of '../app_database.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<CategoryRow>> getCategories({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final query = select(categories)
      ..where((table) => table.tenantId.equals(tenantId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (!includeArchived) {
      query.where((table) => table.isActive.equals(true));
    }
    return query.get();
  }

  Stream<List<CategoryRow>> watchCategories({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final query = select(categories)
      ..where((table) => table.tenantId.equals(tenantId))
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (!includeArchived) {
      query.where((table) => table.isActive.equals(true));
    }
    return query.watch();
  }

  Future<CategoryRow?> getDefaultCategory({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(categories)
          ..where((table) => table.tenantId.equals(tenantId))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> upsertCategory(CategoriesCompanion category) {
    return into(categories).insertOnConflictUpdate(category);
  }

  Future<void> archiveCategory(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (update(categories)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .write(
          CategoriesCompanion(
            isActive: const Value(false),
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );
  }

  Future<void> deleteCategory(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (delete(categories)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .go();
  }
}
