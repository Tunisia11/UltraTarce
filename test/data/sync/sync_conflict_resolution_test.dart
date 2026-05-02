import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/local/database/tenant_row_scope.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/data/sync/local_cloud_import_service.dart';
import 'package:ultra_trace/data/sync/sync_conflict_models.dart';
import 'package:ultra_trace/data/sync/sync_conflict_repository.dart';
import 'package:ultra_trace/data/sync/sync_conflict_service.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_service.dart';
import 'package:ultra_trace/storage/app_storage.dart';

void main() {
  late Directory tempDir;
  const tenantId = '11111111-1111-4111-8111-111111111111';
  const tenantContext = TenantContext(tenantIdOverride: tenantId);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trace_conflict_res_test_');
    setPersistentStorageDirectoryForTesting(tempDir.path);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('keep local marks conflict resolved and requeues mutation', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(),
      tenantContext: tenantContext,
    );
    final outboxRepository = SyncOutboxRepository(database);
    final outboxService = SyncOutboxService(
      repository: outboxRepository,
      deviceIdentityService: const DeviceIdentityService(),
      tenantContext: tenantContext,
    );
    final conflictRepository = SyncConflictRepository(database);
    final importService = LocalCloudImportService(
      database: database,
      outboxRepository: outboxRepository,
      inspectLocal: (_) async => throw UnimplementedError(),
      countPendingOutbox: (_) async => 0,
      writeSnapshot: (_, result) async {},
    );
    final conflictService = SyncConflictService(
      conflictRepository: conflictRepository,
      outboxRepository: outboxRepository,
      importService: importService,
    );

    final p1Scoped = TenantRowScope.rowId(tenantId, 'p1');

    // 1. Setup a conflict and a mutation
    await outboxService.enqueueMutation(
      entityType: 'products',
      entityId: p1Scoped,
      operation: 'update',
      payload: {'id': p1Scoped, 'name': 'Local Name'},
    );

    // Mark it failed
    await outboxRepository.markStatusByEntity(
      tenantId: tenantId,
      entityType: 'products',
      entityId: p1Scoped,
      status: 'failed',
    );

    await outboxRepository.addConflict(
      tenantId: tenantId,
      entityType: 'products',
      entityId: p1Scoped,
      reason: SyncConflictReason.versionMismatch.name,
      localPayload: jsonEncode({'id': p1Scoped, 'name': 'Local Name'}),
      remotePayload: jsonEncode({'id': p1Scoped, 'name': 'Remote Name'}),
    );

    final conflicts = await conflictRepository.getOpenConflicts(
      tenantId: tenantId,
    );
    expect(conflicts.length, 1);
    final conflictId = conflicts.first.id;

    // 2. Resolve Keep Local
    await conflictService.resolveKeepLocal(conflictId);

    // 3. Verify
    final updatedConflicts = await conflictRepository.getOpenConflicts(
      tenantId: tenantId,
    );
    expect(updatedConflicts.isEmpty, true);

    final updatedMutation = await outboxRepository.getPendingByEntity(
      tenantId: tenantId,
      entityType: 'products',
      entityId: p1Scoped,
    );
    expect(updatedMutation?.status, 'pending');

    await database.close();
  });

  test('keep cloud applies remote payload and cancels mutation', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(),
      tenantContext: tenantContext,
    );
    final outboxRepository = SyncOutboxRepository(database);
    final outboxService = SyncOutboxService(
      repository: outboxRepository,
      deviceIdentityService: const DeviceIdentityService(),
      tenantContext: tenantContext,
    );
    final conflictRepository = SyncConflictRepository(database);
    final importService = LocalCloudImportService(
      database: database,
      outboxRepository: outboxRepository,
      inspectLocal: (_) async => throw UnimplementedError(),
      countPendingOutbox: (_) async => 0,
      writeSnapshot: (_, result) async {},
    );
    final conflictService = SyncConflictService(
      conflictRepository: conflictRepository,
      outboxRepository: outboxRepository,
      importService: importService,
    );

    final p1Scoped = TenantRowScope.rowId(tenantId, 'p1');

    // 1. Setup a conflict and a mutation
    await database.productDao.upsertProduct(
      ProductsCompanion.insert(
        id: p1Scoped,
        tenantId: Value(tenantId),
        name: 'Old Name',
        tvaRate: const Value('rate19'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await outboxService.enqueueMutation(
      entityType: 'products',
      entityId: p1Scoped,
      operation: 'update',
      payload: {'id': p1Scoped, 'name': 'Local Name'},
    );

    await outboxRepository.addConflict(
      tenantId: tenantId,
      entityType: 'products',
      entityId: p1Scoped,
      reason: SyncConflictReason.versionMismatch.name,
      localPayload: jsonEncode({'id': p1Scoped, 'name': 'Local Name'}),
      remotePayload: jsonEncode({
        'id': p1Scoped,
        'name': 'Remote Name',
        'sku': 'SKU123',
        'sale_price_ht': 150.0,
        'tva_rate': 'rate19',
        'stock_minimum': 5,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }),
    );

    final conflicts = await conflictRepository.getOpenConflicts(
      tenantId: tenantId,
    );
    final conflictId = conflicts.first.id;

    // 2. Resolve Keep Cloud
    await conflictService.resolveKeepCloud(conflictId);

    // 3. Verify
    final updatedConflicts = await conflictRepository.getOpenConflicts(
      tenantId: tenantId,
    );
    expect(updatedConflicts.isEmpty, true);

    // Mutation should be synced (effectively cancelled/discarded)
    final pendingMutation = await outboxRepository.getPendingByEntity(
      tenantId: tenantId,
      entityType: 'products',
      entityId: p1Scoped,
    );
    expect(
      pendingMutation,
      null,
    ); // Status is synced, so getPendingByEntity returns null

    // Local row should be updated
    final product = await database.productDao.getProductById(
      'p1',
      tenantId: tenantId,
    );
    expect(product?.name, 'Remote Name');
    expect(product?.sku, 'SKU123');

    await database.close();
  });

  test('ignore marks conflict as ignored', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(),
      tenantContext: tenantContext,
    );
    final outboxRepository = SyncOutboxRepository(database);
    final conflictRepository = SyncConflictRepository(database);
    final importService = LocalCloudImportService(
      database: database,
      outboxRepository: outboxRepository,
      inspectLocal: (_) async => throw UnimplementedError(),
      countPendingOutbox: (_) async => 0,
      writeSnapshot: (_, result) async {},
    );
    final conflictService = SyncConflictService(
      conflictRepository: conflictRepository,
      outboxRepository: outboxRepository,
      importService: importService,
    );

    await outboxRepository.addConflict(
      tenantId: tenantId,
      entityType: 'products',
      entityId: 'p1',
      reason: SyncConflictReason.localPendingRemoteChanged.name,
    );

    final conflicts = await conflictRepository.getOpenConflicts(
      tenantId: tenantId,
    );
    final conflictId = conflicts.first.id;

    await conflictService.ignoreConflict(conflictId);

    final openConflicts = await conflictRepository.getOpenConflicts(
      tenantId: tenantId,
    );
    expect(openConflicts.isEmpty, true);

    await database.close();
  });
}
