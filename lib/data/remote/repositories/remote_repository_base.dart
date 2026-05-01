import '../../../core/result/app_result.dart';
import '../remote_errors.dart';
import '../supabase_client_provider.dart';

abstract class RemoteRepositoryBase {
  const RemoteRepositoryBase(this.clientProvider);

  final SupabaseClientProvider clientProvider;

  Future<AppResult<List<Map<String, dynamic>>>> fetchUpdatedRows({
    required String table,
    required String tenantId,
    DateTime? updatedAfter,
  }) async {
    final tenantError = _validateTenantId(tenantId);
    if (tenantError != null) return AppFailure(tenantError);
    final clientResult = clientProvider.requireClient();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    final client = clientResult.valueOrNull!;
    try {
      dynamic query = client.from(table).select().eq('tenant_id', tenantId);
      if (updatedAfter != null) {
        query = query.gt('updated_at', updatedAfter.toUtc().toIso8601String());
      }
      final rows = await query;
      return AppSuccess([
        for (final row in rows as List) Map<String, dynamic>.from(row as Map),
      ]);
    } catch (error) {
      return AppFailure(
        AppError(
          code: RemoteErrorCodes.remoteReadFailed,
          message: 'Lecture distante impossible pour $table.',
          cause: error,
        ),
      );
    }
  }

  Future<AppResult<void>> upsertRows({
    required String table,
    required String tenantId,
    required List<Map<String, dynamic>> rows,
  }) async {
    final tenantError = _validateTenantId(tenantId);
    if (tenantError != null) return AppFailure(tenantError);
    if (rows.isEmpty) return const AppSuccess(null);
    final clientResult = clientProvider.requireClient();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    final client = clientResult.valueOrNull!;
    try {
      final scopedRows = [
        for (final row in rows) {...row, 'tenant_id': tenantId},
      ];
      await client.from(table).upsert(scopedRows, onConflict: 'id');
      return const AppSuccess(null);
    } catch (error) {
      return AppFailure(
        AppError(
          code: RemoteErrorCodes.remoteWriteFailed,
          message: 'Écriture distante impossible pour $table.',
          cause: error,
        ),
      );
    }
  }

  Future<AppResult<void>> softDeleteRow({
    required String table,
    required String tenantId,
    required String id,
    DateTime? deletedAt,
  }) async {
    final tenantError = _validateTenantId(tenantId);
    if (tenantError != null) return AppFailure(tenantError);
    final clientResult = clientProvider.requireClient();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    final client = clientResult.valueOrNull!;
    try {
      await client
          .from(table)
          .update({
            'deleted_at': (deletedAt ?? DateTime.now())
                .toUtc()
                .toIso8601String(),
          })
          .eq('tenant_id', tenantId)
          .eq('id', id);
      return const AppSuccess(null);
    } catch (error) {
      return AppFailure(
        AppError(
          code: RemoteErrorCodes.remoteSoftDeleteFailed,
          message: 'Suppression distante impossible pour $table.',
          cause: error,
        ),
      );
    }
  }

  AppError? _validateTenantId(String tenantId) {
    if (tenantId.trim().isNotEmpty) return null;
    return const AppError(
      code: RemoteErrorCodes.missingTenantId,
      message: 'Aucune société sélectionnée pour la requête distante.',
    );
  }
}
