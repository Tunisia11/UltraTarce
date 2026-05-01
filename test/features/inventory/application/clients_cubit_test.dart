import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/features/inventory/application/clients_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('ClientsCubit creates client through repository', () {
    final repositories = createTestRepositories();
    final cubit = ClientsCubit(
      repositories.clientRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    final client = testClient();

    cubit.createClient(client);

    expect(repositories.appRepository.snapshot.partners, hasLength(1));
    expect(
      repositories.appRepository.snapshot.partners.single.type,
      PartnerType.client,
    );
    expect(cubit.state.clients.single.name, client.name);
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Création tiers',
    );
  });

  test('ClientsCubit updates client through repository', () {
    final client = testClient();
    final repositories = createTestRepositories(
      snapshot: testSnapshot(partners: [client]),
    );
    final cubit = ClientsCubit(
      repositories.clientRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.updateClient(client.copyWith(name: 'Client modifié'));

    expect(
      repositories.appRepository.snapshot.partners.single.name,
      'Client modifié',
    );
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Modification tiers',
    );
  });
}
