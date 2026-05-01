import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/app_config.dart';
import 'package:ultra_trace/features/auth/data/auth_models.dart';
import 'package:ultra_trace/features/auth/presentation/auth_gate.dart';

import 'fake_auth_repositories.dart';

void main() {
  testWidgets('unauthenticated state shows login', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          config: AppConfig.devBypass(),
          authRepository: FakeAuthRepository(),
          tenantRepository: FakeTenantRepository(const []),
          inventoryBuilder: (_) => const Text('Inventaire'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('authenticated user with one tenant opens inventory', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authRepository: FakeAuthRepository(
            initialUser: const AppUser(id: 'user-1', email: 'user@example.com'),
          ),
          tenantRepository: FakeTenantRepository(const [
            TenantMembership(
              tenantId: 'tenant-a',
              tenantName: 'Société A',
              role: TenantRole.owner,
            ),
          ]),
          inventoryBuilder: (_) => const Text('Inventaire prêt'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Société A'), findsWidgets);
    expect(find.text('Inventaire prêt'), findsOneWidget);
  });

  testWidgets('multiple tenants require tenant selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authRepository: FakeAuthRepository(
            initialUser: const AppUser(id: 'user-1', email: 'user@example.com'),
          ),
          tenantRepository: FakeTenantRepository(const [
            TenantMembership(
              tenantId: 'tenant-a',
              tenantName: 'Société A',
              role: TenantRole.owner,
            ),
            TenantMembership(
              tenantId: 'tenant-b',
              tenantName: 'Société B',
              role: TenantRole.manager,
            ),
          ]),
          inventoryBuilder: (_) => const Text('Inventaire prêt'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choisir une société'), findsOneWidget);
    expect(find.text('Société A'), findsOneWidget);
    expect(find.text('Société B'), findsOneWidget);
  });
}
