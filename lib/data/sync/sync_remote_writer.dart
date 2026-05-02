import 'package:supabase_flutter/supabase_flutter.dart';
import '../remote/remote_tables.dart';
import '../../core/result/app_result.dart';
import '../remote/remote_errors.dart';
import '../remote/supabase_client_provider.dart';
import 'remote_sync_mapper.dart';

abstract class SyncRemoteWriter {
  Future<AppResult<String>> requireAuthenticatedUserId();

  Future<AppResult<bool>> rowExists({
    required String table,
    required String tenantId,
    required String id,
  });

  Future<AppResult<Map<String, dynamic>?>> findDocumentByNumber({
    required String tenantId,
    required String type,
    required String number,
  });

  Future<AppResult<void>> upsert(RemoteSyncWrite write);

  Future<AppResult<void>> softDelete(RemoteSyncWrite write);
}

class SupabaseSyncRemoteWriter implements SyncRemoteWriter {
  const SupabaseSyncRemoteWriter({required SupabaseClientProvider provider})
    : _provider = provider;

  final SupabaseClientProvider _provider;

  @override
  Future<AppResult<String>> requireAuthenticatedUserId() async {
    final clientResult = _provider.requireClient();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    final user = clientResult.valueOrNull!.auth.currentUser;
    final session = clientResult.valueOrNull!.auth.currentSession;
    if (user == null || session == null) {
      return const AppFailure(
        AppError(
          code: RemoteErrorCodes.authMissing,
          message: 'Connexion Supabase requise pour envoyer les changements.',
        ),
      );
    }
    return AppSuccess(user.id);
  }

  @override
  Future<AppResult<bool>> rowExists({
    required String table,
    required String tenantId,
    required String id,
  }) async {
    final clientResult = _clientWithSession();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    try {
      final rows = await clientResult.valueOrNull!
          .from(table)
          .select('id')
          .eq('tenant_id', tenantId)
          .eq('id', id)
          .limit(1);
      return AppSuccess((rows as List).isNotEmpty);
    } catch (error) {
      return AppFailure(_remoteError(error, 'Lecture distante impossible.'));
    }
  }

  @override
  Future<AppResult<Map<String, dynamic>?>> findDocumentByNumber({
    required String tenantId,
    required String type,
    required String number,
  }) async {
    final clientResult = _clientWithSession();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    try {
      final rows = await clientResult.valueOrNull!
          .from(RemoteTables.documents)
          .select('id, sync_origin_device_id')
          .eq('tenant_id', tenantId)
          .eq('type', type)
          .eq('number', number)
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) return const AppSuccess(null);
      return AppSuccess(list.first as Map<String, dynamic>);
    } catch (error) {
      return AppFailure(_remoteError(error, 'Lecture distante impossible.'));
    }
  }

  @override
  Future<AppResult<void>> upsert(RemoteSyncWrite write) async {
    final clientResult = _clientWithSession();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    try {
      await clientResult.valueOrNull!
          .from(write.table)
          .upsert(write.payload, onConflict: 'id');
      return const AppSuccess(null);
    } catch (error) {
      return AppFailure(_remoteError(error, 'Écriture distante impossible.'));
    }
  }

  @override
  Future<AppResult<void>> softDelete(RemoteSyncWrite write) async {
    final clientResult = _clientWithSession();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    try {
      await clientResult.valueOrNull!
          .from(write.table)
          .update({
            'deleted_at': (write.deletedAt ?? DateTime.now())
                .toUtc()
                .toIso8601String(),
            'local_updated_at': DateTime.now().toUtc().toIso8601String(),
            if (write.payload['sync_origin_device_id'] != null)
              'sync_origin_device_id': write.payload['sync_origin_device_id'],
            if (write.payload['updated_by'] != null)
              'updated_by': write.payload['updated_by'],
          })
          .eq('tenant_id', write.tenantId)
          .eq('id', write.entityId);
      return const AppSuccess(null);
    } catch (error) {
      return AppFailure(
        _remoteError(error, 'Suppression distante impossible.'),
      );
    }
  }

  AppResult<SupabaseClient> _clientWithSession() {
    final clientResult = _provider.requireClient();
    final clientError = clientResult.errorOrNull;
    if (clientError != null) return AppFailure(clientError);
    final client = clientResult.valueOrNull!;
    if (client.auth.currentUser == null || client.auth.currentSession == null) {
      return const AppFailure(
        AppError(
          code: RemoteErrorCodes.authMissing,
          message: 'Connexion Supabase requise pour envoyer les changements.',
        ),
      );
    }
    return AppSuccess(client);
  }

  AppError _remoteError(Object error, String fallbackMessage) {
    final text = error.toString().toLowerCase();
    final code = _errorCode(text);

    String detailedMessage = fallbackMessage;
    if (error is PostgrestException) {
      final details = [
        error.message,
        error.details,
        error.hint,
      ].where((e) => e != null && e.toString().isNotEmpty).join(' - ');
      detailedMessage = '$fallbackMessage ($details)';
    } else if (code == RemoteErrorCodes.unknownRemoteError) {
      detailedMessage = '$fallbackMessage ($error)';
    }

    return AppError(
      code: code,
      message: switch (code) {
        RemoteErrorCodes.rlsDenied =>
          'Accès distant refusé pour cette société.',
        RemoteErrorCodes.networkError =>
          'Réseau indisponible pendant la synchronisation.',
        RemoteErrorCodes.validationError =>
          'Données refusées par la base distante.',
        _ => detailedMessage,
      },
      cause: error,
    );
  }

  String _errorCode(String text) {
    if (text.contains('row-level security') ||
        text.contains('permission denied') ||
        text.contains('42501')) {
      return RemoteErrorCodes.rlsDenied;
    }
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('xmlhttprequest')) {
      return RemoteErrorCodes.networkError;
    }
    if (text.contains('invalid input syntax') ||
        text.contains('violates') ||
        text.contains('not-null') ||
        text.contains('23502') ||
        text.contains('23514')) {
      return RemoteErrorCodes.validationError;
    }
    if (text.contains('jwt') || text.contains('auth')) {
      return RemoteErrorCodes.authMissing;
    }
    return RemoteErrorCodes.unknownRemoteError;
  }
}
