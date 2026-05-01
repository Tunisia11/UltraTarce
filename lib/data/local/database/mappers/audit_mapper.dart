import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';
import '../tenant_row_scope.dart';

class AuditMapper {
  static AuditEventsCompanion toCompanion(
    AuditEvent event, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return AuditEventsCompanion(
      id: Value(TenantRowScope.rowId(tenantId, event.id)),
      tenantId: Value(tenantId),
      type: Value(event.action),
      title: Value(event.action),
      description: Value(event.detail),
      actor: Value(event.actor),
      action: Value(event.action),
      target: Value(event.target),
      detail: Value(event.detail),
      entityType: Value(event.target.isEmpty ? null : event.target),
      createdAt: Value(event.date),
    );
  }

  static AuditEvent fromRow(
    AuditEventRow row, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return AuditEvent(
      id: TenantRowScope.domainId(tenantId, row.id),
      date: row.createdAt,
      actor: row.actor,
      action: row.action,
      target: row.target,
      detail: row.detail,
    );
  }
}
