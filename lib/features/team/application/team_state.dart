import '../data/team_models.dart';

abstract class TeamState {
  const TeamState();
}

class TeamInitial extends TeamState {
  const TeamInitial();
}

class TeamLoading extends TeamState {
  const TeamLoading();
}

class TeamLoaded extends TeamState {
  const TeamLoaded({
    required this.members,
    required this.invites,
    this.seatsUsed = 0,
    this.seatsLimit,
  });

  final List<TeamMember> members;
  final List<TeamInvite> invites;
  final int seatsUsed;
  final int? seatsLimit;

  List<TeamMember> get activeMembers =>
      members.where((m) => m.status == 'active').toList();

  List<TeamInvite> get pendingInvites =>
      invites.where((i) => i.status == 'pending').toList();

  bool get seatsLimitReached => seatsLimit != null && seatsUsed >= seatsLimit!;
}

class TeamError extends TeamState {
  const TeamError(this.message);
  final String message;
}

// ── Invite acceptance states ──

class MyInvitesLoaded extends TeamState {
  const MyInvitesLoaded(this.invites);
  final List<TeamInvite> invites;
}

class InviteAccepted extends TeamState {
  const InviteAccepted(this.tenantId);
  final String tenantId;
}
