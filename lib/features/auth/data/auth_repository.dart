import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_config.dart';
import 'auth_models.dart';

abstract class AuthRepository {
  bool get isConfigured;

  String? get configurationWarning;

  AppUser? get currentUser;

  Stream<AppUser?> get authStateChanges;

  Future<AppUser?> initialize();

  Future<AppUser> loginWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required String companyName,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> logout();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required AppConfig config, SupabaseClient? client})
    : _config = config,
      _client = client ?? _safeClient();

  final AppConfig _config;
  final SupabaseClient? _client;
  final _devAuthController = StreamController<AppUser?>.broadcast();
  AppUser? _devUser;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get isConfigured => _config.authBypassEnabled || _client != null;

  @override
  String? get configurationWarning => _config.configurationWarning;

  @override
  AppUser? get currentUser {
    if (_config.authBypassEnabled) return _devUser;
    return _mapUser(_client?.auth.currentUser);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    if (_config.authBypassEnabled) return _devAuthController.stream;
    final client = _requireClient();
    return client.auth.onAuthStateChange.map(
      (event) => _mapUser(event.session?.user),
    );
  }

  @override
  Future<AppUser?> initialize() async {
    if (_config.authBypassEnabled) {
      _devUser = const AppUser(
        id: 'local-dev-user',
        email: 'dev@trace-ultra.local',
        displayName: 'Développement local',
        isDevBypass: true,
      );
      _devAuthController.add(_devUser);
      return _devUser;
    }
    if (_client == null) return null;
    return _mapUser(_client.auth.currentUser);
  }

  @override
  Future<AppUser> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (_config.authBypassEnabled) {
      _devUser = AppUser(
        id: 'local-dev-user',
        email: email.trim().isEmpty ? 'dev@trace-ultra.local' : email.trim(),
        displayName: 'Développement local',
        isDevBypass: true,
      );
      _devAuthController.add(_devUser);
      return _devUser!;
    }
    final response = await _requireClient().auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = _mapUser(response.user);
    if (user == null) {
      throw const AuthRepositoryException('Connexion impossible.');
    }
    return user;
  }

  @override
  Future<AppUser> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required String companyName,
  }) async {
    if (_config.authBypassEnabled) {
      _devUser = AppUser(
        id: 'local-dev-user',
        email: email.trim().isEmpty ? 'dev@trace-ultra.local' : email.trim(),
        displayName: displayName.trim(),
        isDevBypass: true,
      );
      _devAuthController.add(_devUser);
      return _devUser!;
    }
    final response = await _requireClient().auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'full_name': displayName.trim(),
        'company_name': companyName.trim(),
      },
    );
    final user = _mapUser(response.user);
    if (user == null) {
      throw const AuthRepositoryException(
        'Compte créé. Vérifiez votre email avant de vous connecter.',
      );
    }
    return user;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (_config.authBypassEnabled) return;
    await _requireClient().auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> logout() async {
    if (_config.authBypassEnabled) {
      _devUser = null;
      _devAuthController.add(null);
      return;
    }
    await _requireClient().auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw AuthRepositoryException(
        configurationWarning ??
            'Supabase n’est pas initialisé. Vérifiez la configuration.',
      );
    }
    return client;
  }

  AppUser? _mapUser(User? user) {
    if (user == null) return null;
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: metadata['full_name'] as String? ?? '',
    );
  }
}
