import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_colors.dart';
import '../application/auth_cubit.dart';
import '../application/auth_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.onShowRegister,
    required this.onShowForgotPassword,
    this.message,
    this.enabled = true,
  });

  final VoidCallback onShowRegister;
  final VoidCallback onShowForgotPassword;
  final String? message;
  final bool enabled;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state is AuthLoading;
    return AuthScaffold(
      title: 'Connexion',
      message: widget.message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            enabled: widget.enabled && !loading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            enabled: widget.enabled && !loading,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: widget.enabled && !loading
                ? () => context.read<AuthCubit>().loginWithEmailPassword(
                    email: _emailController.text,
                    password: _passwordController.text,
                  )
                : null,
            child: Text(loading ? 'Connexion...' : 'Se connecter'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: loading ? null : widget.onShowForgotPassword,
            child: const Text('Mot de passe oublié'),
          ),
          TextButton(
            onPressed: loading ? null : widget.onShowRegister,
            child: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.message,
  });

  final String title;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineMedium),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .08),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: .25),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        message!,
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
