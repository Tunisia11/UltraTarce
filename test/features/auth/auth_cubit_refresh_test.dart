import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/auth/application/auth_cubit.dart';
import 'package:ultra_trace/features/auth/application/auth_state.dart';
import 'package:ultra_trace/features/auth/data/auth_models.dart';

import 'fake_auth_repositories.dart';

class RefreshTokenErrorAuthRepository extends FakeAuthRepository {
  @override
  Future<AppUser?> initialize() async {
    throw Exception('refresh_token_not_found');
  }

  bool logoutCalled = false;
  @override
  Future<void> logout() async {
    logoutCalled = true;
    return super.logout();
  }
}

void main() {
  test('AuthCubit handles refresh_token_not_found by logging out', () async {
    final repo = RefreshTokenErrorAuthRepository();
    final cubit = AuthCubit(repo);

    await cubit.initialize();

    expect(cubit.state, isA<AuthUnauthenticated>());
    expect(repo.logoutCalled, isTrue);
  });
}
