part of '../app_database.dart';

@DriftAccessor(tables: [Partners])
class PartnerDao extends DatabaseAccessor<AppDatabase> with _$PartnerDaoMixin {
  PartnerDao(super.db);

  Future<List<PartnerRow>> getClients({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return _partnersByType(
      'client',
      includeArchived: includeArchived,
      tenantId: tenantId,
    ).get();
  }

  Future<List<PartnerRow>> getSuppliers({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return _partnersByType(
      'supplier',
      includeArchived: includeArchived,
      tenantId: tenantId,
    ).get();
  }

  Stream<List<PartnerRow>> watchClients({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return _partnersByType(
      'client',
      includeArchived: includeArchived,
      tenantId: tenantId,
    ).watch();
  }

  Stream<List<PartnerRow>> watchSuppliers({
    bool includeArchived = true,
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return _partnersByType(
      'supplier',
      includeArchived: includeArchived,
      tenantId: tenantId,
    ).watch();
  }

  Future<void> upsertPartner(PartnersCompanion partner) {
    return into(partners).insertOnConflictUpdate(partner);
  }

  Future<void> archivePartner(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (update(partners)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .write(
          PartnersCompanion(
            isActive: const Value(false),
            updatedAt: Value(now),
            deletedAt: Value(now),
          ),
        );
  }

  Future<void> deletePartner(
    String id, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final rowId = TenantRowScope.rowId(tenantId, id);
    return (delete(partners)..where(
          (table) => table.id.equals(rowId) & table.tenantId.equals(tenantId),
        ))
        .go();
  }

  SimpleSelectStatement<$PartnersTable, PartnerRow> _partnersByType(
    String type, {
    required bool includeArchived,
    required String tenantId,
  }) {
    final query = select(partners)
      ..where(
        (table) => table.tenantId.equals(tenantId) & table.type.equals(type),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.name)]);
    if (!includeArchived) {
      query.where((table) => table.isActive.equals(true));
    }
    return query;
  }
}
