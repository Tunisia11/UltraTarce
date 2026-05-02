import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository) : super(const AuthInitial());

  final AuthRepository _authRepository;
  StreamSubscription<AppUser?>? _authSubscription;

  AuthRepository get repository => _authRepository;

  Future<void> initialize() async {
    emit(const AuthInitializing());
    try {
      _listenToAuthChanges();
      final user = await _authRepository.initialize();
      if (user == null) {
        final warning = _authRepository.configurationWarning;
        if (!_authRepository.isConfigured && warning != null) {
          emit(AuthFailure(warning));
        } else {
          emit(AuthUnauthenticated(message: warning));
        }
      } else {
        emit(AuthAuthenticated(user));
      }
    } catch (error) {
      if (_isRefreshTokenError(error)) {
        await logout();
        return;
      }
      emit(AuthFailure(_friendlyMessage(error)));
    }
  }

  Future<AppUser?> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.loginWithEmailPassword(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
      return user;
    } catch (error) {
      emit(AuthFailure(_friendlyMessage(error)));
      return null;
    }
  }

  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    required String companyName,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
        companyName: companyName,
      );
      emit(AuthAuthenticated(user, registrationCompanyName: companyName));
      return user;
    } catch (error) {
      emit(AuthFailure(_friendlyMessage(error)));
      return null;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendPasswordReset(email);
      emit(
        const AuthUnauthenticated(
          message: 'Lien de réinitialisation envoyé si le compte existe.',
        ),
      );
    } catch (error) {
      emit(AuthFailure(_friendlyMessage(error)));
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(AuthFailure(_friendlyMessage(error)));
    }
  }

  void _listenToAuthChanges() {
    _authSubscription ??= _authRepository.authStateChanges.listen((user) {
      if (isClosed) return;
      if (user == null) {
        emit(const AuthUnauthenticated());
      } else {
        final current = state;
        final registrationCompanyName =
            (current is AuthAuthenticated && current.user.id == user.id)
            ? current.registrationCompanyName
            : null;
        emit(
          AuthAuthenticated(
            user,
            registrationCompanyName: registrationCompanyName,
          ),
        );
      }
    });
  }

  String _friendlyMessage(Object error) {
    if (error is AuthRepositoryException) return error.message;
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login') || message.contains('invalid')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (message.contains('network') || message.contains('socket')) {
      return 'Connexion réseau indisponible. Réessayez plus tard.';
    }
    if (message.contains('already registered')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (_isRefreshTokenError(error)) {
      return 'Session expirée. Veuillez vous reconnecter.';
    }
    return 'Opération impossible. Vérifiez les informations et réessayez.';
  }

  bool _isRefreshTokenError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('refresh_token_not_found') ||
        message.contains('refresh token not found');
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
