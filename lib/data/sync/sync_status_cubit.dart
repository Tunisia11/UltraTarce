import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/tenant_context.dart';
import 'connectivity_service.dart';
import 'sync_outbox_repository.dart';
import 'sync_status.dart';

class SyncStatusCubit extends Cubit<SyncStatusState> {
  SyncStatusCubit({
    required SyncOutboxRepository outboxRepository,
    required ConnectivityService connectivityService,
    required TenantContext tenantContext,
  }) : _outboxRepository = outboxRepository,
       _connectivityService = connectivityService,
       _tenantContext = tenantContext,
       super(const SyncIdle());

  final SyncOutboxRepository _outboxRepository;
  final ConnectivityService _connectivityService;
  final TenantContext _tenantContext;
  StreamSubscription<SyncOutboxSummary>? _summarySubscription;
  StreamSubscription<ConnectivitySnapshot>? _connectivitySubscription;
  SyncOutboxSummary _summary = SyncOutboxSummary.empty;
  bool _isOnline = true;

  void start() {
    _isOnline = _connectivityService.isOnline;
    _summarySubscription ??= _outboxRepository
        .watchSummary(tenantId: _tenantContext.selectedTenantId)
        .listen((summary) {
          _summary = summary;
          _emitCurrent();
        });
    _connectivitySubscription ??= _connectivityService.changes.listen((
      snapshot,
    ) {
      _isOnline = snapshot.isOnline;
      _emitCurrent();
    });
    unawaited(refresh());
  }

  Future<void> refresh() async {
    _summary = await _outboxRepository.getSummary(
      tenantId: _tenantContext.selectedTenantId,
    );
    _isOnline = (await _connectivityService.checkNow()).isOnline;
    _emitCurrent();
  }

  void _emitCurrent() {
    final pendingCount = _summary.pendingCount + _summary.processingCount;
    if (!_isOnline) {
      emit(
        SyncOffline(
          pendingCount: pendingCount,
          failedCount: _summary.failedCount,
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
          lastSyncedAt: _summary.lastSyncedAt,
        ),
      );
      return;
    }
    if (_summary.lastSyncedAt != null) {
      emit(SyncSynced(lastSyncedAt: _summary.lastSyncedAt));
      return;
    }
    emit(const SyncIdle());
  }

  @override
  Future<void> close() async {
    await _summarySubscription?.cancel();
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}
