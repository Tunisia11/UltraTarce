import '../../../core/result/app_result.dart';
import '../remote_tables.dart';
import 'remote_repository_base.dart';

class RemoteCompanyRepository extends RemoteRepositoryBase {
  const RemoteCompanyRepository(super.clientProvider);

  Future<AppResult<List<Map<String, dynamic>>>> fetchCompaniesUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.companies,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<List<Map<String, dynamic>>>> fetchSettingsUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.settings,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<void>> upsertCompanies({
    required String tenantId,
    required List<Map<String, dynamic>> rows,
  }) {
    return upsertRows(
      table: RemoteTables.companies,
      tenantId: tenantId,
      rows: rows,
    );
  }
}
