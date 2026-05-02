import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_config.dart';
import '../application/auth_cubit.dart';
import '../application/auth_state.dart';
import '../application/tenant_cubit.dart';
import '../application/tenant_state.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import '../data/tenant_repository.dart';
import 'forgot_password_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'tenant_selection_page.dart';
import 'user_menu.dart';
import '../../subscription/data/subscription_status_repository.dart';
import '../../subscription/presentation/subscription_gate.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.inventoryBuilder,
    this.config,
    this.authRepository,
    this.tenantRepository,
    this.subscriptionStatusRepository,
  });

  final WidgetBuilder inventoryBuilder;
  final AppConfig? config;
  final AuthRepository? authRepository;
  final TenantRepository? tenantRepository;
  final SubscriptionStatusRepository? subscriptionStatusRepository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AppConfig _config;
  late final AuthCubit _authCubit;
  late final TenantCubit _tenantCubit;
  _AuthPageMode _mode = _AuthPageMode.login;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? AppConfig.fromEnvironment();
    final authRepository =
        widget.authRepository ?? SupabaseAuthRepository(config: _config);
    final tenantRepository =
        widget.tenantRepository ?? SupabaseTenantRepository(config: _config);
    _authCubit = AuthCubit(authRepository);
    _tenantCubit = TenantCubit(tenantRepository);
    _authCubit.initialize();
  }

  @override
  void dispose() {
    _authCubit.close();
    _tenantCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: _authCubit),
        BlocProvider<TenantCubit>.value(value: _tenantCubit),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _tenantCubit.loadMemberships(state.user);
          } else if (state is AuthUnauthenticated) {
            _tenantCubit.clearSelection();
          }
        },
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading || state is AuthInitial) {
              return const _AuthLoadingView(
                message: 'Préparation du compte...',
              );
            }
            if (state is AuthAuthenticated) {
              return _TenantGate(
                user: state.user,
                inventoryBuilder: widget.inventoryBuilder,
                subscriptionStatusRepository:
                    widget.subscriptionStatusRepository,
                onLogout: () => context.read<AuthCubit>().logout(),
              );
            }
            if (state is AuthFailure) {
              return _buildAuthPage(message: state.message, enabled: false);
            }
            final message = state is AuthUnauthenticated ? state.message : null;
            return _buildAuthPage(message: message);
          },
        ),
      ),
    );
  }

  Widget _buildAuthPage({String? message, bool enabled = true}) {
    return switch (_mode) {
      _AuthPageMode.login => LoginPage(
        message: message ?? _config.configurationWarning,
        enabled: enabled && _config.configurationWarning == null,
        onShowRegister: () => setState(() => _mode = _AuthPageMode.register),
        onShowForgotPassword: () =>
            setState(() => _mode = _AuthPageMode.forgotPassword),
      ),
      _AuthPageMode.register => RegisterPage(
        onShowLogin: () => setState(() => _mode = _AuthPageMode.login),
      ),
      _AuthPageMode.forgotPassword => ForgotPasswordPage(
        onShowLogin: () => setState(() => _mode = _AuthPageMode.login),
      ),
    };
  }
}

class _TenantGate extends StatelessWidget {
  const _TenantGate({
    required this.user,
    required this.inventoryBuilder,
    required this.onLogout,
    this.subscriptionStatusRepository,
  });

  final AppUser user;
  final WidgetBuilder inventoryBuilder;
  final VoidCallback onLogout;
  final SubscriptionStatusRepository? subscriptionStatusRepository;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TenantCubit, TenantState>(
      builder: (context, state) {
        if (state is TenantInitial || state is TenantLoading) {
          return const _AuthLoadingView(message: 'Chargement des sociétés...');
        }
        if (state is TenantFailure) {
          return TenantSelectionPage(
            user: user,
            memberships: const [],
            message: state.message,
            onSelectTenant: (_) {},
            onCreateTenant: (name) => context
                .read<TenantCubit>()
                .createFirstTenant(user: user, companyName: name),
            onLogout: onLogout,
          );
        }
        if (state is TenantEmpty) {
          return TenantSelectionPage(
            user: user,
            memberships: const [],
            onSelectTenant: (_) {},
            onCreateTenant: (name) => context
                .read<TenantCubit>()
                .createFirstTenant(user: user, companyName: name),
            onLogout: onLogout,
          );
        }
        if (state is TenantLoaded) {
          return TenantSelectionPage(
            user: user,
            memberships: state.memberships,
            onSelectTenant: (tenant) =>
                context.read<TenantCubit>().selectTenant(
                  user: user,
                  tenant: tenant,
                  memberships: state.memberships,
                ),
            onCreateTenant: (name) => context
                .read<TenantCubit>()
                .createFirstTenant(user: user, companyName: name),
            onLogout: onLogout,
          );
        }
        if (state is TenantSelected) {
          return TenantWorkspaceShell(
            user: user,
            tenant: state.selectedTenant,
            memberships: state.memberships,
            onLogout: onLogout,
            onChangeTenant: () async {
              await context.read<TenantCubit>().clearSelection();
              if (context.mounted) {
                await context.read<TenantCubit>().loadMemberships(user);
              }
            },
            child: SubscriptionGate(
              tenantId: state.selectedTenant.tenantId,
              repository: subscriptionStatusRepository,
              child: inventoryBuilder(context),
            ),
          );
        }
        return const _AuthLoadingView(message: 'Préparation...');
      },
    );
  }
}

class _AuthLoadingView extends StatelessWidget {
  const _AuthLoadingView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
}

enum _AuthPageMode { login, register, forgotPassword }
