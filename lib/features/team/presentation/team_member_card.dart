import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../../auth/data/auth_models.dart';
import '../data/team_models.dart';

class TeamMemberCard extends StatelessWidget {
  const TeamMemberCard({
    super.key,
    required this.member,
    required this.canManage,
    required this.isCurrentUser,
    this.onChangeRole,
    this.onToggleStatus,
  });

  final TeamMember member;
  final bool canManage;
  final bool isCurrentUser;
  final void Function(String newRole)? onChangeRole;
  final VoidCallback? onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final isDisabled = member.status == 'disabled';
    final isOwner = member.role == TenantRole.owner;

    return Card(
      elevation: 0,
      color: isDisabled
          ? AppColors.surfaceLowest.withValues(alpha: .5)
          : AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDisabled
              ? AppColors.border.withValues(alpha: .3)
              : AppColors.border,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _roleColor(member.role),
          child: Text(
            member.displayName[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: isDisabled ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Vous',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            _RoleBadge(role: member.role),
            if (isDisabled) ...[
              const SizedBox(width: 8),
              const _StatusBadge(status: 'disabled'),
            ],
            if (member.email != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  member.email!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ],
        ),
        trailing: canManage && !isCurrentUser && !isOwner
            ? PopupMenuButton<String>(
                itemBuilder: (context) => [
                  ...TenantRole.values
                      .where((r) => r != TenantRole.owner)
                      .map(
                        (r) =>
                            PopupMenuItem(value: r.value, child: Text(r.label)),
                      ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: isDisabled ? '_enable' : '_disable',
                    child: Text(
                      isDisabled ? 'Réactiver' : 'Désactiver',
                      style: TextStyle(
                        color: isDisabled
                            ? AppColors.emerald
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == '_disable' || value == '_enable') {
                    onToggleStatus?.call();
                  } else {
                    onChangeRole?.call(value);
                  }
                },
              )
            : null,
      ),
    );
  }

  Color _roleColor(TenantRole role) {
    switch (role) {
      case TenantRole.owner:
        return AppColors.primaryContainer;
      case TenantRole.manager:
        return AppColors.cyan;
      case TenantRole.cashier:
        return AppColors.emerald;
      case TenantRole.stockManager:
        return Colors.orange;
      case TenantRole.accountant:
        return Colors.purple;
      case TenantRole.readOnly:
        return AppColors.muted;
    }
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final TenantRole role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        role.label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Désactivé',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.danger,
        ),
      ),
    );
  }
}
