import 'dart:convert';

import '../../app/tenant_context.dart';
import '../../domain/app_enums.dart';
import '../../domain/app_models.dart';
import 'device_identity_service.dart';
import 'sync_outbox_repository.dart';

class SyncOutboxService {
  SyncOutboxService({
    required SyncOutboxRepository repository,
    required DeviceIdentityService deviceIdentityService,
    required TenantContext tenantContext,
  }) : _repository = repository,
       _deviceIdentityService = deviceIdentityService,
       _tenantContext = tenantContext;

  final SyncOutboxRepository _repository;
  final DeviceIdentityService _deviceIdentityService;
  final TenantContext _tenantContext;

  Future<void> enqueueMutation({
    required String entityType,
    required String entityId,
    required String operation,
    required Map<String, dynamic> payload,
    DateTime? updatedAt,
  }) async {
    final now = DateTime.now();
    final effectiveUpdatedAt = updatedAt ?? now;
    final tenantId = _tenantContext.selectedTenantId;
    final device = _deviceIdentityService.resolve();
    final idempotencyKey = [
      tenantId,
      entityType,
      entityId,
      operation,
      effectiveUpdatedAt.toUtc().toIso8601String(),
    ].join('|');
    await _repository.enqueue(
      SyncOutboxMutation(
        id: idempotencyKey,
        tenantId: tenantId,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payloadJson: jsonEncode({
          'tenantId': tenantId,
          'entityType': entityType,
          'entityId': entityId,
          'operation': operation,
          'deviceId': device.deviceId,
          'platform': device.platform,
          'appVersion': device.appVersion,
          'payload': payload,
        }),
        createdAt: now,
        updatedAt: effectiveUpdatedAt,
        attempts: 0,
        status: 'pending',
        deviceId: device.deviceId,
        userId: _tenantContext.selectedUserId,
        idempotencyKey: idempotencyKey,
      ),
    );
  }

  Future<void> enqueueSnapshotDiff({
    required AppSnapshot previous,
    required AppSnapshot next,
  }) async {
    await _repository.transaction(() async {
      await _enqueueCompany(previous.company, next.company);
      await _enqueueListDiff<Warehouse>(
        previous: previous.warehouses,
        next: next.warehouses,
        entityType: 'warehouses',
        idOf: (warehouse) => warehouse.id,
        payloadOf: (warehouse) => warehouse.toJson(),
      );
      await _enqueueListDiff<Category>(
        previous: previous.categories,
        next: next.categories,
        entityType: 'categories',
        idOf: (category) => category.id,
        payloadOf: (category) => category.toJson(),
      );
      await _enqueueListDiff<Product>(
        previous: previous.products,
        next: next.products,
        entityType: 'products',
        idOf: (product) => product.id,
        payloadOf: (product) => product.toJson(),
      );
      await _enqueueListDiff<Partner>(
        previous: previous.partners,
        next: next.partners,
        entityType: 'partners',
        idOf: (partner) => partner.id,
        payloadOf: (partner) => partner.toJson(),
      );
      await _enqueueDocuments(previous.documents, next.documents);
      await _enqueueListDiff<StockMovement>(
        previous: previous.movements,
        next: next.movements,
        entityType: 'stock_movements',
        idOf: _stockMovementId,
        payloadOf: (movement) => movement.toJson(),
      );
      await _enqueueListDiff<AuditEvent>(
        previous: previous.auditEvents,
        next: next.auditEvents,
        entityType: 'audit_events',
        idOf: (event) => event.id,
        payloadOf: (event) => event.toJson(),
      );
      await _enqueueSequenceSetting(previous.sequences, next.sequences);

      if (previous.movements.length != next.movements.length) {
        // Enqueue 'main' warehouse (and all other existing warehouses) to ensure dependencies
        for (final warehouse in next.warehouses) {
          await enqueueMutation(
            entityType: 'warehouses',
            entityId: warehouse.id,
            operation: 'upsert',
            payload: warehouse.toJson(),
          );
        }
      }
    });
  }

  Future<void> _enqueueCompany(
    CompanyProfile previous,
    CompanyProfile next,
  ) async {
    if (_samePayload(previous.toJson(), next.toJson())) return;
    await enqueueMutation(
      entityType: 'companies',
      entityId: _tenantContext.selectedTenantId,
      operation: 'upsert',
      payload: next.toJson(),
    );
  }

  Future<void> _enqueueListDiff<T>({
    required List<T> previous,
    required List<T> next,
    required String entityType,
    required String Function(T item) idOf,
    required Map<String, dynamic> Function(T item) payloadOf,
  }) async {
    final previousById = {for (final item in previous) idOf(item): item};
    final nextById = {for (final item in next) idOf(item): item};

    for (final entry in nextById.entries) {
      final old = previousById[entry.key];
      final payload = payloadOf(entry.value);
      if (old == null) {
        await enqueueMutation(
          entityType: entityType,
          entityId: entry.key,
          operation: 'insert',
          payload: payload,
        );
      } else if (!_samePayload(payloadOf(old), payload)) {
        await enqueueMutation(
          entityType: entityType,
          entityId: entry.key,
          operation: 'upsert',
          payload: payload,
        );
      }
    }

    for (final deletedId in previousById.keys.toSet().difference(
      nextById.keys.toSet(),
    )) {
      await enqueueMutation(
        entityType: entityType,
        entityId: deletedId,
        operation: 'delete',
        payload: {'id': deletedId},
      );
    }
  }

  Future<void> _enqueueDocuments(
    List<BusinessDocument> previous,
    List<BusinessDocument> next,
  ) async {
    await _enqueueListDiff<BusinessDocument>(
      previous: previous,
      next: next,
      entityType: 'documents',
      idOf: (document) => document.id,
      payloadOf: (document) => document.toJson(),
    );

    final previousById = {
      for (final document in previous) document.id: document,
    };
    final nextById = {for (final document in next) document.id: document};

    for (final document in next) {
      final old = previousById[document.id];
      await _enqueueDocumentLines(old, document);
      await _enqueuePayments(old, document);
    }

    for (final deletedId in previousById.keys.toSet().difference(
      nextById.keys.toSet(),
    )) {
      final old = previousById[deletedId]!;
      for (var index = 0; index < old.lines.length; index++) {
        await enqueueMutation(
          entityType: 'document_lines',
          entityId: '${old.id}-$index',
          operation: 'delete',
          payload: {'id': '${old.id}-$index', 'documentId': old.id},
        );
      }
      for (final payment in old.payments) {
        await enqueueMutation(
          entityType: 'payments',
          entityId: payment.id,
          operation: 'delete',
          payload: {'id': payment.id, 'documentId': old.id},
        );
      }
    }
  }

  Future<void> _enqueueDocumentLines(
    BusinessDocument? previous,
    BusinessDocument next,
  ) async {
    final previousLines = previous?.lines ?? const <DocumentLine>[];
    final maxLength = next.lines.length > previousLines.length
        ? next.lines.length
        : previousLines.length;
    for (var index = 0; index < maxLength; index++) {
      final entityId = '${next.id}-$index';
      final old = index < previousLines.length ? previousLines[index] : null;
      final line = index < next.lines.length ? next.lines[index] : null;
      if (line == null) {
        await enqueueMutation(
          entityType: 'document_lines',
          entityId: entityId,
          operation: 'delete',
          payload: {'id': entityId, 'documentId': next.id},
        );
      } else {
        final payload = {
          ...line.toJson(),
          'id': entityId,
          'documentId': next.id,
          'position': index,
        };
        if (old == null) {
          await enqueueMutation(
            entityType: 'document_lines',
            entityId: entityId,
            operation: 'insert',
            payload: payload,
          );
        } else {
          final oldPayload = {
            ...old.toJson(),
            'id': entityId,
            'documentId': next.id,
            'position': index,
          };
          if (!_samePayload(oldPayload, payload)) {
            await enqueueMutation(
              entityType: 'document_lines',
              entityId: entityId,
              operation: 'upsert',
              payload: payload,
            );
          }
        }
      }
    }
  }

  Future<void> _enqueuePayments(
    BusinessDocument? previous,
    BusinessDocument next,
  ) async {
    final previousById = {
      for (final payment in previous?.payments ?? const <PaymentEntry>[])
        payment.id: payment,
    };
    final nextById = {for (final payment in next.payments) payment.id: payment};

    for (final entry in nextById.entries) {
      final old = previousById[entry.key];
      final payload = {...entry.value.toJson(), 'documentId': next.id};
      if (old == null) {
        await enqueueMutation(
          entityType: 'payments',
          entityId: entry.key,
          operation: 'insert',
          payload: payload,
        );
      } else {
        final oldPayload = {...old.toJson(), 'documentId': next.id};
        if (!_samePayload(oldPayload, payload)) {
          await enqueueMutation(
            entityType: 'payments',
            entityId: entry.key,
            operation: 'upsert',
            payload: payload,
          );
        }
      }
    }

    for (final deletedId in previousById.keys.toSet().difference(
      nextById.keys.toSet(),
    )) {
      await enqueueMutation(
        entityType: 'payments',
        entityId: deletedId,
        operation: 'delete',
        payload: {'id': deletedId, 'documentId': next.id},
      );
    }
  }

  Future<void> _enqueueSequenceSetting(
    Map<DocumentType, int> previous,
    Map<DocumentType, int> next,
  ) async {
    final oldPayload = previous.map(
      (type, value) => MapEntry(type.name, value),
    );
    final payload = next.map((type, value) => MapEntry(type.name, value));
    if (_samePayload(oldPayload, payload)) return;
    await enqueueMutation(
      entityType: 'settings',
      entityId: 'document_sequences',
      operation: 'upsert',
      payload: {'key': 'document_sequences', 'value': payload},
    );
  }

  bool _samePayload(Map<String, dynamic> left, Map<String, dynamic> right) {
    return jsonEncode(left) == jsonEncode(right);
  }

  String _stockMovementId(StockMovement movement) {
    return [
      movement.date.microsecondsSinceEpoch,
      movement.productId,
      movement.warehouseId,
      movement.documentNumber,
      movement.direction.name,
      movement.quantity,
      movement.serialNumbers.join(','),
    ].join(':');
  }

  Future<void> repairSync(AppSnapshot snapshot) async {
    await _repository.transaction(() async {
      await enqueueMutation(
        entityType: 'companies',
        entityId: _tenantContext.selectedTenantId,
        operation: 'upsert',
        payload: snapshot.company.toJson(),
      );
      for (final warehouse in snapshot.warehouses) {
        await enqueueMutation(
          entityType: 'warehouses',
          entityId: warehouse.id,
          operation: 'upsert',
          payload: warehouse.toJson(),
        );
      }
      for (final category in snapshot.categories) {
        await enqueueMutation(
          entityType: 'categories',
          entityId: category.id,
          operation: 'upsert',
          payload: category.toJson(),
        );
      }
      for (final product in snapshot.products) {
        await enqueueMutation(
          entityType: 'products',
          entityId: product.id,
          operation: 'upsert',
          payload: product.toJson(),
        );
      }
      for (final partner in snapshot.partners) {
        await enqueueMutation(
          entityType: 'partners',
          entityId: partner.id,
          operation: 'upsert',
          payload: partner.toJson(),
        );
      }
      for (final document in snapshot.documents) {
        await enqueueMutation(
          entityType: 'documents',
          entityId: document.id,
          operation: 'upsert',
          payload: document.toJson(),
        );
      }
    });
  }
}
