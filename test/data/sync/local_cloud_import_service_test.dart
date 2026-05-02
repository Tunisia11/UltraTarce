import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/sync/local_cloud_import_service.dart';
import 'package:ultra_trace/data/sync/local_tenant_data_status.dart';
import 'package:ultra_trace/data/sync/remote_pull_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';

void main() {
  late AppDatabase database;
  late SyncOutboxRepository outboxRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    outboxRepository = SyncOutboxRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('LocalCloudImportService', () {
    test('inspectLocal triggers callback', () async {
      final service = LocalCloudImportService(
        database: database,
        outboxRepository: outboxRepository,
        inspectLocal: (tenantId) async =>
            const LocalTenantDataStatus(productCount: 5),
        countPendingOutbox: (_) async => 0,
        writeSnapshot: (_, _) async {},
      );

      final status = await service.inspectLocal('t1');
      expect(status.productCount, 5);
      expect(status.isEmpty, isFalse);
    });

    test('countPendingOutbox triggers callback', () async {
      final service = LocalCloudImportService(
        database: database,
        outboxRepository: outboxRepository,
        inspectLocal: (_) async => const LocalTenantDataStatus(),
        countPendingOutbox: (tenantId) async => 3,
        writeSnapshot: (_, _) async {},
      );

      final count = await service.countPendingOutbox('t1');
      expect(count, 3);
    });

    test('importRemoteData writes snapshot and returns row count', () async {
      var writeCalled = false;
      var passedTenantId = '';

      final service = LocalCloudImportService(
        database: database,
        outboxRepository: outboxRepository,
        inspectLocal: (_) async => const LocalTenantDataStatus(),
        countPendingOutbox: (_) async => 0,
        writeSnapshot: (tenantId, pullResult) async {
          writeCalled = true;
          passedTenantId = tenantId;
        },
      );

      const pullResult = RemotePullResult();
      final rows = await service.importRemoteData(
        tenantId: 't1',
        pullResult: pullResult,
      );

      expect(writeCalled, isTrue);
      expect(passedTenantId, 't1');
      expect(rows, 0);
    });
  });
}
