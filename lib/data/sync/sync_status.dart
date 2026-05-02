sealed class SyncStatusState {
  const SyncStatusState({
    required this.pendingCount,
    required this.failedCount,
    required this.isOnline,
    this.conflictCount = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  final int pendingCount;
  final int failedCount;
  final int conflictCount;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final bool isOnline;

  bool get hasConflicts => conflictCount > 0;

  String get label;
}

class SyncIdle extends SyncStatusState {
  const SyncIdle({
    super.pendingCount = 0,
    super.failedCount = 0,
    super.conflictCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => hasConflicts ? 'Conflits à vérifier' : 'Synchronisé';
}

class SyncOffline extends SyncStatusState {
  const SyncOffline({
    required super.pendingCount,
    required super.failedCount,
    super.conflictCount = 0,
    super.lastSyncedAt,
    super.lastError,
  }) : super(isOnline: false);

  @override
  String get label => 'Sauvegardé localement';
}

class SyncPending extends SyncStatusState {
  const SyncPending({
    required super.pendingCount,
    required super.failedCount,
    super.conflictCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Sauvegardé localement';
}

class SyncProcessing extends SyncStatusState {
  const SyncProcessing({
    required super.pendingCount,
    required super.failedCount,
    super.conflictCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Synchronisation en cours…';
}

class SyncFailed extends SyncStatusState {
  const SyncFailed({
    required super.pendingCount,
    required super.failedCount,
    super.conflictCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'À vérifier';
}

class SyncSynced extends SyncStatusState {
  const SyncSynced({
    super.pendingCount = 0,
    super.failedCount = 0,
    super.conflictCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => hasConflicts ? 'Conflits à vérifier' : 'Synchronisé';
}

class SyncPulling extends SyncStatusState {
  const SyncPulling({
    required super.pendingCount,
    required super.failedCount,
    super.conflictCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Synchronisation en cours…';
}
