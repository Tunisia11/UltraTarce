import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_colors.dart';
import '../../auth/data/auth_models.dart';
import '../application/team_cubit.dart';
import '../application/team_state.dart';
import '../data/team_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Page where a user sees their pending invitations and can accept them.
class PendingInvitesPage extends StatefulWidget {
  const PendingInvitesPage({super.key, this.onAccepted});

  final void Function(String tenantId)? onAccepted;

  @override
  State<PendingInvitesPage> createState() => _PendingInvitesPageState();
}

class _PendingInvitesPageState extends State<PendingInvitesPage> {
  late final TeamCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = TeamCubit(TeamRepository(Supabase.instance.client));
    _cubit.loadMyPendingInvites();
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
          title: const Text('Mes invitations'),
        ),
        body: BlocConsumer<TeamCubit, TeamState>(
          listener: (context, state) {
            if (state is InviteAccepted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Invitation acceptée ! Rechargez la liste des sociétés.',
                  ),
                  backgroundColor: AppColors.emerald,
                ),
              );
              widget.onAccepted?.call(state.tenantId);
              Navigator.of(context).pop();
            }
            if (state is TeamError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.danger,
                ),
              );
              _cubit.loadMyPendingInvites();
            }
          },
          builder: (context, state) {
            if (state is TeamLoading || state is TeamInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MyInvitesLoaded) {
              if (state.invites.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucune invitation en attente.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: state.invites.length,
                itemBuilder: (context, index) {
                  final invite = state.invites[index];
                  return Card(
                    elevation: 0,
                    color: AppColors.surfaceLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.primaryContainer,
                        child: Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(invite.tenantName ?? 'Société'),
                      subtitle: Text(
                        'Rôle : ${invite.role.label}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () =>
                            _cubit.acceptInvite(invite.inviteToken),
                        child: const Text('Accepter'),
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
