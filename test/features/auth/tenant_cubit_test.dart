import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/auth/application/tenant_cubit.dart';
import 'package:ultra_trace/features/auth/application/tenant_state.dart';
import 'package:ultra_trace/features/auth/data/auth_models.dart';

import 'fake_auth_repositories.dart';

void main() {
  const user = AppUser(id: 'user-1', email: 'user@example.com');
  const tenantA = TenantMembership(
    tenantId: 'tenant-a',
    tenantName: 'Société A',
    role: TenantRole.owner,
  );
  const tenantB = TenantMembership(
    tenantId: 'tenant-b',
    tenantName: 'Société B',
    role: TenantRole.manager,
  );

  test('one tenant auto-selects', () async {
    final repo = FakeTenantRepository([tenantA]);
    final cubit = TenantCubit(repo);

    await cubit.loadMemberships(user);

    expect(cubit.state, isA<TenantSelected>());
    expect(repo.storedTenant?.tenantId, 'tenant-a');
    await cubit.close();
  });

  test('multiple tenants require selection', () async {
    final repo = FakeTenantRepository([tenantA, tenantB]);
    final cubit = TenantCubit(repo);

    await cubit.loadMemberships(user);

    expect(cubit.state, isA<TenantLoaded>());
    await cubit.close();
  });

  test('no tenant shows empty state', () async {
    final repo = FakeTenantRepository([]);
    final cubit = TenantCubit(repo);

    await cubit.loadMemberships(user);

    expect(cubit.state, isA<TenantEmpty>());
    await cubit.close();
  });

  test('selected tenant is stored locally through repository', () async {
    final repo = FakeTenantRepository([tenantA, tenantB]);
    final cubit = TenantCubit(repo);

    await cubit.selectTenant(user: user, tenant: tenantB);

    expect(cubit.state, isA<TenantSelected>());
    expect(repo.storedTenant?.tenantId, 'tenant-b');
    await cubit.close();
  });
}
