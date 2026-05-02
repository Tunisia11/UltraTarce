import '../data/auth_models.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthInitializing extends AuthState {
  const AuthInitializing();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  final String? message;
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user, {this.registrationCompanyName});

  final AppUser user;
  final String? registrationCompanyName;
}

class AuthFailure extends AuthState {
  const AuthFailure(this.message);

  final String message;
}
