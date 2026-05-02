import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/app_enums.dart';
import '../../domain/app_models.dart';
import '../local/database/app_database.dart';
import '../local/database/tenant_row_scope.dart';
import 'local_tenant_data_status.dart';
import 'remote_pull_repository.dart';
import 'sync_conflict_models.dart';
import 'sync_outbox_repository.dart';

/// Service that handles importing cloud data into local Drift database.
/// Used for initial cloud bootstrap on fresh devices.
class LocalCloudImportService {
  LocalCloudImportService({
    required this.inspectLocal,
    required this.countPendingOutbox,
    required this.writeSnapshot,
    required this.outboxRepository,
    required this.database,
  });

  final SyncOutboxRepository outboxRepository;
  final AppDatabase database;

  /// Inspect local data rows for a given tenant.
  final Future<LocalTenantDataStatus> Function(String tenantId) inspectLocal;

  /// Count pending outbox entries for this tenant.
  final Future<int> Function(String tenantId) countPendingOutbox;

  /// Write the pull result as a snapshot into local Drift.
  /// This callback should use DriftSnapshotStore.replaceSnapshot.
  /// It must NOT enqueue sync outbox entries.
  final Future<void> Function(String tenantId, RemotePullResult pullResult)
  writeSnapshot;

  /// Full import flow:
  /// 1. Converts remote data to AppSnapshot via pullResult.toSnapshot()
  /// 2. Writes snapshot to local Drift
  /// Returns the number of rows imported.
  Future<int> importRemoteData({
    required String tenantId,
    required RemotePullResult pullResult,
  }) async {
    await writeSnapshot(tenantId, pullResult);
    return pullResult.totalRows;
  }

  /// Incremental import flow:
  /// 1. Iterates through changed rows in pullResult
  /// 2. Checks for conflicts in sync_outbox
  /// 3. Applies safe changes to local Drift
  /// 4. Records conflicts for pending local changes
  Future<ImportIncrementalResult> importIncremental({
    required String tenantId,
    required RemotePullResult pullResult,
  }) async {
    int conflicts = 0;

    await database.transaction(() async {
      // 1. Warehouses
      for (final w in pullResult.warehouses) {
        if (await outboxRepository.hasPendingChanges(
          tenantId,
          'warehouses',
          w.id,
        )) {
          conflicts++;
          await outboxRepository.addConflict(
            tenantId: tenantId,
            entityType: 'warehouses',
            entityId: w.id,
            reason: SyncConflictReason.localPendingRemoteChanged.name,
            remotePayload: 'Remote changed: ${w.name}',
          );
        } else {
          if (w.isDeleted) {
            await database.warehouseDao.deleteWarehouse(
              w.id,
              tenantId: tenantId,
            );
          } else {
            await database.warehouseDao.upsertWarehouse(
              warehouseToCompanion(w, tenantId),
            );
          }
        }
      }

      // 2. Categories
      for (final c in pullResult.categories) {
        final conflict = await _checkConflict(tenantId, 'categories', c.id);
        if (conflict != null) {
          conflicts++;
          await outboxRepository.addConflict(
            tenantId: tenantId,
            entityType: 'categories',
            entityId: c.id,
            reason: conflict.reason.name,
            localPayload: conflict.localPayload,
            remotePayload: jsonEncode(c.toJson()),
            localUpdatedAt: conflict.localUpdatedAt,
            remoteUpdatedAt: c.updatedAt,
          );
        } else {
          if (c.isDeleted) {
            await database.categoryDao.deleteCategory(c.id, tenantId: tenantId);
          } else {
            await database.categoryDao.upsertCategory(
              categoryToCompanion(c, tenantId),
            );
          }
        }
      }

      // 3. Products
      for (final p in pullResult.products) {
        final conflict = await _checkConflict(tenantId, 'products', p.id);
        if (conflict != null) {
          conflicts++;
          await outboxRepository.addConflict(
            tenantId: tenantId,
            entityType: 'products',
            entityId: p.id,
            reason: conflict.reason.name,
            localPayload: conflict.localPayload,
            remotePayload: jsonEncode(_summarizeProduct(p)),
            localUpdatedAt: conflict.localUpdatedAt,
            remoteUpdatedAt: p.updatedAt,
          );
        } else {
          if (p.isDeleted) {
            await database.productDao.deleteProduct(p.id, tenantId: tenantId);
          } else {
            await database.productDao.upsertProduct(
              productToCompanion(p, tenantId),
            );
          }
        }
      }

      // 4. Partners
      for (final p in pullResult.partners) {
        final conflict = await _checkConflict(tenantId, 'partners', p.id);
        if (conflict != null) {
          conflicts++;
          await outboxRepository.addConflict(
            tenantId: tenantId,
            entityType: 'partners',
            entityId: p.id,
            reason: conflict.reason.name,
            localPayload: conflict.localPayload,
            remotePayload: jsonEncode(p.toJson()),
            localUpdatedAt: conflict.localUpdatedAt,
            remoteUpdatedAt: p.updatedAt,
          );
        } else {
          if (p.isDeleted) {
            await database.partnerDao.deletePartner(p.id, tenantId: tenantId);
          } else {
            await database.partnerDao.upsertPartner(
              partnerToCompanion(p, tenantId),
            );
          }
        }
      }

      // 5. Documents (and Lines/Payments)
      for (final d in pullResult.documents) {
        final conflict = await _checkConflict(tenantId, 'documents', d.id);
        if (conflict != null) {
          conflicts++;
          await outboxRepository.addConflict(
            tenantId: tenantId,
            entityType: 'documents',
            entityId: d.id,
            reason: conflict.reason.name,
            localPayload: conflict.localPayload,
            remotePayload: jsonEncode(d.toJson()),
            localUpdatedAt: conflict.localUpdatedAt,
            remoteUpdatedAt: d.updatedAt,
          );
        } else {
          if (d.isDeleted) {
            await database.documentDao.deleteDocument(d.id, tenantId: tenantId);
          } else {
            await database.documentDao.upsertDocumentRow(
              documentToCompanion(d, tenantId),
            );
          }
        }
      }

      for (final l in pullResult.documentLines) {
        if (l.isDeleted) {
          // Hard delete lines for now if document exists
          await database.customStatement(
            'DELETE FROM document_lines WHERE id = ? AND tenant_id = ?',
            [l.id, tenantId],
          );
        } else {
          await database.customStatement(
            '''
            INSERT OR REPLACE INTO document_lines (
              id, tenant_id, document_id, product_id, label, sku, 
              quantity, unit_price_ht, discount, tva_rate, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            [
              l.id,
              tenantId,
              l.documentId,
              l.productId,
              l.label,
              l.sku,
              l.quantity,
              l.unitPriceHt,
              l.discount,
              l.tvaRate,
              DateTime.now().toUtc().toIso8601String(),
            ],
          );
        }
      }

      for (final p in pullResult.payments) {
        if (p.isDeleted) {
          await database.customStatement(
            'DELETE FROM payments WHERE id = ? AND tenant_id = ?',
            [p.id, tenantId],
          );
        } else {
          await database.documentDao.addPayment(
            _paymentToCompanion(p, tenantId),
          );
        }
      }

      // 6. Stock Movements
      for (final m in pullResult.stockMovements) {
        // Stock movements are usually immutable but let's be safe
        await database.stockDao.addMovement(_movementToCompanion(m, tenantId));
      }

      // 7. Audit Events
      for (final a in pullResult.auditEvents) {
        await database.auditDao.addAuditEvent(_auditToCompanion(a, tenantId));
      }

      // 8. Settings
      pullResult.settings.forEach((key, value) async {
        await database.settingsDao.setSetting(key, value, tenantId: tenantId);
      });
    });

    return ImportIncrementalResult(conflictCount: conflicts);
  }

  WarehousesCompanion warehouseToCompanion(RemoteWarehouse w, String tenantId) {
    return WarehousesCompanion(
      id: Value(TenantRowScope.rowId(tenantId, w.id)),
      tenantId: Value(tenantId),
      name: Value(w.name),
      description: Value(w.description ?? ''),
      type: Value(w.type),
      isActive: Value(w.isActive),
      updatedAt: Value(w.updatedAt ?? DateTime.now()),
    );
  }

  CategoriesCompanion categoryToCompanion(RemoteCategory c, String tenantId) {
    return CategoriesCompanion(
      id: Value(TenantRowScope.rowId(tenantId, c.id)),
      tenantId: Value(tenantId),
      name: Value(c.name),
      isActive: Value(c.isActive),
      updatedAt: Value(c.updatedAt ?? DateTime.now()),
    );
  }

  ProductsCompanion productToCompanion(RemoteProduct p, String tenantId) {
    return ProductsCompanion(
      id: Value(TenantRowScope.rowId(tenantId, p.id)),
      tenantId: Value(tenantId),
      name: Value(p.name),
      sku: Value(p.sku ?? ''),
      barcode: Value(p.barcode),
      description: Value(p.description ?? ''),
      categoryName: Value(p.categoryName ?? ''),
      brand: Value(p.brand ?? ''),
      purchasePriceHt: Value(p.purchasePriceHt),
      salePriceHt: Value(p.salePriceHt),
      tvaRate: Value(p.tvaRate.name),
      stockMinimum: Value(p.stockMinimum),
      imagePath: Value(p.imagePath ?? ''),
      isActive: Value(p.isActive),
      updatedAt: Value(p.updatedAt ?? DateTime.now()),
    );
  }

  PartnersCompanion partnerToCompanion(RemotePartner p, String tenantId) {
    return PartnersCompanion(
      id: Value(TenantRowScope.rowId(tenantId, p.id)),
      tenantId: Value(tenantId),
      type: Value(p.type == PartnerType.client ? 'client' : 'supplier'),
      name: Value(p.name),
      taxId: Value(p.taxId ?? ''),
      address: Value(p.address ?? ''),
      phone: Value(p.phone ?? ''),
      email: Value(p.email ?? ''),
      notes: Value(p.notes ?? ''),
      isActive: Value(p.isActive),
      updatedAt: Value(p.updatedAt ?? DateTime.now()),
    );
  }

  DocumentsCompanion documentToCompanion(RemoteDocument d, String tenantId) {
    final meta = d.metadata ?? {};
    return DocumentsCompanion(
      id: Value(TenantRowScope.rowId(tenantId, d.id)),
      tenantId: Value(tenantId),
      type: Value(d.type),
      status: Value(d.status),
      number: Value(d.number),
      partnerId: Value(d.partnerId ?? ''),
      issueDate: Value(d.issueDate),
      subtotalHt: Value(d.subtotalHt),
      totalTva: Value(d.totalTva),
      totalTtc: Value(d.totalTtc),
      paidAmount: Value(d.paidAmount),
      remainingAmount: Value(d.remainingAmount),
      timbreFiscal: Value(d.timbreFiscal),
      notes: Value(d.notes),
      warehouseId: Value(d.warehouseId ?? ''),
      sourceNumber: Value(d.sourceNumber),
      metadataJson: Value(meta.isEmpty ? '{}' : jsonEncode(meta)),
      updatedAt: Value(d.updatedAt ?? DateTime.now()),
    );
  }

  PaymentsCompanion _paymentToCompanion(RemotePayment p, String tenantId) {
    return PaymentsCompanion(
      id: Value(p.id),
      tenantId: Value(tenantId),
      documentId: Value(p.documentId),
      amount: Value(p.amount),
      method: Value(p.method ?? 'cash'),
      date: Value(p.date),
      reference: Value(p.reference ?? ''),
      note: Value(p.note ?? ''),
      updatedAt: Value(p.updatedAt ?? DateTime.now()),
    );
  }

  StockMovementsCompanion _movementToCompanion(
    StockMovement m,
    String tenantId,
  ) {
    final delta = m.direction == StockDirection.inbound
        ? m.quantity
        : -m.quantity;
    return StockMovementsCompanion(
      id: Value('${m.productId}|${m.date.millisecondsSinceEpoch}'),
      tenantId: Value(tenantId),
      productId: Value(m.productId),
      warehouseId: Value(m.warehouseId),
      quantityDelta: Value(delta),
      reason: Value(m.documentNumber),
      sourceDocumentId: Value(m.sourceDocumentId),
      createdAt: Value(m.date),
    );
  }

  AuditEventsCompanion _auditToCompanion(AuditEvent a, String tenantId) {
    return AuditEventsCompanion(
      id: Value(a.id),
      tenantId: Value(tenantId),
      type: Value(a.action),
      entityType: Value(a.target),
      description: Value(a.detail),
      createdAt: Value(a.date),
      metadataJson: Value(jsonEncode({'actor': a.actor})),
    );
  }

  Future<_DetectedConflict?> _checkConflict(
    String tenantId,
    String entityType,
    String entityId,
  ) async {
    final mutation = await outboxRepository.findLatestMutation(
      tenantId,
      entityType,
      entityId,
    );
    if (mutation == null) return null;

    if (mutation.status == 'pending') {
      return _DetectedConflict(
        reason: SyncConflictReason.localPendingRemoteChanged,
        localPayload: mutation.payloadJson,
        localUpdatedAt: mutation.updatedAt,
      );
    } else if (mutation.status == 'failed') {
      return _DetectedConflict(
        reason: SyncConflictReason.localFailedRemoteChanged,
        localPayload: mutation.payloadJson,
        localUpdatedAt: mutation.updatedAt,
      );
    }
    return null;
  }

  Map<String, dynamic> _summarizeProduct(RemoteProduct p) {
    final map = p.toJson();
    if (map['image_url'] != null && map['image_url'].toString().length > 1000) {
      map['image_url'] = '[image data omitted]';
    }
    return map;
  }
}

class _DetectedConflict {
  const _DetectedConflict({
    required this.reason,
    required this.localPayload,
    required this.localUpdatedAt,
  });
  final SyncConflictReason reason;
  final String localPayload;
  final DateTime localUpdatedAt;
}

class ImportIncrementalResult {
  const ImportIncrementalResult({required this.conflictCount});
  final int conflictCount;
}
