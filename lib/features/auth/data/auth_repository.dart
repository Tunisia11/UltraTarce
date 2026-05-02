import 'dart:async';
import 'package:flutter/foundation.dart';

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

  Future<void> submitTrialRequest({
    required String fullName,
    required String email,
    required String companyName,
    String? phone,
    String? message,
  });

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
    try {
      final response = await _requireClient().auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthRepositoryException('Connexion impossible.');
      }
      return user;
    } on AuthException catch (e) {
      throw _handleAuthException(e, fallback: 'Connexion impossible.');
    } catch (e) {
      debugPrint('Unknown exception during login: $e');
      throw const AuthRepositoryException(
        'Erreur de connexion. Vérifiez votre réseau.',
      );
    }
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
    try {
      final response = await _requireClient().auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': displayName.trim(),
          'company_name': companyName.trim(),
        },
      );

      if (response.session == null && response.user != null) {
        throw const AuthRepositoryException(
          'Compte créé. Vérifiez votre email pour confirmer le compte avant de continuer.',
        );
      }

      final user = _mapUser(response.user);
      if (user == null) {
        throw const AuthRepositoryException(
          'Création du compte impossible. Vérifiez les informations et réessayez.',
        );
      }
      return user;
    } on AuthException catch (e) {
      throw _handleAuthException(e, fallback: 'Création du compte impossible.');
    } catch (e) {
      debugPrint('Unknown exception during signup: $e');
      throw const AuthRepositoryException(
        'Création du compte impossible. Vérifiez votre réseau.',
      );
    }
  }

  @override
  Future<void> submitTrialRequest({
    required String fullName,
    required String email,
    required String companyName,
    String? phone,
    String? message,
  }) async {
    if (_config.authBypassEnabled) return;

    try {
      await _requireClient().from('trial_requests').insert({
        'full_name': fullName.trim(),
        'email': email.trim(),
        'company_name': companyName.trim(),
        'phone': phone?.trim(),
        'message': message?.trim(),
        'status': 'new',
        'source': 'trace_ultra',
      });
    } catch (e) {
      debugPrint('Error submitting trial request: $e');
      throw const AuthRepositoryException(
        'Envoi de la demande impossible. Vérifiez votre connexion.',
      );
    }
  }

  AuthRepositoryException _handleAuthException(
    AuthException e, {
    required String fallback,
  }) {
    debugPrint('Supabase AuthException: ${e.statusCode} ${e.message}');
    final msg = e.message.toLowerCase();

    if (e.statusCode == '429' || msg.contains('rate limit')) {
      return const AuthRepositoryException(
        'Trop de tentatives. Réessayez dans quelques minutes.',
      );
    }
    if (msg.contains('email_send_rate_limit') ||
        msg.contains('email rate limit')) {
      return const AuthRepositoryException(
        'Limite d’envoi email atteinte. Réessayez plus tard ou contactez Virex.',
      );
    }
    if (msg.contains('already registered') ||
        msg.contains('email_exists') ||
        msg.contains('already exists')) {
      return const AuthRepositoryException(
        'Un compte existe déjà avec cet email.',
      );
    }
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return const AuthRepositoryException('Email ou mot de passe incorrect.');
    }
    if (msg.contains('weak_password') ||
        (msg.contains('password') && msg.contains('short'))) {
      return const AuthRepositoryException(
        'Mot de passe trop faible (6 caractères min).',
      );
    }
    if (msg.contains('invalid email')) {
      return const AuthRepositoryException('Email invalide.');
    }
    if (msg.contains('email not confirmed')) {
      return const AuthRepositoryException('Email non confirmé.');
    }
    if (msg.contains('refresh_token_not_found') ||
        msg.contains('invalid refresh token')) {
      return const AuthRepositoryException(
        'Session expirée. Veuillez vous reconnecter.',
      );
    }

    return AuthRepositoryException(fallback);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (_config.authBypassEnabled) return;
    try {
      await _requireClient().auth.resetPasswordForEmail(email.trim());
    } on AuthException catch (e) {
      throw _handleAuthException(e, fallback: 'Réinitialisation impossible.');
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      throw const AuthRepositoryException('Erreur. Vérifiez votre réseau.');
    }
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
