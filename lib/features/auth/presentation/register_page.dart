import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/auth_cubit.dart';
import '../application/auth_state.dart';

import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onShowLogin,
    this.message,
    this.enabled = true,
  });

  final VoidCallback onShowLogin;
  final String? message;
  final bool enabled;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state is AuthLoading;
    return AuthScaffold(
      title: 'Créer un compte',
      message: widget.message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            enabled: widget.enabled && !loading,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          TextField(
            controller: _companyController,
            enabled: widget.enabled && !loading,
            decoration: const InputDecoration(labelText: 'Nom de société'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: widget.enabled && !loading ? _register : null,
            child: Text(loading ? 'Création...' : 'Créer mon espace'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: loading ? null : widget.onShowLogin,
            child: const Text('J’ai déjà un compte'),
          ),
        ],
      ),
    );
  }

  Future<void> _register() async {
    await context.read<AuthCubit>().registerWithEmailPassword(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
      companyName: _companyController.text,
    );
  }
}
