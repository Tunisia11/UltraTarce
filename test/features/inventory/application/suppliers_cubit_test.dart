import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/features/inventory/application/suppliers_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('SuppliersCubit creates and updates supplier through repository', () {
    final repositories = createTestRepositories();
    final cubit = SuppliersCubit(
      repositories.supplierRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    final supplier = testSupplier();

    cubit.createSupplier(supplier);
    cubit.updateSupplier(supplier.copyWith(name: 'Fournisseur modifié'));

    final saved = repositories.appRepository.snapshot.partners.single;
    expect(saved.type, PartnerType.supplier);
    expect(saved.name, 'Fournisseur modifié');
    expect(
      repositories.appRepository.snapshot.auditEvents.first.action,
      'Modification tiers',
    );
  });
}
