import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/core/result/app_result.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/remote/remote_errors.dart';
import 'package:ultra_trace/data/remote/remote_tables.dart';
import 'package:ultra_trace/data/sync/connectivity_service.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/data/sync/remote_sync_mapper.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_service.dart';
import 'package:ultra_trace/data/sync/sync_push_service.dart';
import 'package:ultra_trace/data/sync/sync_remote_writer.dart';
import 'package:ultra_trace/storage/app_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trace_push_test_');
    setPersistentStorageDirectoryForTesting(tempDir.path);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('successful push marks outbox row synced', () async {
    final harness = _createHarness();
    addTearDown(harness.close);

    await harness.outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit', 'saleHt': 10},
    );

    final result = await harness.pushService.pushPending();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.synced, 1);
    final summary = await harness.outboxRepository.getSummary(
      tenantId: _tenantId,
    );
    expect(summary.pendingCount, 0);
    expect(summary.lastSyncedAt, isNotNull);
    expect(harness.remote.upserts.single.table, RemoteTables.products);
  });

  test('failed push marks outbox row failed and keeps local payload', () async {
    final harness = _createHarness(
      remote: _FakeSyncRemoteWriter(
        writeFailure: const AppError(
          code: RemoteErrorCodes.rlsDenied,
          message: 'RLS denied',
        ),
      ),
    );
    addTearDown(harness.close);

    await harness.outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit'},
    );

    final result = await harness.pushService.pushPending();

    expect(result.valueOrNull!.failed, 1);
    final rows = await harness.outboxRepository.listPending(
      tenantId: _tenantId,
    );
    expect(rows.single.status, 'failed');
    expect(rows.single.payloadJson, contains('Produit'));
  });

  test('retryFailed can mark synced after success', () async {
    final remote = _FakeSyncRemoteWriter(
      writeFailure: const AppError(
        code: RemoteErrorCodes.networkError,
        message: 'network down',
      ),
    );
    final harness = _createHarness(remote: remote);
    addTearDown(harness.close);

    await harness.outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit'},
    );
    await harness.pushService.pushPending();
    remote.writeFailure = null;

    final retry = await harness.pushService.retryFailed();

    expect(retry.valueOrNull!.synced, 1);
    final summary = await harness.outboxRepository.getSummary(
      tenantId: _tenantId,
    );
    expect(summary.failedCount, 0);
  });

  test('dependency_missing leaves entry failed for retry', () async {
    final harness = _createHarness();
    addTearDown(harness.close);

    await harness.outboxService.enqueueMutation(
      entityType: 'payments',
      entityId: 'pay-1',
      operation: 'insert',
      payload: {'id': 'pay-1', 'documentId': 'doc-1', 'amount': 12},
    );

    final result = await harness.pushService.pushPending();

    expect(result.valueOrNull!.failed, 1);
    final summary = await harness.outboxRepository.getSummary(
      tenantId: _tenantId,
    );
    expect(summary.failedCount, 1);
    expect(summary.lastError, contains('Dépendance distante manquante'));
  });

  test('missing auth prevents push without changing pending row', () async {
    final harness = _createHarness(
      remote: _FakeSyncRemoteWriter(authenticated: false),
    );
    addTearDown(harness.close);

    await harness.outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit'},
    );

    final result = await harness.pushService.pushPending();

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.code, RemoteErrorCodes.authMissing);
    final summary = await harness.outboxRepository.getSummary(
      tenantId: _tenantId,
    );
    expect(summary.pendingCount, 1);
    expect(summary.failedCount, 0);
  });

  test('dev bypass without real auth does not crash', () async {
    final harness = _createHarness(
      tenantContext: const TenantContext(authBypassOverride: true),
      remote: _FakeSyncRemoteWriter(authenticated: false),
    );
    addTearDown(harness.close);

    await harness.outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit'},
    );

    final result = await harness.pushService.pushPending();

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.code, RemoteErrorCodes.authMissing);
  });

  test('pushes entries in dependency priority order', () async {
    final harness = _createHarness();
    addTearDown(harness.close);

    harness.remote.existingRows.add(
      '${RemoteTables.warehouses}|$_tenantId|${RemoteSyncMapper.remoteIdFor(_tenantId, 'warehouses', 'w1')}',
    );

    // Enqueue in reverse priority order
    await harness.outboxService.enqueueMutation(
      entityType: 'stock_movements',
      entityId: 'sm1',
      operation: 'insert',
      payload: {
        'id': 'sm1',
        'productId': 'p1',
        'warehouseId': 'w1',
        'sourceDocumentId': 'doc1',
      },
    );
    await harness.outboxService.enqueueMutation(
      entityType: 'document_lines',
      entityId: 'dl1',
      operation: 'insert',
      payload: {'id': 'dl1', 'documentId': 'doc1', 'productId': 'p1'},
    );
    await harness.outboxService.enqueueMutation(
      entityType: 'documents',
      entityId: 'doc1',
      operation: 'insert',
      payload: {'id': 'doc1'},
    );
    await harness.outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1'},
    );

    await harness.pushService.pushPending();

    expect(harness.remote.upserts.length, 4);
    expect(harness.remote.upserts[0].table, RemoteTables.products);
    expect(harness.remote.upserts[1].table, RemoteTables.documents);
    expect(harness.remote.upserts[2].table, RemoteTables.documentLines);
    expect(harness.remote.upserts[3].table, RemoteTables.stockMovements);
  });

  test('failed push stores exact remote error in sync_errors', () async {
    final harness = _createHarness(
      remote: _FakeSyncRemoteWriter(
        writeFailure: const AppError(
          code: RemoteErrorCodes.validationError,
          message: 'not-null constraint violated',
        ),
      ),
    );
    addTearDown(harness.close);

    await harness.outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit'},
    );

    await harness.pushService.pushPending();

    final errors = await harness.database
        .customSelect('SELECT * FROM sync_errors')
        .get();
    expect(errors.length, 1);
    expect(errors.first.data['error_message'], 'not-null constraint violated');
    expect(errors.first.data['entity_type'], 'products');
  });
}

const _tenantId = '11111111-1111-4111-8111-111111111111';

_PushHarness _createHarness({
  TenantContext tenantContext = const TenantContext(
    tenantIdOverride: _tenantId,
    userIdOverride: '22222222-2222-4222-8222-222222222222',
  ),
  _FakeSyncRemoteWriter? remote,
}) {
  final database = AppDatabase.forTesting(
    NativeDatabase.memory(),
    tenantContext: tenantContext,
  );
  final outboxRepository = SyncOutboxRepository(database);
  final connectivity = ConnectivityService();
  final effectiveRemote = remote ?? _FakeSyncRemoteWriter();
  return _PushHarness(
    database: database,
    outboxRepository: outboxRepository,
    connectivity: connectivity,
    remote: effectiveRemote,
    outboxService: SyncOutboxService(
      repository: outboxRepository,
      deviceIdentityService: const DeviceIdentityService(),
      tenantContext: tenantContext,
    ),
    pushService: SyncPushService(
      outboxRepository: outboxRepository,
      connectivityService: connectivity,
      tenantContext: tenantContext,
      remoteWriter: effectiveRemote,
    ),
  );
}

class _PushHarness {
  const _PushHarness({
    required this.database,
    required this.outboxRepository,
    required this.outboxService,
    required this.pushService,
    required this.connectivity,
    required this.remote,
  });

  final AppDatabase database;
  final SyncOutboxRepository outboxRepository;
  final SyncOutboxService outboxService;
  final SyncPushService pushService;
  final ConnectivityService connectivity;
  final _FakeSyncRemoteWriter remote;

  Future<void> close() async {
    await outboxRepository.close();
    await connectivity.dispose();
    await database.close();
  }
}

class _FakeSyncRemoteWriter implements SyncRemoteWriter {
  _FakeSyncRemoteWriter({this.authenticated = true, this.writeFailure});

  bool authenticated;
  AppError? writeFailure;
  final upserts = <RemoteSyncWrite>[];
  final deletes = <RemoteSyncWrite>[];
  final existingRows = <String>{};

  @override
  Future<AppResult<String>> requireAuthenticatedUserId() async {
    if (!authenticated) {
      return const AppFailure(
        AppError(code: RemoteErrorCodes.authMissing, message: 'auth missing'),
      );
    }
    return const AppSuccess('22222222-2222-4222-8222-222222222222');
  }

  @override
  Future<AppResult<bool>> rowExists({
    required String table,
    required String tenantId,
    required String id,
  }) async {
    return AppSuccess(existingRows.contains('$table|$tenantId|$id'));
  }

  @override
  Future<AppResult<void>> softDelete(RemoteSyncWrite write) async {
    final failure = writeFailure;
    if (failure != null) return AppFailure(failure);
    deletes.add(write);
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> upsert(RemoteSyncWrite write) async {
    final failure = writeFailure;
    if (failure != null) return AppFailure(failure);
    upserts.add(write);
    existingRows.add('${write.table}|${write.tenantId}|${write.entityId}');
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<Map<String, dynamic>?>> findDocumentByNumber({
    required String tenantId,
    required String type,
    required String number,
  }) async {
    return const AppSuccess<Map<String, dynamic>?>(null);
  }
}
