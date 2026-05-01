import '../../../core/result/app_result.dart';
import '../remote_tables.dart';
import 'remote_repository_base.dart';

class RemoteProductRepository extends RemoteRepositoryBase {
  const RemoteProductRepository(super.clientProvider);

  Future<AppResult<List<Map<String, dynamic>>>> fetchProductsUpdatedSince({
    required String tenantId,
    DateTime? updatedAfter,
  }) {
    return fetchUpdatedRows(
      table: RemoteTables.products,
      tenantId: tenantId,
      updatedAfter: updatedAfter,
    );
  }

  Future<AppResult<void>> upsertProducts({
    required String tenantId,
    required List<Map<String, dynamic>> rows,
  }) {
    return upsertRows(
      table: RemoteTables.products,
      tenantId: tenantId,
      rows: rows,
    );
  }

  Future<AppResult<void>> softDeleteProduct({
    required String tenantId,
    required String id,
  }) {
    return softDeleteRow(
      table: RemoteTables.products,
      tenantId: tenantId,
      id: id,
    );
  }
}
