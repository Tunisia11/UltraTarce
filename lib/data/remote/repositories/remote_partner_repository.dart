import '../../../core/result/app_result.dart';
import '../remote_tables.dart';
import 'remote_repository_base.dart';

class RemotePartnerRepository extends RemoteRepositoryBase {
  const RemotePartnerRepository(super.clientProvider);

  Future<AppResult<List<Map<String, dynamic>>>> fetchPartnersUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.partners,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<void>> upsertPartners({
    required String tenantId,
    required List<Map<String, dynamic>> rows,
  }) {
    return upsertRows(
      table: RemoteTables.partners,
      tenantId: tenantId,
      rows: rows,
    );
  }
}
