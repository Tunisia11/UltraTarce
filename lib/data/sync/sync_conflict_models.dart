import 'dart:convert';

enum SyncConflictStatus { open, resolved, ignored }

enum SyncConflictReason {
  localPendingRemoteChanged,
  localFailedRemoteChanged,
  remoteDeletedLocalPending,
  localDeletedRemoteChanged,
  versionMismatch,
  dependencyConflict,
}

class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.tenantId,
    required this.entityType,
    required this.entityId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.localPayloadJson,
    this.remotePayloadJson,
    this.localUpdatedAt,
    this.remoteUpdatedAt,
    this.resolvedAt,
    this.resolvedBy,
  });

  final String id;
  final String tenantId;
  final String entityType;
  final String entityId;
  final SyncConflictReason reason;
  final SyncConflictStatus status;
  final String? localPayloadJson;
  final String? remotePayloadJson;
  final DateTime? localUpdatedAt;
  final DateTime? remoteUpdatedAt;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  Map<String, dynamic>? get localPayload {
    if (localPayloadJson == null) return null;
    try {
      return jsonDecode(localPayloadJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get remotePayload {
    if (remotePayloadJson == null) return null;
    try {
      return jsonDecode(remotePayloadJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String get reasonLabel {
    switch (reason) {
      case SyncConflictReason.localPendingRemoteChanged:
        return 'Modification locale en attente + Changement distant';
      case SyncConflictReason.localFailedRemoteChanged:
        return 'Échec local précédent + Changement distant';
      case SyncConflictReason.remoteDeletedLocalPending:
        return 'Supprimé à distance + Modification locale en attente';
      case SyncConflictReason.localDeletedRemoteChanged:
        return 'Supprimé localement + Changement distant';
      case SyncConflictReason.versionMismatch:
        return 'Conflit de version';
      case SyncConflictReason.dependencyConflict:
        return 'Conflit de dépendance';
    }
  }
}
