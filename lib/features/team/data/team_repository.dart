import 'package:supabase_flutter/supabase_flutter.dart';
import 'team_models.dart';

class TeamRepository {
  TeamRepository(this._client);

  final SupabaseClient _client;

  /// Load all members of a tenant, merging profile data in Dart.
  Future<List<TeamMember>> loadMembers(String tenantId) async {
    final membersRaw = await _client
        .from('tenant_users')
        .select('id, tenant_id, user_id, role, status, created_at')
        .eq('tenant_id', tenantId);

    final profilesRes = await _client
        .from('profiles')
        .select('id, email, full_name');
    final profileMap = {for (final p in profilesRes) p['id'] as String: p};

    return membersRaw.map((m) {
      final userId = m['user_id'] as String?;
      final profile = userId != null ? profileMap[userId] : null;
      return TeamMember.fromMap(m, profile: profile);
    }).toList();
  }

  /// Load pending invites for a tenant.
  Future<List<TeamInvite>> loadInvites(String tenantId) async {
    final res = await _client
        .from('tenant_invites')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false);
    return res.map((m) => TeamInvite.fromMap(m)).toList();
  }

  /// Create a new invitation.
  Future<TeamInvite> createInvite({
    required String tenantId,
    required String email,
    required String role,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final res = await _client
        .from('tenant_invites')
        .insert({
          'tenant_id': tenantId,
          'email': email.trim().toLowerCase(),
          'role': role,
          'invited_by': userId,
          'expires_at': DateTime.now()
              .add(const Duration(days: 30))
              .toUtc()
              .toIso8601String(),
        })
        .select()
        .single();
    return TeamInvite.fromMap(res);
  }

  /// Cancel an invitation.
  Future<void> cancelInvite(String inviteId) async {
    await _client
        .from('tenant_invites')
        .update({
          'status': 'cancelled',
          'cancelled_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', inviteId);
  }

  /// Update a member's role.
  Future<void> updateMemberRole({
    required String memberId,
    required String newRole,
  }) async {
    await _client
        .from('tenant_users')
        .update({'role': newRole})
        .eq('id', memberId);
  }

  /// Disable a member.
  Future<void> disableMember(String memberId) async {
    await _client
        .from('tenant_users')
        .update({'status': 'disabled'})
        .eq('id', memberId);
  }

  /// Re-enable a member.
  Future<void> enableMember(String memberId) async {
    await _client
        .from('tenant_users')
        .update({'status': 'active'})
        .eq('id', memberId);
  }

  /// Load pending invites for the currently logged-in user's email.
  Future<List<TeamInvite>> loadMyPendingInvites() async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return [];
    final res = await _client
        .from('tenant_invites')
        .select('*, tenants(name)')
        .eq('status', 'pending')
        .ilike('email', email);
    return res.map((m) => TeamInvite.fromMap(m)).toList();
  }

  /// Accept an invite using the SECURITY DEFINER function.
  Future<String> acceptInvite(String inviteToken) async {
    final tenantId = await _client.rpc(
      'accept_tenant_invite',
      params: {'p_invite_token': inviteToken},
    );
    return tenantId as String;
  }

  /// Get current seats usage for a tenant.
  Future<int> getActiveSeatsCount(String tenantId) async {
    final res = await _client
        .from('tenant_users')
        .select('id')
        .eq('tenant_id', tenantId)
        .eq('status', 'active');
    return res.length;
  }

  /// Get the seats limit from tenant_subscriptions.
  Future<int?> getSeatsLimit(String tenantId) async {
    final res = await _client
        .from('tenant_subscriptions')
        .select('seats_limit')
        .eq('tenant_id', tenantId)
        .maybeSingle();
    return res?['seats_limit'] as int?;
  }
}
