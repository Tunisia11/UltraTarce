import '../../auth/data/auth_models.dart';

class TeamMember {
  const TeamMember({
    required this.id,
    required this.userId,
    required this.tenantId,
    required this.role,
    required this.status,
    this.email,
    this.fullName,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String tenantId;
  final TenantRole role;
  final String status;
  final String? email;
  final String? fullName;
  final DateTime createdAt;

  String get displayName => (fullName != null && fullName!.isNotEmpty)
      ? fullName!
      : (email ?? 'Utilisateur');

  factory TeamMember.fromMap(
    Map<String, dynamic> m, {
    Map<String, dynamic>? profile,
  }) {
    return TeamMember(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      tenantId: m['tenant_id'] as String,
      role: tenantRoleFromValue(m['role']),
      status: m['status'] as String? ?? 'active',
      email: profile?['email'] as String?,
      fullName: profile?['full_name'] as String?,
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class TeamInvite {
  const TeamInvite({
    required this.id,
    required this.tenantId,
    required this.email,
    required this.role,
    required this.status,
    required this.inviteToken,
    this.invitedBy,
    this.expiresAt,
    this.acceptedAt,
    this.cancelledAt,
    required this.createdAt,
    this.tenantName,
  });

  final String id;
  final String tenantId;
  final String email;
  final TenantRole role;
  final String status;
  final String inviteToken;
  final String? invitedBy;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final String? tenantName;

  factory TeamInvite.fromMap(Map<String, dynamic> m) {
    return TeamInvite(
      id: m['id'] as String,
      tenantId: m['tenant_id'] as String,
      email: m['email'] as String,
      role: tenantRoleFromValue(m['role']),
      status: m['status'] as String? ?? 'pending',
      inviteToken: m['invite_token'] as String,
      invitedBy: m['invited_by'] as String?,
      expiresAt: m['expires_at'] != null
          ? DateTime.tryParse(m['expires_at'] as String)
          : null,
      acceptedAt: m['accepted_at'] != null
          ? DateTime.tryParse(m['accepted_at'] as String)
          : null,
      cancelledAt: m['cancelled_at'] != null
          ? DateTime.tryParse(m['cancelled_at'] as String)
          : null,
      createdAt:
          DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
      tenantName: (m['tenants'] as Map<String, dynamic>?)?['name'] as String?,
    );
  }
}
