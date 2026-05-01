import '../app_snapshot_local_data_source.dart';
import '../database/app_database.dart';
import '../database/drift_snapshot_store.dart';

class AppSnapshotToDriftMigration {
  AppSnapshotToDriftMigration({
    required this.database,
    required this.legacyDataSource,
    required this.driftStore,
  });

  final AppDatabase database;
  final AppSnapshotLocalDataSource legacyDataSource;
  final DriftSnapshotStore driftStore;

  Future<void> migrateIfNeeded() async {
    final migrated = await database.settingsDao.getGlobalSetting(
      DriftSnapshotStore.legacyMigrationSettingKey,
    );
    if (migrated == 'true') return;

    if (!await driftStore.isEmpty()) {
      await database.settingsDao.setGlobalSetting(
        DriftSnapshotStore.legacyMigrationSettingKey,
        'true',
      );
      return;
    }

    final legacyResult = legacyDataSource.load();
    await driftStore.replaceSnapshot(legacyResult.snapshot);
    await database.settingsDao.setGlobalSetting(
      DriftSnapshotStore.legacyMigrationSettingKey,
      'true',
    );
  }
}
