import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/tenant_context.dart';
import 'connectivity_service.dart';
import 'sync_outbox_repository.dart';
import 'sync_status.dart';
import 'sync_pull_service.dart';
import 'sync_conflict_repository.dart';

class SyncStatusCubit extends Cubit<SyncStatusState> {
  SyncStatusCubit({
    required SyncOutboxRepository outboxRepository,
    required ConnectivityService connectivityService,
    required TenantContext tenantContext,
    required SyncConflictRepository conflictRepository,
    SyncPullService? pullService,
  }) : _outboxRepository = outboxRepository,
       _connectivityService = connectivityService,
       _tenantContext = tenantContext,
       _conflictRepository = conflictRepository,
       _pullService = pullService,
       super(const SyncIdle());

  final SyncOutboxRepository _outboxRepository;
  final ConnectivityService _connectivityService;
  final TenantContext _tenantContext;
  final SyncConflictRepository _conflictRepository;
  final SyncPullService? _pullService;

  StreamSubscription<void>? _summarySubscription;
  StreamSubscription<ConnectivitySnapshot>? _connectivitySubscription;
  StreamSubscription<void>? _conflictSubscription;
  SyncOutboxSummary _summary = SyncOutboxSummary.empty;
  bool _isOnline = true;
  bool _isPulling = false;
  int _conflictCount = 0;

  void start() {
    _isOnline = _connectivityService.isOnline;
    _summarySubscription ??= _outboxRepository.watchChanges().listen((_) {
      unawaited(refresh());
    });
    _connectivitySubscription ??= _connectivityService.changes.listen((
      snapshot,
    ) {
      _isOnline = snapshot.isOnline;
      _emitCurrent(); // Emit immediately for connectivity changes
      unawaited(refresh());
    });
    _conflictSubscription ??= _conflictRepository.watchChanges().listen((_) {
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  Future<void> refresh() async {
    _summary = await _outboxRepository.getSummary(
      tenantId: _tenantContext.selectedTenantId,
    );
    _isOnline = (await _connectivityService.checkNow()).isOnline;
    _conflictCount = await _conflictRepository.countOpenConflicts(
      tenantId: _tenantContext.selectedTenantId,
    );
    _emitCurrent();
  }

  Future<void> pullIncremental() async {
    if (_pullService == null || _isPulling) return;

    _isPulling = true;
    _emitCurrent();

    final result = await _pullService.pullIncremental(
      tenantId: _tenantContext.selectedTenantId,
      deviceId: 'current', // or get real device ID
    );

    _isPulling = false;
    await refresh();

    if (result.isSuccess) {
      // optional: trigger app-wide data refresh if many things changed
    }
  }

  void _emitCurrent() {
    final pendingCount = _summary.pendingCount + _summary.processingCount;

    if (_isPulling) {
      emit(
        SyncPulling(
          pendingCount: pendingCount,
          failedCount: _summary.failedCount,
          conflictCount: _conflictCount,
          lastSyncedAt: _summary.lastSyncedAt,
          lastError: _summary.lastError,
          isOnline: _isOnline,
        ),
      );
      return;
    }

    if (!_isOnline) {
      emit(
        SyncOffline(
          pendingCount: pendingCount,
          failedCount: _summary.failedCount,
          conflictCount: _conflictCount,
          lastSyncedAt: _summary.lastSyncedAt,
          lastError: _summary.lastError,
        ),
      );
      return;
    }
    if (_summary.failedCount > 0) {
      emit(
        SyncFailed(
          pendingCount: pendingCount,
          failedCount: _summary.failedCount,
          conflictCount: _conflictCount,
          lastSyncedAt: _summary.lastSyncedAt,
          lastError: _summary.lastError,
        ),
      );
      return;
    }
    if (_summary.processingCount > 0) {
      emit(
        SyncProcessing(
          pendingCount: pendingCount,
          failedCount: _summary.failedCount,
          conflictCount: _conflictCount,
          lastSyncedAt: _summary.lastSyncedAt,
        ),
      );
      return;
    }
    if (_summary.pendingCount > 0) {
      emit(
        SyncPending(
          pendingCount: _summary.pendingCount,
          failedCount: _summary.failedCount,
          conflictCount: _conflictCount,
          lastSyncedAt: _summary.lastSyncedAt,
        ),
      );
      return;
    }
    if (_summary.lastSyncedAt != null || _conflictCount > 0) {
      emit(
        SyncSynced(
          lastSyncedAt: _summary.lastSyncedAt,
          conflictCount: _conflictCount,
        ),
      );
      return;
    }
    emit(SyncIdle(conflictCount: _conflictCount));
  }

  @override
  Future<void> close() async {
    await _summarySubscription?.cancel();
    await _connectivitySubscription?.cancel();
    await _conflictSubscription?.cancel();
    return super.close();
  }
}
