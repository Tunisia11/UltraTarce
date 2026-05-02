import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../auth/data/auth_models.dart';

class InviteMemberDialog extends StatefulWidget {
  const InviteMemberDialog({super.key, required this.onInvite});

  final void Function(String email, String role) onInvite;

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _emailController = TextEditingController();
  String _selectedRole = 'cashier';
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Inviter un membre'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'exemple@email.com',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un email';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Rôle',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              items: TenantRole.values
                  .where((r) => r != TenantRole.owner)
                  .map(
                    (r) =>
                        DropdownMenuItem(value: r.value, child: Text(r.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Envoyer invitation'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.emerald,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onInvite(_emailController.text.trim(), _selectedRole);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }
}
