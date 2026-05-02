import 'package:flutter/foundation.dart';

import '../../app/tenant_context.dart';
import '../../core/result/app_result.dart';
import '../remote/remote_errors.dart';
import '../remote/remote_tables.dart';
import 'connectivity_service.dart';
import 'remote_sync_mapper.dart';
import 'sync_outbox_repository.dart';
import 'sync_remote_writer.dart';
import 'sync_metadata_repository.dart';
import 'sync_conflict_models.dart';
import 'dart:convert';

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
  SyncPushService({
    required SyncOutboxRepository outboxRepository,
    required ConnectivityService connectivityService,
    required TenantContext tenantContext,
    required SyncRemoteWriter remoteWriter,
    required SyncMetadataRepository metadataRepository,
    RemoteSyncMapper mapper = const RemoteSyncMapper(),
  }) : _outboxRepository = outboxRepository,
       _connectivityService = connectivityService,
       _tenantContext = tenantContext,
       _remoteWriter = remoteWriter,
       _metadataRepository = metadataRepository,
       _mapper = mapper;

  final SyncOutboxRepository _outboxRepository;
  final ConnectivityService _connectivityService;
  final TenantContext _tenantContext;
  final SyncRemoteWriter _remoteWriter;
  final SyncMetadataRepository _metadataRepository;
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
    final rawRows = await _outboxRepository.listByStatuses(
      tenantId: tenantId,
      statuses: statuses,
      limit: limit,
    );
    final rows = [...rawRows]
      ..sort((a, b) {
        final byPriority = _entityPriority(
          a.entityType,
        ).compareTo(_entityPriority(b.entityType));
        if (byPriority != 0) return byPriority;
        return a.createdAt.compareTo(b.createdAt);
      });
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
    var write = writeResult.valueOrNull!;

    if (write.table == RemoteTables.documents && !write.isDelete) {
      final number = write.payload['number'] as String?;
      final type = write.payload['type'] as String?;
      if (number != null && number.isNotEmpty && type != null) {
        final existing = await _remoteWriter.findDocumentByNumber(
          tenantId: write.tenantId,
          type: type,
          number: number,
        );
        final existingError = existing.errorOrNull;
        if (existingError != null) {
          await _failEntry(entry, existingError);
          return AppFailure(existingError);
        }
        final existingDoc = existing.valueOrNull;
        if (existingDoc != null && existingDoc['id'] != write.entityId) {
          final existingDeviceId = existingDoc['sync_origin_device_id'];
          final localDeviceId = write.payload['sync_origin_device_id'];

          if (existingDeviceId == localDeviceId) {
            // It's the same device, maybe local db was wiped but document was restored, map to existing ID
            write = RemoteSyncWrite(
              table: write.table,
              tenantId: write.tenantId,
              entityId: existingDoc['id'] as String,
              operation: write.operation,
              payload: {...write.payload, 'id': existingDoc['id']},
              dependencies: write.dependencies,
              deletedAt: write.deletedAt,
            );
          } else {
            // Conflict from another device. Add a suffix to number.
            final suffix =
                '-DUP-${DateTime.now().millisecondsSinceEpoch.toRadixString(16).toUpperCase().substring(4)}';
            final newNumber = '$number$suffix';
            write = RemoteSyncWrite(
              table: write.table,
              tenantId: write.tenantId,
              entityId: write.entityId,
              operation: write.operation,
              payload: {...write.payload, 'number': newNumber},
              dependencies: write.dependencies,
              deletedAt: write.deletedAt,
            );
          }
        }
      }
    }

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
        if (dependency.localId.isNotEmpty) {
          final parentMutation = await _outboxRepository.findLatestMutation(
            write.tenantId,
            dependency.localEntityType,
            dependency.localId,
          );
          if (parentMutation != null) {
            debugPrint(
              '[sync] Attempting to repair missing dependency ${dependency.localEntityType}/${dependency.localId} for ${entry.entityType}/${entry.entityId}',
            );
            if (parentMutation.status == 'failed') {
              await _outboxRepository.markPending(
                parentMutation.id,
                tenantId: write.tenantId,
              );
            }
            final parentResult = await pushOne(parentMutation);
            if (parentResult.isSuccess) {
              debugPrint(
                '[sync] Successfully repaired missing dependency ${dependency.localEntityType}/${dependency.localId}. Continuing with ${entry.entityType}/${entry.entityId}.',
              );
              continue; // Parent pushed, dependency should exist now!
            }
          } else if (dependency.localEntityType == 'warehouses' &&
              entry.entityType == 'stock_movements') {
            final error = AppError(
              code: RemoteErrorCodes.dependencyMissing,
              message: 'Dépôt introuvable pour ce mouvement de stock.',
            );
            await _failEntry(entry, error);
            return AppFailure(error);
          }
        }

        final error = AppError(
          code: RemoteErrorCodes.dependencyMissing,
          message: 'Dépendance distante manquante pour ${entry.entityType}.',
        );
        await _failEntry(entry, error);
        return AppFailure(error);
      }
    }

    // Phase 9C: Version check before upsert
    if (!write.isDelete) {
      final remoteRowResult = await _remoteWriter.fetchRow(
        table: write.table,
        tenantId: write.tenantId,
        id: write.entityId,
      );
      final remoteRow = remoteRowResult.valueOrNull;
      if (remoteRow != null) {
        final remoteUpdatedAt = DateTime.tryParse(
          remoteRow['updated_at']?.toString() ?? '',
        );
        if (remoteUpdatedAt != null) {
          final lastPullAt = await _metadataRepository.getLastPullCompletedAt(
            write.tenantId,
          );
          if (lastPullAt != null && remoteUpdatedAt.isAfter(lastPullAt)) {
            // Conflict! Remote changed after we last pulled.
            final error = AppError(
              code: 'conflict_detected',
              message: 'Conflit détecté. Les données locales sont conservées.',
            );
            await _outboxRepository.markFailed(
              entry.id,
              tenantId: entry.tenantId,
              error: error.message,
            );
            await _outboxRepository.addConflict(
              tenantId: entry.tenantId,
              entityType: entry.entityType,
              entityId: entry.entityId,
              reason: SyncConflictReason.versionMismatch.name,
              localPayload: entry.payloadJson,
              remotePayload: jsonEncode(remoteRow),
              localUpdatedAt: entry.updatedAt,
              remoteUpdatedAt: remoteUpdatedAt,
            );
            return AppFailure(error);
          }
        }
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
    debugPrint(
      '[sync] ${entry.entityType}/${entry.entityId} failed: ${error.code} ${error.message} cause=${error.cause}',
    );
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

  int _entityPriority(String entityType) {
    return switch (entityType) {
      'companies' => 0,
      'warehouses' => 1,
      'categories' => 2,
      'products' => 3,
      'partners' => 4,
      'documents' => 5,
      'document_lines' => 6,
      'payments' => 7,
      'stock_movements' => 8,
      'settings' => 9,
      'audit_events' => 10,
      _ => 99,
    };
  }
}
