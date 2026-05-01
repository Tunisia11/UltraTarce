sealed class SyncStatusState {
  const SyncStatusState({
    required this.pendingCount,
    required this.failedCount,
    required this.isOnline,
    this.lastSyncedAt,
    this.lastError,
  });

  final int pendingCount;
  final int failedCount;
  final DateTime? lastSyncedAt;
  final String? lastError;
  final bool isOnline;

  String get label;
}

class SyncIdle extends SyncStatusState {
  const SyncIdle({
    super.pendingCount = 0,
    super.failedCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Synchronisé';
}

class SyncOffline extends SyncStatusState {
  const SyncOffline({
    required super.pendingCount,
    required super.failedCount,
    super.lastSyncedAt,
    super.lastError,
  }) : super(isOnline: false);

  @override
  String get label => 'Hors ligne';
}

class SyncPending extends SyncStatusState {
  const SyncPending({
    required super.pendingCount,
    required super.failedCount,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Synchronisation en attente';
}

class SyncProcessing extends SyncStatusState {
  const SyncProcessing({
    required super.pendingCount,
    required super.failedCount,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Synchronisation...';
}

class SyncFailed extends SyncStatusState {
  const SyncFailed({
    required super.pendingCount,
    required super.failedCount,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Erreur de synchronisation';
}

class SyncSynced extends SyncStatusState {
  const SyncSynced({
    super.pendingCount = 0,
    super.failedCount = 0,
    super.isOnline = true,
    super.lastSyncedAt,
    super.lastError,
  });

  @override
  String get label => 'Synchronisé';
}
