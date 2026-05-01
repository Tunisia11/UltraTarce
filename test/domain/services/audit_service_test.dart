import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/audit_service.dart';

void main() {
  test('creates audit event metadata', () {
    final event = AuditService.createEvent(
      action: 'Création produit',
      target: 'ART',
      detail: 'Produit créé.',
      date: DateTime(2026, 5, 1),
    );

    expect(event.actor, 'Utilisateur local');
    expect(event.action, 'Création produit');
    expect(event.target, 'ART');
    expect(event.id, 'audit-${DateTime(2026, 5, 1).microsecondsSinceEpoch}');
  });

  test('prepends events and enforces max length', () {
    final events = [_event('old-1'), _event('old-2')];

    final next = AuditService.append(
      events: events,
      action: 'Paiement',
      target: 'FAC-2026-0001',
      detail: 'Encaissement ajouté.',
      maxEvents: 2,
      date: DateTime(2026, 5, 1),
    );

    expect(next.length, 2);
    expect(next.first.action, 'Paiement');
    expect(next.last.id, 'old-1');
  });
}

AuditEvent _event(String id) {
  return AuditEvent(
    id: id,
    date: DateTime(2026, 4, 1),
    actor: 'Utilisateur local',
    action: 'Ancien',
    target: id,
    detail: 'Ancien événement',
  );
}
