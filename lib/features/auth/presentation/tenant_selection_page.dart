import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../data/auth_models.dart';

class TenantSelectionPage extends StatefulWidget {
  const TenantSelectionPage({
    super.key,
    required this.user,
    required this.memberships,
    required this.onSelectTenant,
    required this.onCreateTenant,
    required this.onLogout,
    this.message,
    this.companyName,
  });

  final AppUser user;
  final List<TenantMembership> memberships;
  final ValueChanged<TenantMembership> onSelectTenant;
  final ValueChanged<String> onCreateTenant;
  final VoidCallback onLogout;
  final String? message;
  final String? companyName;

  @override
  State<TenantSelectionPage> createState() => _TenantSelectionPageState();
}

class _TenantSelectionPageState extends State<TenantSelectionPage> {
  late final TextEditingController _companyController;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.companyName);
  }

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir une société'),
        actions: [
          TextButton(
            onPressed: widget.onLogout,
            child: const Text('Déconnexion'),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.user.displayName.isEmpty
                      ? widget.user.email
                      : widget.user.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (widget.message != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.message!,
                    style: const TextStyle(color: AppColors.warning),
                  ),
                ],
                const SizedBox(height: 20),
                if (widget.memberships.isNotEmpty)
                  Expanded(
                    child: ListView.separated(
                      itemCount: widget.memberships.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final membership = widget.memberships[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: AppColors.border.withValues(alpha: .35),
                            ),
                          ),
                          title: Text(membership.tenantName),
                          subtitle: Text(membership.role.label),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onSelectTenant(membership),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.message != null)
                          Text(
                            widget.message!,
                            style: const TextStyle(color: AppColors.warning),
                          )
                        else
                          const Text(
                            'Aucune société n’est encore liée à ce compte.',
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _companyController,
                          decoration: const InputDecoration(
                            labelText: 'Nom de société',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              widget.onCreateTenant(_companyController.text),
                          child: Text(
                            widget.message != null
                                ? 'Réessayer la création de société'
                                : 'Créer votre société',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
