import '../../app/tenant_context.dart';
import '../../core/result/app_result.dart';
import '../remote/remote_errors.dart';
import 'connectivity_service.dart';
import 'remote_sync_mapper.dart';
import 'sync_outbox_repository.dart';
import 'sync_remote_writer.dart';

class SyncPushReport {
  const SyncPushReport({
    required this.attempted,
    required this.synced,
    required this.failed,
    required this.skipped,
    this.lastError,
  });

  final int attempted;
  final int synced;
  final int failed;
  final int skipped;
  final AppError? lastError;

  bool get hasFailures => failed > 0 || lastError != null;
}

class SyncPushService {
  const SyncPushService({
    required SyncOutboxRepository outboxRepository,
    required ConnectivityService connectivityService,
    required TenantContext tenantContext,
    required SyncRemoteWriter remoteWriter,
    RemoteSyncMapper mapper = const RemoteSyncMapper(),
  }) : _outboxRepository = outboxRepository,
       _connectivityService = connectivityService,
       _tenantContext = tenantContext,
       _remoteWriter = remoteWriter,
       _mapper = mapper;

  final SyncOutboxRepository _outboxRepository;
  final ConnectivityService _connectivityService;
  final TenantContext _tenantContext;
  final SyncRemoteWriter _remoteWriter;
  final RemoteSyncMapper _mapper;

  Future<AppResult<void>> canPush() async {
    final tenantId = _tenantContext.selectedTenantId.trim();
    if (tenantId.isEmpty) {
      return const AppFailure(
        AppError(
          code: RemoteErrorCodes.missingTenantId,
          message: 'Aucune société sélectionnée pour synchroniser.',
        ),
      );
    }
    final connectivity = await _connectivityService.checkNow();
    if (!connectivity.isOnline) {
      return const AppFailure(
        AppError(
          code: RemoteErrorCodes.networkError,
          message: 'Synchronisation impossible hors ligne.',
        ),
      );
    }
    final auth = await _remoteWriter.requireAuthenticatedUserId();
    final authError = auth.errorOrNull;
    if (authError != null) return AppFailure(authError);
    return const AppSuccess(null);
  }

  Future<AppResult<SyncPushReport>> pushPending({int limit = 50}) async {
    final readiness = await canPush();
    final readinessError = readiness.errorOrNull;
    if (readinessError != null) return AppFailure(readinessError);
    return _pushByStatuses(const ['pending'], limit: limit);
  }

  Future<AppResult<SyncPushReport>> retryFailed({int limit = 50}) async {
    final readiness = await canPush();
    final readinessError = readiness.errorOrNull;
    if (readinessError != null) return AppFailure(readinessError);
    return _pushByStatuses(const ['failed'], limit: limit);
  }

  Future<AppResult<SyncPushReport>> _pushByStatuses(
    List<String> statuses, {
    required int limit,
  }) async {
    final tenantId = _tenantContext.selectedTenantId;
    final rows = await _outboxRepository.listByStatuses(
      tenantId: tenantId,
      statuses: statuses,
      limit: limit,
    );
    var synced = 0;
    var failed = 0;
    var skipped = 0;
    AppError? lastError;

    for (final row in rows) {
      final result = await pushOne(row);
      if (result.isSuccess) {
        synced++;
        continue;
      }
      final error = result.errorOrNull;
      lastError = error;
      failed++;
      if (error?.code == RemoteErrorCodes.missingTenantId ||
          error?.code == RemoteErrorCodes.authMissing ||
          error?.code == RemoteErrorCodes.networkError) {
        skipped += rows.length - synced - failed;
        break;
      }
    }

    return AppSuccess(
      SyncPushReport(
        attempted: rows.length,
        synced: synced,
        failed: failed,
        skipped: skipped,
        lastError: lastError,
      ),
    );
  }

  Future<AppResult<void>> pushOne(SyncOutboxMutation entry) async {
    final readiness = await canPush();
    final readinessError = readiness.errorOrNull;
    if (readinessError != null) return AppFailure(readinessError);

    if (entry.tenantId != _tenantContext.selectedTenantId) {
      return const AppFailure(
        AppError(
          code: RemoteErrorCodes.missingTenantId,
          message: 'Cette modification appartient à une autre société locale.',
        ),
      );
    }

    await _outboxRepository.markProcessing(entry.id, tenantId: entry.tenantId);
    final writeResult = _mapper.map(entry);
    final writeError = writeResult.errorOrNull;
    if (writeError != null) {
      await _failEntry(entry, writeError);
      return AppFailure(writeError);
    }
    final write = writeResult.valueOrNull!;

    for (final dependency in write.dependencies) {
      final exists = await _remoteWriter.rowExists(
        table: dependency.table,
        tenantId: write.tenantId,
        id: dependency.id,
      );
      final existsError = exists.errorOrNull;
      if (existsError != null) {
        await _failEntry(entry, existsError);
        return AppFailure(existsError);
      }
      if (exists.valueOrNull != true) {
        final error = AppError(
          code: RemoteErrorCodes.dependencyMissing,
          message: 'Dépendance distante manquante pour ${entry.entityType}.',
        );
        await _failEntry(entry, error);
        return AppFailure(error);
      }
    }

    final remoteResult = write.isDelete
        ? await _remoteWriter.softDelete(write)
        : await _remoteWriter.upsert(write);
    final remoteError = remoteResult.errorOrNull;
    if (remoteError != null) {
      await _failEntry(entry, remoteError);
      return AppFailure(remoteError);
    }

    await _outboxRepository.markSynced(entry.id, tenantId: entry.tenantId);
    return const AppSuccess(null);
  }

  Future<void> _failEntry(SyncOutboxMutation entry, AppError error) async {
    await _outboxRepository.markFailed(
      entry.id,
      tenantId: entry.tenantId,
      error: error.message,
    );
    await _outboxRepository.addError(
      id: '${entry.id}|${DateTime.now().microsecondsSinceEpoch}',
      tenantId: entry.tenantId,
      message: error.message,
      entityType: entry.entityType,
      entityId: entry.entityId,
      operation: entry.operation,
      code: error.code,
      payloadJson: entry.payloadJson,
    );
  }
}
