import 'dart:async';

import '../../app/tenant_context.dart';
import '../../core/result/app_result.dart';
import '../../domain/app_models.dart';
import '../local/app_snapshot_local_data_source.dart';
import '../local/database/app_database.dart';
import '../local/database/drift_snapshot_store.dart';
import '../local/migration/app_snapshot_to_drift_migration.dart';
import '../sync/sync_outbox_service.dart';

class AppRepository {
  AppRepository(
    this._localDataSource, {
    DriftSnapshotStore? driftStore,
    AppSnapshotToDriftMigration? driftMigration,
    TenantContext? tenantContext,
    SyncOutboxService? syncOutboxService,
  }) : _tenantContext = tenantContext ?? const TenantContext(),
       _driftStore = driftStore,
       _driftMigration = driftMigration,
       _syncOutboxService = syncOutboxService;

  AppSnapshotLocalDataSource _localDataSource;
  final TenantContext _tenantContext;
  DriftSnapshotStore? _driftStore;
  AppSnapshotToDriftMigration? _driftMigration;
  SyncOutboxService? _syncOutboxService;
  Future<void>? _pendingDriftWrite;
  AppResult<void> _lastMutationResult = const AppSuccess(null);
  AppSnapshot? _snapshot;
  DateTime? lastSavedAt;
  String storageStatus = 'Sauvegarde locale prête';

  AppDatabase? get database => _driftStore?.database;

  bool get isDriftBacked => _driftStore != null;

  String get tenantId => _tenantContext.selectedTenantId;

  AppSnapshot get snapshot {
    final current = _snapshot;
    if (current == null) {
      throw StateError('AppRepository.load() doit être appelé avant snapshot.');
    }
    return current;
  }

  void configureLocalDataSource(AppSnapshotLocalDataSource localDataSource) {
    _localDataSource = localDataSource;
  }

  void configureDrift({
    required DriftSnapshotStore driftStore,
    required AppSnapshotToDriftMigration migration,
  }) {
    _driftStore = driftStore;
    _driftMigration = migration;
  }

  void configureSyncOutbox(SyncOutboxService syncOutboxService) {
    _syncOutboxService = syncOutboxService;
  }

  AppSnapshotLoadResult load() {
    final result = _localDataSource.load();
    _snapshot = result.snapshot;
    storageStatus = result.status;
    lastSavedAt = result.savedAt;
    if (result.recoveredFromFallback) {
      save(result.snapshot, status: 'Copie de secours restaurée et sécurisée.');
    }
    return result;
  }

  Future<AppSnapshotLoadResult> loadAsync() async {
    final driftStore = _driftStore;
    if (driftStore == null) return load();

    try {
      await _driftMigration?.migrateIfNeeded();
      final driftSnapshot = await driftStore.loadSnapshot();
      if (driftSnapshot != null) {
        return _loadedFromDrift(driftSnapshot);
      }
      final seedSnapshot = _localDataSource.fallbackSnapshot;
      await driftStore.replaceSnapshot(seedSnapshot);
      return _loadedFromDrift(seedSnapshot);
    } catch (error) {
      final legacyResult = load();
      storageStatus =
          'SQLite local indisponible; données restaurées depuis la sauvegarde JSON.';
      return AppSnapshotLoadResult(
        snapshot: legacyResult.snapshot,
        status: storageStatus,
        loadedFromStorage: legacyResult.loadedFromStorage,
        recoveredFromFallback: legacyResult.recoveredFromFallback,
        savedAt: legacyResult.savedAt,
      );
    }
  }

  void setSnapshot(AppSnapshot snapshot, {String? status, DateTime? savedAt}) {
    _snapshot = snapshot;
    if (status != null) storageStatus = status;
    lastSavedAt = savedAt ?? lastSavedAt;
  }

  AppSnapshot cacheSnapshot(AppSnapshot snapshot, {required String status}) {
    _snapshot = snapshot;
    storageStatus = status;
    lastSavedAt = DateTime.now();
    return snapshot;
  }

  AppSnapshot commitDaoMutation(
    AppSnapshot snapshot, {
    required String status,
    required Future<void> Function(AppDatabase database) write,
  }) {
    final previousSnapshot = _snapshot;
    cacheSnapshot(snapshot, status: status);
    final database = this.database;
    if (database == null) {
      _localDataSource.save(snapshot);
      _lastMutationResult = const AppSuccess(null);
    } else {
      _queueDriftMutation(
        database,
        write,
        previousSnapshot: previousSnapshot,
        nextSnapshot: snapshot,
      );
    }
    return snapshot;
  }

  AppSnapshot save(AppSnapshot snapshot, {required String status}) {
    _snapshot = snapshot;
    storageStatus = status;
    lastSavedAt = DateTime.now();
    final driftStore = _driftStore;
    if (driftStore == null) {
      _localDataSource.save(snapshot);
      _lastMutationResult = const AppSuccess(null);
    } else {
      _queueDriftWrite(driftStore, snapshot);
    }
    return snapshot;
  }

  AppSnapshot update(
    AppSnapshot Function(AppSnapshot snapshot) update, {
    required String status,
  }) {
    final updated = update(snapshot);
    save(updated, status: status);
    return updated;
  }

  AppSnapshot replace(AppSnapshot snapshot, {required String status}) {
    return save(snapshot, status: status);
  }

  Future<void> repairSync() async {
    final syncOutboxService = _syncOutboxService;
    final currentSnapshot = _snapshot;
    if (syncOutboxService != null && currentSnapshot != null) {
      await syncOutboxService.repairSync(currentSnapshot);
    }
  }

  Future<void> flushPendingWrites() async {
    await _pendingDriftWrite;
  }

  Future<AppResult<void>> flushPendingMutationResult() async {
    await _pendingDriftWrite;
    return _lastMutationResult;
  }

  AppSnapshotLoadResult _loadedFromDrift(AppSnapshot snapshot) {
    _snapshot = snapshot;
    storageStatus = 'Données restaurées depuis SQLite local.';
    lastSavedAt = DateTime.now();
    return AppSnapshotLoadResult(
      snapshot: snapshot,
      status: storageStatus,
      loadedFromStorage: true,
      recoveredFromFallback: false,
      savedAt: lastSavedAt,
    );
  }

  void _queueDriftWrite(DriftSnapshotStore driftStore, AppSnapshot snapshot) {
    final previousWrite = _pendingDriftWrite ?? Future<void>.value();
    final write = previousWrite.catchError((_) {}).then((_) async {
      try {
        await driftStore.replaceSnapshot(snapshot);
        _lastMutationResult = const AppSuccess(null);
      } catch (_) {
        _localDataSource.save(snapshot);
        storageStatus = 'SQLite indisponible; sauvegarde JSON locale utilisée.';
        _lastMutationResult = const AppFailure(
          AppError(
            code: 'drift_write_failed',
            message:
                'SQLite local est indisponible; sauvegarde JSON locale utilisée.',
          ),
        );
      }
    });
    _pendingDriftWrite = write;
    unawaited(write);
  }

  void _queueDriftMutation(
    AppDatabase database,
    Future<void> Function(AppDatabase database) write, {
    required AppSnapshot? previousSnapshot,
    required AppSnapshot nextSnapshot,
  }) {
    final previousWrite = _pendingDriftWrite ?? Future<void>.value();
    final writeFuture = previousWrite.catchError((_) {}).then((_) async {
      try {
        await write(database);
        final syncOutboxService = _syncOutboxService;
        if (syncOutboxService != null && previousSnapshot != null) {
          await syncOutboxService.enqueueSnapshotDiff(
            previous: previousSnapshot,
            next: nextSnapshot,
          );
        }
        _lastMutationResult = const AppSuccess(null);
      } catch (_) {
        final current = _snapshot;
        if (current != null) {
          _localDataSource.save(current);
        }
        storageStatus = 'SQLite indisponible; sauvegarde JSON locale utilisée.';
        _lastMutationResult = const AppFailure(
          AppError(
            code: 'drift_mutation_failed',
            message:
                'SQLite local est indisponible; sauvegarde JSON locale utilisée.',
          ),
        );
      }
    });
    _pendingDriftWrite = writeFuture;
    unawaited(writeFuture);
  }
}
