import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/company_repository.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('company fiscal settings persist after reload', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = CompanyRepository(harness.appRepository);

    repository.updateCompany(
      repository.getCompany().copyWith(
        timbreFiscalEnabled: false,
        timbreFiscalAmount: 2,
      ),
      status: 'Configuration fiscale sauvegardée.',
    );
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.company.timbreFiscalEnabled, isFalse);
    expect(restored.company.timbreFiscalAmount, 2);
  });
}
