import 'dart:async';

import 'package:drift/drift.dart';

import '../../app/tenant_context.dart';
import '../local/database/app_database.dart';

class SyncOutboxMutation {
  const SyncOutboxMutation({
    required this.id,
    required this.tenantId,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payloadJson,
    required this.createdAt,
    required this.updatedAt,
    required this.attempts,
    required this.status,
    required this.deviceId,
    required this.idempotencyKey,
    this.lastError,
    this.userId,
  });

  final String id;
  final String tenantId;
  final String entityType;
  final String entityId;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attempts;
  final String? lastError;
  final String status;
  final String deviceId;
  final String? userId;
  final String idempotencyKey;
}

class SyncOutboxSummary {
  const SyncOutboxSummary({
    required this.pendingCount,
    required this.processingCount,
    required this.failedCount,
    this.lastSyncedAt,
    this.lastError,
  });

  final int pendingCount;
  final int processingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
  final String? lastError;

  static const empty = SyncOutboxSummary(
    pendingCount: 0,
    processingCount: 0,
    failedCount: 0,
  );

  factory SyncOutboxSummary.fromRows(List<SyncOutboxMutation> rows) {
    var pending = 0;
    var processing = 0;
    var failed = 0;
    DateTime? lastSynced;
    String? lastError;
    DateTime? lastFailure;
    for (final row in rows) {
      switch (row.status) {
        case 'pending':
          pending++;
        case 'processing':
          processing++;
        case 'failed':
          failed++;
          if (lastFailure == null || row.updatedAt.isAfter(lastFailure)) {
            lastFailure = row.updatedAt;
            lastError = row.lastError;
          }
        case 'synced':
          if (lastSynced == null || row.updatedAt.isAfter(lastSynced)) {
            lastSynced = row.updatedAt;
          }
      }
    }
    return SyncOutboxSummary(
      pendingCount: pending,
      processingCount: processing,
      failedCount: failed,
      lastSyncedAt: lastSynced,
      lastError: lastError,
    );
  }
}

class SyncOutboxRepository {
  SyncOutboxRepository(this._database);

  final AppDatabase _database;
  final _changes = StreamController<void>.broadcast();
  Stream<void> watchChanges() => _changes.stream;

  Future<void> transaction(Future<void> Function() action) {
    return _database.transaction(action);
  }

  Future<void> enqueue(SyncOutboxMutation mutation) async {
    await _database.customStatement(
      '''
      INSERT OR REPLACE INTO sync_outbox (
        id,
        tenant_id,
        entity_type,
        entity_id,
        operation,
        payload_json,
        created_at,
        updated_at,
        attempts,
        last_error,
        status,
        device_id,
        user_id,
        idempotency_key
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        mutation.id,
        mutation.tenantId,
        mutation.entityType,
        mutation.entityId,
        mutation.operation,
        mutation.payloadJson,
        mutation.createdAt.toUtc().toIso8601String(),
        mutation.updatedAt.toUtc().toIso8601String(),
        mutation.attempts,
        mutation.lastError,
        mutation.status,
        mutation.deviceId,
        mutation.userId,
        mutation.idempotencyKey,
      ],
    );
    _changes.add(null);
  }

  Future<List<SyncOutboxMutation>> listPending({
    required String tenantId,
    int limit = 100,
  }) async {
    return listByStatuses(
      tenantId: tenantId,
      statuses: const ['pending', 'failed'],
      limit: limit,
    );
  }

  Future<List<SyncOutboxMutation>> listFailed({
    required String tenantId,
    int limit = 20,
  }) async {
    return listByStatuses(
      tenantId: tenantId,
      statuses: const ['failed'],
      limit: limit,
    );
  }

  Future<List<SyncOutboxMutation>> listByStatuses({
    required String tenantId,
    required List<String> statuses,
    int limit = 100,
  }) async {
    if (statuses.isEmpty) return const [];
    final placeholders = List.filled(statuses.length, '?').join(', ');
    final rows = await _database
        .customSelect(
          '''
          SELECT *
          FROM sync_outbox
          WHERE tenant_id = ?
            AND status IN ($placeholders)
          ORDER BY created_at ASC
          LIMIT ?
          ''',
          variables: [
            Variable.withString(tenantId),
            for (final status in statuses) Variable.withString(status),
            Variable.withInt(limit),
          ],
        )
        .get();
    return rows.map(_mutationFromRow).toList();
  }

  Future<SyncOutboxMutation?> findLatestMutation(
    String tenantId,
    String entityType,
    String entityId,
  ) async {
    final rows = await _database
        .customSelect(
          '''
          SELECT *
          FROM sync_outbox
          WHERE tenant_id = ?
            AND entity_type = ?
            AND entity_id = ?
          ORDER BY updated_at DESC
          LIMIT 1
          ''',
          variables: [
            Variable.withString(tenantId),
            Variable.withString(entityType),
            Variable.withString(entityId),
          ],
        )
        .get();
    if (rows.isEmpty) return null;
    return _mutationFromRow(rows.first);
  }

  Future<void> markPending(String id, {required String tenantId}) {
    return _markStatus(id, tenantId: tenantId, status: 'pending');
  }

  Future<void> markProcessing(String id, {required String tenantId}) {
    return _markStatus(id, tenantId: tenantId, status: 'processing');
  }

  Future<void> markSynced(String id, {required String tenantId}) {
    return _markStatus(id, tenantId: tenantId, status: 'synced');
  }

  Future<void> markFailed(
    String id, {
    required String tenantId,
    required String error,
  }) async {
    await _database.customStatement(
      '''
      UPDATE sync_outbox
      SET status = 'failed',
          attempts = attempts + 1,
          last_error = ?,
          updated_at = ?
      WHERE id = ?
        AND tenant_id = ?
      ''',
      [error, DateTime.now().toUtc().toIso8601String(), id, tenantId],
    );
    _changes.add(null);
  }

  Future<SyncOutboxSummary> getSummary({
    String tenantId = TenantContext.legacyTenantId,
  }) async {
    final rows = await _allForTenant(tenantId);
    return SyncOutboxSummary.fromRows(rows);
  }

  Stream<SyncOutboxSummary> watchSummary({
    String tenantId = TenantContext.legacyTenantId,
  }) async* {
    yield await getSummary(tenantId: tenantId);
    yield* _changes.stream.asyncMap((_) => getSummary(tenantId: tenantId));
  }

  Future<void> clearSyncedOlderThan(
    DateTime threshold, {
    required String tenantId,
  }) async {
    await _database.customStatement(
      '''
      DELETE FROM sync_outbox
      WHERE tenant_id = ?
        AND status = 'synced'
        AND updated_at < ?
      ''',
      [tenantId, threshold.toUtc().toIso8601String()],
    );
    _changes.add(null);
  }

  Future<void> addError({
    required String id,
    required String tenantId,
    required String message,
    String? entityType,
    String? entityId,
    String? operation,
    String? code,
    String? payloadJson,
  }) async {
    await _database.customStatement(
      '''
      INSERT OR REPLACE INTO sync_errors (
        id,
        tenant_id,
        entity_type,
        entity_id,
        operation,
        error_code,
        error_message,
        payload_json,
        created_at,
        resolved_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NULL)
      ''',
      [
        id,
        tenantId,
        entityType,
        entityId,
        operation,
        code,
        message,
        payloadJson,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<void> addConflict({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String reason,
    String? localPayload,
    String? remotePayload,
    DateTime? localUpdatedAt,
    DateTime? remoteUpdatedAt,
  }) async {
    await _database.customStatement(
      '''
      INSERT OR REPLACE INTO sync_conflicts (
        id,
        tenant_id,
        entity_type,
        entity_id,
        reason,
        local_payload_json,
        remote_payload_json,
        local_updated_at,
        remote_updated_at,
        status,
        created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'open', ?)
      ''',
      [
        '$entityType|$entityId|${DateTime.now().microsecondsSinceEpoch}',
        tenantId,
        entityType,
        entityId,
        reason,
        localPayload,
        remotePayload,
        localUpdatedAt?.toUtc().toIso8601String(),
        remoteUpdatedAt?.toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
    _changes.add(null);
  }

  Future<bool> hasPendingChanges(
    String tenantId,
    String entityType,
    String entityId,
  ) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT count(*) as count
      FROM sync_outbox
      WHERE tenant_id = ?
        AND entity_type = ?
        AND entity_id = ?
        AND status IN ('pending', 'failed', 'processing')
      ''',
          variables: [
            Variable.withString(tenantId),
            Variable.withString(entityType),
            Variable.withString(entityId),
          ],
        )
        .get();
    return (rows.first.data['count'] as num? ?? 0) > 0;
  }

  Future<void> close() async {
    await _changes.close();
  }

  Future<void> _markStatus(
    String id, {
    required String tenantId,
    required String status,
  }) async {
    await _database.customStatement(
      '''
      UPDATE sync_outbox
      SET status = ?,
          last_error = NULL,
          updated_at = ?
      WHERE id = ?
        AND tenant_id = ?
      ''',
      [status, DateTime.now().toUtc().toIso8601String(), id, tenantId],
    );
    _changes.add(null);
  }

  Future<SyncOutboxMutation?> getPendingByEntity({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT * FROM sync_outbox 
      WHERE tenant_id = ? AND entity_type = ? AND entity_id = ? 
        AND status IN ('pending', 'failed', 'processing')
      ORDER BY created_at DESC
      ''',
          variables: [
            Variable.withString(tenantId),
            Variable.withString(entityType),
            Variable.withString(entityId),
          ],
        )
        .get();
    if (rows.isEmpty) return null;
    return _mutationFromRow(rows.first);
  }

  Future<void> markStatusByEntity({
    required String tenantId,
    required String entityType,
    required String entityId,
    required String status,
  }) async {
    await _database.customStatement(
      '''
      UPDATE sync_outbox
      SET status = ?,
          updated_at = ?
      WHERE tenant_id = ? AND entity_type = ? AND entity_id = ?
        AND status != 'synced'
      ''',
      [
        status,
        DateTime.now().toUtc().toIso8601String(),
        tenantId,
        entityType,
        entityId,
      ],
    );
    _changes.add(null);
  }

  Future<void> deletePendingByEntity({
    required String tenantId,
    required String entityType,
    required String entityId,
  }) async {
    await _database.customStatement(
      '''
      DELETE FROM sync_outbox
      WHERE tenant_id = ? AND entity_type = ? AND entity_id = ?
        AND status != 'synced'
      ''',
      [tenantId, entityType, entityId],
    );
    _changes.add(null);
  }

  Future<List<SyncOutboxMutation>> _allForTenant(String tenantId) async {
    final rows = await _database
        .customSelect(
          'SELECT * FROM sync_outbox WHERE tenant_id = ?',
          variables: [Variable.withString(tenantId)],
        )
        .get();
    return rows.map(_mutationFromRow).toList();
  }

  SyncOutboxMutation _mutationFromRow(QueryRow row) {
    final data = row.data;
    return SyncOutboxMutation(
      id: data['id'] as String,
      tenantId: data['tenant_id'] as String,
      entityType: data['entity_type'] as String,
      entityId: data['entity_id'] as String,
      operation: data['operation'] as String,
      payloadJson: data['payload_json'] as String,
      createdAt: _dateFrom(data['created_at']),
      updatedAt: _dateFrom(data['updated_at']),
      attempts: (data['attempts'] as num?)?.toInt() ?? 0,
      lastError: data['last_error'] as String?,
      status: data['status'] as String,
      deviceId: data['device_id'] as String,
      userId: data['user_id'] as String?,
      idempotencyKey: data['idempotency_key'] as String,
    );
  }

  DateTime _dateFrom(Object? value) {
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse('$value') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
