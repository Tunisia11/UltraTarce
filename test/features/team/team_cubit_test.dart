import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/team/application/team_cubit.dart';
import 'package:ultra_trace/features/team/application/team_state.dart';
import 'package:ultra_trace/features/team/data/team_models.dart';
import 'package:ultra_trace/features/team/data/team_repository.dart';
import 'package:ultra_trace/features/auth/data/auth_models.dart';

class FakeTeamRepository implements TeamRepository {
  List<TeamMember> members = [];
  List<TeamInvite> invites = [];
  int seatsCount = 1;
  int? seatsLimit;
  bool shouldThrow = false;
  TeamInvite? createdInvite;

  @override
  Future<List<TeamMember>> loadMembers(String tenantId) async {
    if (shouldThrow) throw Exception('network error');
    return members;
  }

  @override
  Future<List<TeamInvite>> loadInvites(String tenantId) async {
    if (shouldThrow) throw Exception('network error');
    return invites;
  }

  @override
  Future<TeamInvite> createInvite({
    required String tenantId,
    required String email,
    required String role,
  }) async {
    final invite = TeamInvite(
      id: 'inv-1',
      tenantId: tenantId,
      email: email,
      role: tenantRoleFromValue(role),
      status: 'pending',
      inviteToken: 'token-abc',
      createdAt: DateTime.now(),
    );
    createdInvite = invite;
    invites = [...invites, invite];
    return invite;
  }

  @override
  Future<void> cancelInvite(String inviteId) async {
    invites = invites.where((i) => i.id != inviteId).toList();
  }

  @override
  Future<void> updateMemberRole({
    required String memberId,
    required String newRole,
  }) async {}

  @override
  Future<void> disableMember(String memberId) async {}

  @override
  Future<void> enableMember(String memberId) async {}

  @override
  Future<List<TeamInvite>> loadMyPendingInvites() async => invites;

  @override
  Future<String> acceptInvite(String inviteToken) async => 'tenant-123';

  @override
  Future<int> getActiveSeatsCount(String tenantId) async => seatsCount;

  @override
  Future<int?> getSeatsLimit(String tenantId) async => seatsLimit;
}

void main() {
  group('TeamCubit', () {
    late TeamCubit cubit;
    late FakeTeamRepository repo;

    setUp(() {
      repo = FakeTeamRepository();
      repo.members = [
        TeamMember(
          id: 'm1',
          userId: 'u1',
          tenantId: 't1',
          role: TenantRole.owner,
          status: 'active',
          email: 'owner@test.com',
          createdAt: DateTime(2025),
        ),
      ];
      cubit = TeamCubit(repo);
    });

    tearDown(() => cubit.close());

    test('loadTeam emits TeamLoaded with members', () async {
      await cubit.loadTeam('t1');
      expect(cubit.state, isA<TeamLoaded>());
      final loaded = cubit.state as TeamLoaded;
      expect(loaded.members.length, 1);
      expect(loaded.members.first.email, 'owner@test.com');
    });

    test('inviteMember creates invite and reloads', () async {
      await cubit.loadTeam('t1');
      await cubit.inviteMember(
        tenantId: 't1',
        email: 'newuser@test.com',
        role: 'cashier',
      );
      expect(cubit.state, isA<TeamLoaded>());
      final loaded = cubit.state as TeamLoaded;
      expect(loaded.invites.length, 1);
      expect(repo.createdInvite?.email, 'newuser@test.com');
    });

    test('loadTeam handles error', () async {
      repo.shouldThrow = true;
      await cubit.loadTeam('t1');
      expect(cubit.state, isA<TeamError>());
    });

    test('acceptInvite emits InviteAccepted', () async {
      await cubit.acceptInvite('token-abc');
      expect(cubit.state, isA<InviteAccepted>());
      final accepted = cubit.state as InviteAccepted;
      expect(accepted.tenantId, 'tenant-123');
    });

    test('seats limit is forwarded', () async {
      repo.seatsLimit = 5;
      repo.seatsCount = 5;
      await cubit.loadTeam('t1');
      final loaded = cubit.state as TeamLoaded;
      expect(loaded.seatsLimitReached, isTrue);
    });
  });
}
