import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/auth/application/auth_cubit.dart';
import 'package:ultra_trace/features/auth/application/auth_state.dart';
import 'package:ultra_trace/features/auth/data/auth_models.dart';

import 'fake_auth_repositories.dart';

void main() {
  test('initialize without session emits unauthenticated', () async {
    final repo = FakeAuthRepository();
    final cubit = AuthCubit(repo);

    await cubit.initialize();

    expect(cubit.state, isA<AuthUnauthenticated>());
    await cubit.close();
    await repo.close();
  });

  test('login success moves to authenticated state', () async {
    final repo = FakeAuthRepository();
    final cubit = AuthCubit(repo);

    final user = await cubit.loginWithEmailPassword(
      email: 'user@example.com',
      password: 'secret',
    );

    expect(user?.email, 'user@example.com');
    expect(cubit.state, isA<AuthAuthenticated>());
    await cubit.close();
    await repo.close();
  });

  test('login failure gives failure state', () async {
    final repo = FakeAuthRepository(
      loginFailure: 'Email ou mot de passe incorrect.',
    );
    final cubit = AuthCubit(repo);

    await cubit.loginWithEmailPassword(
      email: 'user@example.com',
      password: 'bad',
    );

    expect(cubit.state, isA<AuthFailure>());
    await cubit.close();
    await repo.close();
  });

  test('logout clears auth state', () async {
    final repo = FakeAuthRepository(
      initialUser: const AppUser(id: 'user-1', email: 'user@example.com'),
    );
    final cubit = AuthCubit(repo);

    await cubit.logout();

    expect(repo.loggedOut, isTrue);
    expect(cubit.state, isA<AuthUnauthenticated>());
    await cubit.close();
    await repo.close();
  });

  test(
    'registration success moves to authenticated state with company name',
    () async {
      final repo = FakeAuthRepository();
      final cubit = AuthCubit(repo);

      final user = await cubit.registerWithEmailPassword(
        email: 'new@example.com',
        password: 'password',
        displayName: 'New User',
        companyName: 'New Co',
      );

      expect(user?.email, 'new@example.com');
      final state = cubit.state;
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).registrationCompanyName, 'New Co');
      await cubit.close();
      await repo.close();
    },
  );

  test('sendPasswordReset emits safe success message', () async {
    final repo = FakeAuthRepository();
    final cubit = AuthCubit(repo);

    await cubit.sendPasswordReset('user@example.com');

    expect(cubit.state, isA<AuthUnauthenticated>());
    expect(
      (cubit.state as AuthUnauthenticated).message,
      'Si un compte existe avec cet email, un lien de réinitialisation sera envoyé.',
    );
    await cubit.close();
    await repo.close();
  });

  test('submitTrialRequest emits success message', () async {
    final repo = FakeAuthRepository();
    final cubit = AuthCubit(repo);

    final success = await cubit.submitTrialRequest(
      fullName: 'Test User',
      email: 'test@example.com',
      companyName: 'Test Co',
    );

    expect(success, isTrue);
    expect(cubit.state, isA<AuthUnauthenticated>());
    expect(
      (cubit.state as AuthUnauthenticated).message,
      'Demande envoyée. Nous vous contacterons rapidement.',
    );
    await cubit.close();
    await repo.close();
  });
}
