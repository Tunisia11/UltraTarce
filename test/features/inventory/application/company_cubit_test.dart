import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/application/company_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('CompanyCubit updates fiscal settings', () {
    final repositories = createTestRepositories();
    final cubit = CompanyCubit(
      repositories.companyRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.updateFiscalSettings(
      timbreFiscalEnabled: false,
      timbreFiscalAmount: 2,
    );

    final company = repositories.appRepository.snapshot.company;
    expect(company.timbreFiscalEnabled, isFalse);
    expect(company.timbreFiscalAmount, 2);
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Configuration fiscale',
    );
  });
}
