import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_colors.dart';
import '../../auth/data/auth_models.dart';
import '../../permissions/tenant_permissions.dart';
import '../application/team_cubit.dart';
import '../application/team_state.dart';
import '../data/team_repository.dart';
import 'invite_member_dialog.dart';
import 'team_member_card.dart';

class TeamPage extends StatefulWidget {
  const TeamPage({
    super.key,
    required this.tenantId,
    required this.currentRole,
  });

  final String tenantId;
  final TenantRole currentRole;

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  late final TeamCubit _cubit;
  late final TenantPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = TenantPermissions(widget.currentRole);
    _cubit = TeamCubit(TeamRepository(Supabase.instance.client));
    _cubit.loadTeam(widget.tenantId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceHighest,
          title: const Text('Équipe'),
          actions: [
            if (_permissions.canManageTeam)
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Inviter un membre',
                onPressed: _showInviteDialog,
              ),
          ],
        ),
        body: BlocBuilder<TeamCubit, TeamState>(
          builder: (context, state) {
            if (state is TeamLoading || state is TeamInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is TeamError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _cubit.loadTeam(widget.tenantId),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }
            if (state is TeamLoaded) {
              return _buildTeamContent(state);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildTeamContent(TeamLoaded state) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Seats info
        if (state.seatsLimit != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: state.seatsLimitReached
                  ? AppColors.danger.withValues(alpha: .08)
                  : AppColors.primaryContainer.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: state.seatsLimitReached
                    ? AppColors.danger.withValues(alpha: .3)
                    : AppColors.primaryContainer.withValues(alpha: .3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  state.seatsLimitReached ? Icons.warning : Icons.people,
                  color: state.seatsLimitReached
                      ? AppColors.danger
                      : AppColors.primaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  '${state.seatsUsed} / ${state.seatsLimit} utilisateurs actifs',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: state.seatsLimitReached
                        ? AppColors.danger
                        : AppColors.ink,
                  ),
                ),
                if (state.seatsLimitReached) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Limite atteinte',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Members section
        Text(
          'Membres (${state.activeMembers.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 12),
        ...state.members.map(
          (member) => TeamMemberCard(
            member: member,
            canManage: _permissions.canManageTeam,
            isCurrentUser:
                member.userId == Supabase.instance.client.auth.currentUser?.id,
            onChangeRole: _permissions.canManageTeam
                ? (newRole) => _cubit.updateMemberRole(
                    memberId: member.id,
                    newRole: newRole,
                    tenantId: widget.tenantId,
                  )
                : null,
            onToggleStatus: _permissions.canManageTeam
                ? () {
                    if (member.status == 'active') {
                      _cubit.disableMember(
                        memberId: member.id,
                        tenantId: widget.tenantId,
                      );
                    } else {
                      _cubit.enableMember(
                        memberId: member.id,
                        tenantId: widget.tenantId,
                      );
                    }
                  }
                : null,
          ),
        ),

        // Invites section
        if (_permissions.canViewTeam && state.pendingInvites.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'Invitations en attente (${state.pendingInvites.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          ...state.pendingInvites.map(
            (invite) => Card(
              elevation: 0,
              color: AppColors.surfaceLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.warning,
                  child: Icon(
                    Icons.mail_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(invite.email),
                subtitle: Text('Rôle : ${invite.role.label}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copier le code',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: invite.inviteToken),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copié !')),
                        );
                      },
                    ),
                    if (_permissions.canManageTeam)
                      IconButton(
                        icon: const Icon(
                          Icons.cancel,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        tooltip: 'Annuler',
                        onPressed: () => _cubit.cancelInvite(
                          inviteId: invite.id,
                          tenantId: widget.tenantId,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showInviteDialog() {
    final currentState = _cubit.state;
    if (currentState is TeamLoaded && currentState.seatsLimitReached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limite utilisateurs atteinte pour ce plan.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (_) => InviteMemberDialog(
        onInvite: (email, role) {
          _cubit.inviteMember(
            tenantId: widget.tenantId,
            email: email,
            role: role,
          );
        },
      ),
    );
  }
}
