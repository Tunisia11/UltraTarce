import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/audit_repository.dart';
import 'package:ultra_trace/domain/services/audit_service.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('audit event insert persists after reload', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = AuditRepository(harness.appRepository);

    repository.saveAll(
      AuditService.append(
        events: repository.getAll(),
        action: 'Création produit',
        target: 'ART-001',
        detail: 'Article créé',
      ),
      status: 'Audit sauvegardé.',
    );
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.auditEvents.single.action, 'Création produit');
  });
}
