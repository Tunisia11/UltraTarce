import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/auth_cubit.dart';
import '../application/auth_state.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.onShowLogin});

  final VoidCallback onShowLogin;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state is AuthLoading;
    return AuthScaffold(
      title: 'Réinitialisation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            enabled: !loading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: loading
                ? null
                : () => context.read<AuthCubit>().sendPasswordReset(
                    _emailController.text,
                  ),
            child: const Text('Envoyer le lien de réinitialisation'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: loading ? null : widget.onShowLogin,
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }
}
