import '../app_models.dart';

class AuditService {
  const AuditService._();

  static AuditEvent createEvent({
    required String action,
    required String target,
    required String detail,
    DateTime? date,
    String actor = 'Utilisateur local',
    String? id,
  }) {
    final timestamp = date ?? DateTime.now();
    return AuditEvent(
      id: id ?? 'audit-${timestamp.microsecondsSinceEpoch}',
      date: timestamp,
      actor: actor,
      action: action,
      target: target,
      detail: detail,
    );
  }

  static List<AuditEvent> append({
    required Iterable<AuditEvent> events,
    required String action,
    required String target,
    required String detail,
    int maxEvents = 300,
    DateTime? date,
  }) {
    final next = [
      createEvent(action: action, target: target, detail: detail, date: date),
      ...events,
    ];
    return next.length > maxEvents ? next.take(maxEvents).toList() : next;
  }
}
