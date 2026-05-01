import '../../../core/result/app_result.dart';
import '../remote_tables.dart';
import 'remote_repository_base.dart';

class RemoteAuditRepository extends RemoteRepositoryBase {
  const RemoteAuditRepository(super.clientProvider);

  Future<AppResult<List<Map<String, dynamic>>>> fetchAuditEventsUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.auditEvents,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<void>> upsertAuditEvents({
    required String tenantId,
    required List<Map<String, dynamic>> rows,
  }) {
    return upsertRows(
      table: RemoteTables.auditEvents,
      tenantId: tenantId,
      rows: rows,
    );
  }
}
