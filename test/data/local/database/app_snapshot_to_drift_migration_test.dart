import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/local/app_snapshot_local_data_source.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/local/database/drift_snapshot_store.dart';
import 'package:ultra_trace/data/local/migration/app_snapshot_to_drift_migration.dart';
import 'package:ultra_trace/storage/app_storage.dart';
import 'package:ultra_trace/storage/app_storage_keys.dart';

import '../../repositories/drift_repository_test_helpers.dart';

void main() {
  late Directory storageDirectory;
  late AppDatabase database;

  setUp(() {
    storageDirectory = Directory.systemTemp.createTempSync(
      'trace_ultra_drift_migration_test_',
    );
    setPersistentStorageDirectoryForTesting(storageDirectory.path);
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    setPersistentStorageDirectoryForTesting(null);
    await database.close();
    if (storageDirectory.existsSync()) {
      storageDirectory.deleteSync(recursive: true);
    }
  });

  test('legacy AppSnapshot migrates into Drift idempotently', () async {
    final snapshot = testSnapshot(
      products: [testProduct()],
      partners: [testPartner()],
      documents: [testDocument()],
    );
    writePersistentValue(appStateStorageKey, jsonEncode(snapshot.toJson()));

    final dataSource = AppSnapshotLocalDataSource(fallbackSnapshot: snapshot);
    final store = DriftSnapshotStore(database);
    final migration = AppSnapshotToDriftMigration(
      database: database,
      legacyDataSource: dataSource,
      driftStore: store,
    );

    await migration.migrateIfNeeded();
    await migration.migrateIfNeeded();

    final restored = await store.loadSnapshot();
    expect(restored, isNotNull);
    expect(restored!.products, hasLength(1));
    expect(restored.documents, hasLength(1));
    expect(
      await database.settingsDao.getGlobalSetting(
        DriftSnapshotStore.legacyMigrationSettingKey,
      ),
      'true',
    );
  });
}
