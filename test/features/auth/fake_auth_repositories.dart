import 'dart:async';

import 'package:ultra_trace/features/auth/data/auth_models.dart';
import 'package:ultra_trace/features/auth/data/auth_repository.dart';
import 'package:ultra_trace/features/auth/data/tenant_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.initialUser, this.loginFailure});

  AppUser? initialUser;
  String? loginFailure;
  String? signupFailure;
  final controller = StreamController<AppUser?>.broadcast();

  bool loggedOut = false;

  @override
  bool get isConfigured => true;

  @override
  String? get configurationWarning => null;

  @override
  AppUser? get currentUser => initialUser;

  @override
  Stream<AppUser?> get authStateChanges => controller.stream;

  @override
  Future<AppUser?> initialize() async => initialUser;

  @override
  Future<AppUser> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (loginFailure != null) {
      throw AuthRepositoryException(loginFailure!);
    }
    initialUser = AppUser(id: 'user-1', email: email);
    controller.add(initialUser);
    return initialUser!;
  }

  @override
  Future<AppUser> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required String companyName,
  }) async {
    if (signupFailure != null) {
      throw AuthRepositoryException(signupFailure!);
    }
    initialUser = AppUser(id: 'user-1', email: email, displayName: displayName);
    controller.add(initialUser);
    return initialUser!;
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> submitTrialRequest({
    required String fullName,
    required String email,
    required String companyName,
    String? phone,
    String? message,
  }) async {}

  @override
  Future<void> logout() async {
    loggedOut = true;
    initialUser = null;
    controller.add(null);
  }

  Future<void> close() => controller.close();
}

class FakeTenantRepository implements TenantRepository {
  FakeTenantRepository(this.memberships);

  List<TenantMembership> memberships;
  TenantMembership? storedTenant;
  AppUser? storedUser;
  String? createFailure;

  @override
  Future<List<TenantMembership>> loadMemberships(AppUser user) async {
    return memberships;
  }

  @override
  Future<TenantMembership> createFirstTenant({
    required AppUser user,
    required String companyName,
  }) async {
    if (createFailure != null) {
      throw AuthRepositoryException(createFailure!);
    }
    final tenant = TenantMembership(
      tenantId: 'created-tenant',
      tenantName: companyName,
      role: TenantRole.owner,
    );
    memberships = [tenant];
    return tenant;
  }

  @override
  Future<void> storeSelectedTenant({
    required AppUser user,
    required TenantMembership tenant,
  }) async {
    storedUser = user;
    storedTenant = tenant;
  }

  @override
  TenantMembership? loadSelectedTenant(AppUser user) {
    return storedUser?.id == user.id ? storedTenant : null;
  }

  @override
  Future<void> clearSelectedTenant() async {
    storedTenant = null;
  }
}
