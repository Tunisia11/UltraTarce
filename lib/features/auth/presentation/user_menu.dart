import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_colors.dart';
import '../../admin/presentation/admin_gate.dart';
import '../../team/presentation/pending_invites_page.dart';
import '../data/auth_models.dart';

class TenantWorkspaceShell extends StatelessWidget {
  const TenantWorkspaceShell({
    super.key,
    required this.user,
    required this.tenant,
    required this.memberships,
    required this.onLogout,
    required this.onChangeTenant,
    required this.child,
  });

  final AppUser user;
  final TenantMembership tenant;
  final List<TenantMembership> memberships;
  final VoidCallback onLogout;
  final VoidCallback onChangeTenant;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.surfaceLowest,
          elevation: .5,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 44,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        tenant.tenantName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    UserMenu(
                      user: user,
                      tenant: tenant,
                      canChangeTenant: memberships.length > 1,
                      onLogout: onLogout,
                      onChangeTenant: onChangeTenant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class UserMenu extends StatefulWidget {
  const UserMenu({
    super.key,
    required this.user,
    required this.tenant,
    required this.canChangeTenant,
    required this.onLogout,
    required this.onChangeTenant,
  });

  final AppUser user;
  final TenantMembership tenant;
  final bool canChangeTenant;
  final VoidCallback onLogout;
  final VoidCallback onChangeTenant;

  @override
  State<UserMenu> createState() => _UserMenuState();
}

class _UserMenuState extends State<UserMenu> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    // Check if the user is a platform admin using a lightweight RPC or repository
    try {
      final res = await Supabase.instance.client.rpc('is_platform_admin');
      if (mounted) {
        setState(() {
          _isAdmin = res == true;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'Compte',
      onSelected: (action) {
        switch (action) {
          case _UserMenuAction.changeTenant:
            widget.onChangeTenant();
          case _UserMenuAction.logout:
            widget.onLogout();
          case _UserMenuAction.adminVirex:
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminGate()));
          case _UserMenuAction.pendingInvites:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PendingInvitesPage()),
            );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_UserMenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.user.displayName.isEmpty
                    ? widget.user.email
                    : widget.user.displayName,
              ),
              Text(
                widget.user.email,
                style: const TextStyle(fontSize: 12, color: AppColors.subtle),
              ),
              Text(
                widget.tenant.tenantName,
                style: const TextStyle(fontSize: 12, color: AppColors.subtle),
              ),
            ],
          ),
        ),
        if (widget.canChangeTenant)
          const PopupMenuItem(
            value: _UserMenuAction.changeTenant,
            child: Text('Changer de société'),
          ),
        if (_isAdmin)
          const PopupMenuItem(
            value: _UserMenuAction.adminVirex,
            child: Text(
              'Admin Virex',
              style: TextStyle(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const PopupMenuItem(
          value: _UserMenuAction.logout,
          child: Text('Déconnexion'),
        ),
        const PopupMenuItem(
          value: _UserMenuAction.pendingInvites,
          child: Text('Mes invitations'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.user.email,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.account_circle_outlined, size: 22),
        ],
      ),
    );
  }
}

enum _UserMenuAction { changeTenant, logout, adminVirex, pendingInvites }
