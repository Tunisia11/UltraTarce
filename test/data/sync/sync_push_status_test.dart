import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/core/result/app_result.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/remote/remote_errors.dart';
import 'package:ultra_trace/data/sync/connectivity_service.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/data/sync/remote_sync_mapper.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_service.dart';
import 'package:ultra_trace/data/sync/sync_push_service.dart';
import 'package:ultra_trace/data/sync/sync_remote_writer.dart';
import 'package:ultra_trace/data/sync/sync_status.dart';
import 'package:ultra_trace/data/sync/sync_status_cubit.dart';
import 'package:ultra_trace/storage/app_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trace_push_status_test_');
    setPersistentStorageDirectoryForTesting(tempDir.path);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('sync status updates pending, synced, and failed after push', () async {
    const tenantContext = TenantContext(tenantIdOverride: _tenantId);
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
    final connectivity = ConnectivityService();
    final remote = _StatusFakeRemoteWriter();
    final pushService = SyncPushService(
      outboxRepository: outboxRepository,
      connectivityService: connectivity,
      tenantContext: tenantContext,
      remoteWriter: remote,
    );
    final cubit = SyncStatusCubit(
      outboxRepository: outboxRepository,
      connectivityService: connectivity,
      tenantContext: tenantContext,
    )..start();
    addTearDown(cubit.close);
    addTearDown(connectivity.dispose);
    addTearDown(outboxRepository.close);
    addTearDown(database.close);

    await outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p1',
      operation: 'insert',
      payload: {'id': 'p1', 'name': 'Produit'},
    );
    await _waitFor(() => cubit.state is SyncPending);

    await pushService.pushPending();
    await _waitFor(() => cubit.state is SyncSynced);

    await outboxService.enqueueMutation(
      entityType: 'products',
      entityId: 'p2',
      operation: 'insert',
      payload: {'id': 'p2', 'name': 'Produit 2'},
    );
    remote.failure = const AppError(
      code: RemoteErrorCodes.validationError,
      message: 'invalid product',
    );
    await pushService.pushPending();
    await _waitFor(() => cubit.state is SyncFailed);
    expect(cubit.state.failedCount, 1);
  });
}

const _tenantId = '11111111-1111-4111-8111-111111111111';

class _StatusFakeRemoteWriter implements SyncRemoteWriter {
  AppError? failure;
  final existing = <String>{};

  @override
  Future<AppResult<String>> requireAuthenticatedUserId() async {
    return const AppSuccess('22222222-2222-4222-8222-222222222222');
  }

  @override
  Future<AppResult<bool>> rowExists({
    required String table,
    required String tenantId,
    required String id,
  }) async {
    return AppSuccess(existing.contains('$table|$tenantId|$id'));
  }

  @override
  Future<AppResult<void>> softDelete(RemoteSyncWrite write) async {
    final error = failure;
    if (error != null) return AppFailure(error);
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<void>> upsert(RemoteSyncWrite write) async {
    final error = failure;
    if (error != null) return AppFailure(error);
    existing.add('${write.table}|${write.tenantId}|${write.entityId}');
    return const AppSuccess(null);
  }
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 80; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not reached.');
}
