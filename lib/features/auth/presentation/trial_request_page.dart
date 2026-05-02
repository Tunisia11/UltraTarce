import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_colors.dart';
import '../application/auth_cubit.dart';
import '../application/auth_state.dart';
import 'login_page.dart';

class TrialRequestPage extends StatefulWidget {
  const TrialRequestPage({super.key, required this.onShowLogin});

  final VoidCallback onShowLogin;

  @override
  State<TrialRequestPage> createState() => _TrialRequestPageState();
}

class _TrialRequestPageState extends State<TrialRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _messageController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthCubit>().state is AuthLoading;

    if (_submitted) {
      return AuthScaffold(
        title: 'Demande envoyée',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: .08),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: .25),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Demande envoyée avec succès !',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'L\'équipe Virex vous contactera rapidement pour activer votre espace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: widget.onShowLogin,
              child: const Text('Retour à la connexion'),
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      title: 'Demander un essai',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Remplissez ce formulaire pour demander un accès à Trace Ultra. '
              'Notre équipe vous contactera rapidement.',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Le nom est obligatoire'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              enabled: !loading,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'L\'email est obligatoire';
                }
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              enabled: !loading,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyController,
              enabled: !loading,
              decoration: const InputDecoration(
                labelText: 'Nom de société *',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Le nom de société est obligatoire'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              enabled: !loading,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Message (optionnel)',
                prefixIcon: Icon(Icons.message_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: loading ? null : _submit,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(loading ? 'Envoi...' : 'Envoyer la demande'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: loading ? null : widget.onShowLogin,
              child: const Text('J\'ai déjà un compte'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await context.read<AuthCubit>().submitTrialRequest(
      fullName: _nameController.text,
      email: _emailController.text,
      companyName: _companyController.text,
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text,
      message: _messageController.text.trim().isEmpty
          ? null
          : _messageController.text,
    );

    if (success && mounted) {
      setState(() => _submitted = true);
    }
  }
}

class InviteOnlyPage extends StatelessWidget {
  const InviteOnlyPage({super.key, required this.onShowLogin});

  final VoidCallback onShowLogin;

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Accès sur invitation',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .06),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .2),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(Icons.lock_outline, color: AppColors.primary, size: 48),
                SizedBox(height: 16),
                Text(
                  'Trace Ultra est accessible sur invitation uniquement.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Contactez Virex pour obtenir une invitation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onShowLogin,
            child: const Text('J\'ai déjà un compte'),
          ),
        ],
      ),
    );
  }
}
