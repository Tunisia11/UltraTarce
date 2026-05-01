import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../application/auth_cubit.dart';
import '../application/auth_state.dart';
import '../application/tenant_cubit.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.onShowLogin});

  final VoidCallback onShowLogin;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            enabled: !loading,
            decoration: const InputDecoration(labelText: 'Nom complet'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            enabled: !loading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            enabled: !loading,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _companyController,
            enabled: !loading,
            decoration: const InputDecoration(labelText: 'Nom de société'),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: loading ? null : _register,
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
    final user = await context.read<AuthCubit>().registerWithEmailPassword(
      email: _emailController.text,
      password: _passwordController.text,
      displayName: _nameController.text,
      companyName: _companyController.text,
    );
    if (!mounted || user == null || _companyController.text.trim().isEmpty) {
      return;
    }
    await context.read<TenantCubit>().createFirstTenant(
      user: user,
      companyName: _companyController.text,
    );
  }
}
