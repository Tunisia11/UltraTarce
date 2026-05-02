import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/team_repository.dart';
import 'team_state.dart';

class TeamCubit extends Cubit<TeamState> {
  TeamCubit(this._repository) : super(const TeamInitial());

  final TeamRepository _repository;

  Future<void> loadTeam(String tenantId) async {
    emit(const TeamLoading());
    try {
      final members = await _repository.loadMembers(tenantId);
      final invites = await _repository.loadInvites(tenantId);
      final seatsUsed = await _repository.getActiveSeatsCount(tenantId);
      final seatsLimit = await _repository.getSeatsLimit(tenantId);
      emit(
        TeamLoaded(
          members: members,
          invites: invites,
          seatsUsed: seatsUsed,
          seatsLimit: seatsLimit,
        ),
      );
    } catch (e) {
      emit(TeamError('Erreur chargement équipe: $e'));
    }
  }

  Future<void> inviteMember({
    required String tenantId,
    required String email,
    required String role,
  }) async {
    try {
      await _repository.createInvite(
        tenantId: tenantId,
        email: email,
        role: role,
      );
      await loadTeam(tenantId);
    } catch (e) {
      emit(TeamError('Erreur invitation: $e'));
    }
  }

  Future<void> cancelInvite({
    required String inviteId,
    required String tenantId,
  }) async {
    try {
      await _repository.cancelInvite(inviteId);
      await loadTeam(tenantId);
    } catch (e) {
      emit(TeamError('Erreur annulation: $e'));
    }
  }

  Future<void> updateMemberRole({
    required String memberId,
    required String newRole,
    required String tenantId,
  }) async {
    try {
      await _repository.updateMemberRole(memberId: memberId, newRole: newRole);
      await loadTeam(tenantId);
    } catch (e) {
      emit(TeamError('Erreur changement rôle: $e'));
    }
  }

  Future<void> disableMember({
    required String memberId,
    required String tenantId,
  }) async {
    try {
      await _repository.disableMember(memberId);
      await loadTeam(tenantId);
    } catch (e) {
      emit(TeamError('Erreur désactivation: $e'));
    }
  }

  Future<void> enableMember({
    required String memberId,
    required String tenantId,
  }) async {
    try {
      await _repository.enableMember(memberId);
      await loadTeam(tenantId);
    } catch (e) {
      emit(TeamError('Erreur réactivation: $e'));
    }
  }

  /// Load pending invites for the current user (for accept flow).
  Future<void> loadMyPendingInvites() async {
    emit(const TeamLoading());
    try {
      final invites = await _repository.loadMyPendingInvites();
      emit(MyInvitesLoaded(invites));
    } catch (e) {
      emit(TeamError('Erreur chargement invitations: $e'));
    }
  }

  Future<void> acceptInvite(String inviteToken) async {
    emit(const TeamLoading());
    try {
      final tenantId = await _repository.acceptInvite(inviteToken);
      emit(InviteAccepted(tenantId));
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('expired') || msg.contains('expirée')) {
        emit(const TeamError('Invitation expirée.'));
      } else if (msg.contains('email mismatch') ||
          msg.contains('wrong email')) {
        emit(
          const TeamError('Cette invitation ne correspond pas à votre email.'),
        );
      } else {
        emit(TeamError('Erreur acceptation: $e'));
      }
    }
  }
}
