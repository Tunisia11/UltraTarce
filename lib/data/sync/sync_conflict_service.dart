import 'dart:convert';
import 'package:ultra_trace/data/sync/local_cloud_import_service.dart';
import 'package:ultra_trace/data/sync/remote_pull_repository.dart';
import 'package:ultra_trace/data/sync/sync_conflict_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';

class SyncConflictService {
  SyncConflictService({
    required this.conflictRepository,
    required this.outboxRepository,
    required this.importService,
  });

  final SyncConflictRepository conflictRepository;
  final SyncOutboxRepository outboxRepository;
  final LocalCloudImportService importService;

  Future<void> resolveKeepLocal(String conflictId) async {
    final conflict = await conflictRepository.getById(conflictId);
    if (conflict == null) return;

    // 1. Mark conflict resolved
    await conflictRepository.markAsResolved(
      conflictId,
      resolution: 'keep_local',
    );

    // 2. Re-queue outbox mutation as pending so it can push again
    await outboxRepository.markStatusByEntity(
      tenantId: conflict.tenantId,
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      status: 'pending',
    );
  }

  Future<void> resolveKeepCloud(String conflictId) async {
    final conflict = await conflictRepository.getById(conflictId);
    if (conflict == null) return;

    final remoteJson = conflict.remotePayloadJson;
    if (remoteJson == null) return;

    final data = jsonDecode(remoteJson) as Map<String, dynamic>;

    // 1. Apply remote data through import path (does not create outbox entry)
    await _applyRemoteData(conflict.tenantId, conflict.entityType, data);

    // 2. Mark outbox mutation as synced (cancels the pending local change)
    await outboxRepository.markStatusByEntity(
      tenantId: conflict.tenantId,
      entityType: conflict.entityType,
      entityId: conflict.entityId,
      status: 'synced',
    );

    // 3. Mark conflict resolved
    await conflictRepository.markAsResolved(
      conflictId,
      resolution: 'keep_cloud',
    );
  }

  Future<void> ignoreConflict(String conflictId) async {
    await conflictRepository.markAsIgnored(conflictId);
  }

  Future<void> _applyRemoteData(
    String tenantId,
    String entityType,
    Map<String, dynamic> data,
  ) async {
    final database = importService.database;

    switch (entityType) {
      case 'warehouses':
        final w = RemoteWarehouse.fromRow(data);
        await database.warehouseDao.upsertWarehouse(
          importService.warehouseToCompanion(w, tenantId),
        );
      case 'categories':
        final c = RemoteCategory.fromRow(data);
        await database.categoryDao.upsertCategory(
          importService.categoryToCompanion(c, tenantId),
        );
      case 'products':
        final p = RemoteProduct.fromRow(data);
        await database.productDao.upsertProduct(
          importService.productToCompanion(p, tenantId),
        );
      case 'partners':
        final p = RemotePartner.fromRow(data);
        await database.partnerDao.upsertPartner(
          importService.partnerToCompanion(p, tenantId),
        );
      case 'documents':
        final d = RemoteDocument.fromRow(data);
        await database.documentDao.upsertDocumentRow(
          importService.documentToCompanion(d, tenantId),
        );
      default:
        // Unknown type or types we don't handle resolution for yet (movements, etc)
        // Movements are usually consequences of docs, so resolving doc is enough
        break;
    }
  }
}
