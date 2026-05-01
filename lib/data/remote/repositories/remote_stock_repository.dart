import '../../../core/result/app_result.dart';
import '../remote_tables.dart';
import 'remote_repository_base.dart';

class RemoteStockRepository extends RemoteRepositoryBase {
  const RemoteStockRepository(super.clientProvider);

  Future<AppResult<List<Map<String, dynamic>>>> fetchMovementsUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.stockMovements,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<void>> upsertMovements({
    required String tenantId,
    required List<Map<String, dynamic>> rows,
  }) {
    return upsertRows(
      table: RemoteTables.stockMovements,
      tenantId: tenantId,
      rows: rows,
    );
  }
}
