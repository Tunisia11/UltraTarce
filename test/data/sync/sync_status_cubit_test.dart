import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/sync/connectivity_service.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_service.dart';
import 'package:ultra_trace/data/sync/sync_status.dart';
import 'package:ultra_trace/data/sync/sync_status_cubit.dart';
import 'package:ultra_trace/storage/app_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('trace_sync_status_test_');
    setPersistentStorageDirectoryForTesting(tempDir.path);
  });

  tearDown(() {
    setPersistentStorageDirectoryForTesting(null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('reflects pending, failed, and offline states', () async {
    final tenantContext = const TenantContext(tenantIdOverride: 'tenant-a');
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
      payload: {'id': 'p1'},
    );
    await _waitFor(() => cubit.state is SyncPending);
    expect(cubit.state.pendingCount, 1);

    final row = (await outboxRepository.listPending(
      tenantId: 'tenant-a',
    )).single;
    await outboxRepository.markFailed(
      row.id,
      tenantId: 'tenant-a',
      error: 'remote failed',
    );
    await _waitFor(() => cubit.state is SyncFailed);
    expect(cubit.state.failedCount, 1);

    connectivity.setOnlineForTesting(false);
    await _waitFor(() => cubit.state is SyncOffline);
    expect(cubit.state.isOnline, isFalse);
  });
}

Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 50; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Condition was not reached.');
}
