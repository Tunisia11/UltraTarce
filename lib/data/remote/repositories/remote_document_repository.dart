import '../../../core/result/app_result.dart';
import '../remote_tables.dart';
import 'remote_repository_base.dart';

class RemoteDocumentRepository extends RemoteRepositoryBase {
  const RemoteDocumentRepository(super.clientProvider);

  Future<AppResult<List<Map<String, dynamic>>>> fetchDocumentsUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.documents,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<List<Map<String, dynamic>>>> fetchDocumentLinesUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.documentLines,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<List<Map<String, dynamic>>>> fetchPaymentsUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.payments,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<void>> upsertDocumentBundle({
    required String tenantId,
    required List<Map<String, dynamic>> documents,
    required List<Map<String, dynamic>> lines,
    required List<Map<String, dynamic>> payments,
  }) async {
    final documentResult = await upsertRows(
      table: RemoteTables.documents,
      tenantId: tenantId,
      rows: documents,
    );
    if (documentResult is AppFailure<void>) return documentResult;
    final lineResult = await upsertRows(
      table: RemoteTables.documentLines,
      tenantId: tenantId,
      rows: lines,
    );
    if (lineResult is AppFailure<void>) return lineResult;
    return upsertRows(
      table: RemoteTables.payments,
      tenantId: tenantId,
      rows: payments,
    );
  }
}
