import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_service.dart';
import 'package:ultra_trace/storage/app_storage.dart';

import '../repositories/drift_repository_test_helpers.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trace_outbox_test_');
    setPersistentStorageDirectoryForTesting(tempDir.path);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('enqueue mutation creates pending outbox row', () async {
    final tenantContext = const TenantContext(tenantIdOverride: 'tenant-a');
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(),
      tenantContext: tenantContext,
    );
    final repository = SyncOutboxRepository(database);
    final service = SyncOutboxService(
      repository: repository,
      deviceIdentityService: const DeviceIdentityService(),
      tenantContext: tenantContext,
    );
    addTearDown(repository.close);
    addTearDown(database.close);

    await service.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit'},
    );

    final pending = await repository.listPending(tenantId: 'tenant-a');
    expect(pending, hasLength(1));
    expect(pending.single.entityType, 'products');
    expect(pending.single.status, 'pending');
    expect(jsonDecode(pending.single.payloadJson)['payload']['id'], 'p1');
  });

  test('status transitions update summary counts', () async {
    final tenantContext = const TenantContext(tenantIdOverride: 'tenant-a');
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(),
      tenantContext: tenantContext,
    );
    final repository = SyncOutboxRepository(database);
    final service = SyncOutboxService(
      repository: repository,
      deviceIdentityService: const DeviceIdentityService(),
      tenantContext: tenantContext,
    );
    addTearDown(repository.close);
    addTearDown(database.close);

    await service.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1'},
    );
    final row = (await repository.listPending(tenantId: 'tenant-a')).single;

    await repository.markFailed(row.id, tenantId: 'tenant-a', error: 'network');
    var summary = await repository.getSummary(tenantId: 'tenant-a');
    expect(summary.failedCount, 1);
    expect(summary.lastError, 'network');

    await repository.markProcessing(row.id, tenantId: 'tenant-a');
    summary = await repository.getSummary(tenantId: 'tenant-a');
    expect(summary.processingCount, 1);

    await repository.markSynced(row.id, tenantId: 'tenant-a');
    summary = await repository.getSummary(tenantId: 'tenant-a');
    expect(summary.pendingCount, 0);
    expect(summary.failedCount, 0);
    expect(summary.lastSyncedAt, isNotNull);
  });

  test(
    'snapshot diff enqueues changed product and document children',
    () async {
      final tenantContext = const TenantContext(tenantIdOverride: 'tenant-a');
      final database = AppDatabase.forTesting(
        NativeDatabase.memory(),
        tenantContext: tenantContext,
      );
      final repository = SyncOutboxRepository(database);
      final service = SyncOutboxService(
        repository: repository,
        deviceIdentityService: const DeviceIdentityService(),
        tenantContext: tenantContext,
      );
      addTearDown(repository.close);
      addTearDown(database.close);

      final product = testProduct(id: 'p1');
      final document = testDocument();
      await service.enqueueSnapshotDiff(
        previous: testSnapshot(products: [product]),
        next: testSnapshot(
          products: [product.copyWith(name: 'Modifié')],
          documents: [document],
        ),
      );

      final rows = await repository.listPending(
        tenantId: 'tenant-a',
        limit: 20,
      );
      expect(rows.map((row) => row.entityType), contains('products'));
      expect(rows.map((row) => row.entityType), contains('documents'));
      expect(rows.map((row) => row.entityType), contains('document_lines'));
    },
  );
}
