import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
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

class UserMenu extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return PopupMenuButton<_UserMenuAction>(
      tooltip: 'Compte',
      onSelected: (action) {
        switch (action) {
          case _UserMenuAction.changeTenant:
            onChangeTenant();
          case _UserMenuAction.logout:
            onLogout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<_UserMenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName.isEmpty ? user.email : user.displayName),
              Text(
                user.email,
                style: const TextStyle(fontSize: 12, color: AppColors.subtle),
              ),
              Text(
                tenant.tenantName,
                style: const TextStyle(fontSize: 12, color: AppColors.subtle),
              ),
            ],
          ),
        ),
        if (canChangeTenant)
          const PopupMenuItem(
            value: _UserMenuAction.changeTenant,
            child: Text('Changer de société'),
          ),
        const PopupMenuItem(
          value: _UserMenuAction.logout,
          child: Text('Déconnexion'),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.email,
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

enum _UserMenuAction { changeTenant, logout }
