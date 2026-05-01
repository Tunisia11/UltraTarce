part of '../app_database.dart';

@DriftAccessor(tables: [AuditEvents])
class AuditDao extends DatabaseAccessor<AppDatabase> with _$AuditDaoMixin {
  AuditDao(super.db);

  Future<List<AuditEventRow>> getAuditEvents({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(auditEvents)
          ..where((table) => table.tenantId.equals(tenantId))
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .get();
  }

  Stream<List<AuditEventRow>> watchAuditEvents({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(auditEvents)
          ..where((table) => table.tenantId.equals(tenantId))
          ..orderBy([(table) => OrderingTerm.desc(table.createdAt)]))
        .watch();
  }

  Future<void> addAuditEvent(AuditEventsCompanion event) {
    return into(auditEvents).insertOnConflictUpdate(event);
  }

  Future<void> deleteAuditEventsNotIn(
    Set<String> ids, {
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    if (ids.isEmpty) {
      await (delete(
        auditEvents,
      )..where((table) => table.tenantId.equals(tenantId))).go();
      return;
    }
    final rowIds = ids.map((id) => TenantRowScope.rowId(tenantId, id)).toList();
    await (delete(auditEvents)..where(
          (table) => table.tenantId.equals(tenantId) & table.id.isNotIn(rowIds),
        ))
        .go();
  }
}
