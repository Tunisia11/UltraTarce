import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/client_repository.dart';
import 'package:ultra_trace/data/repositories/supplier_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('client create and update persist after reload', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = ClientRepository(harness.appRepository);

    final client = testPartner(id: 'c-new', name: 'Client A');
    repository.upsert(client, status: 'Client sauvegardé.');
    repository.upsert(
      client.copyWith(phone: '72000000'),
      status: 'Client sauvegardé.',
    );
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    final saved = restored!.partners.singleWhere(
      (partner) => partner.id == 'c-new',
    );
    expect(saved.type, PartnerType.client);
    expect(saved.phone, '72000000');
  });

  test('supplier create and update persist after reload', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = SupplierRepository(harness.appRepository);

    final supplier = testPartner(
      id: 's-new',
      type: PartnerType.supplier,
      name: 'Fournisseur A',
    );
    repository.upsert(supplier, status: 'Fournisseur sauvegardé.');
    repository.upsert(
      supplier.copyWith(email: 's@example.com'),
      status: 'Fournisseur sauvegardé.',
    );
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    final saved = restored!.partners.singleWhere(
      (partner) => partner.id == 's-new',
    );
    expect(saved.type, PartnerType.supplier);
    expect(saved.email, 's@example.com');
  });
}
