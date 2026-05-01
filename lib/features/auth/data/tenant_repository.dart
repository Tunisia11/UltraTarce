import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_config.dart';
import '../../../app/tenant_context.dart';
import '../../../storage/app_storage.dart';
import '../../../storage/app_storage_keys.dart';
import 'auth_models.dart';

abstract class TenantRepository {
  Future<List<TenantMembership>> loadMemberships(AppUser user);

  Future<TenantMembership> createFirstTenant({
    required AppUser user,
    required String companyName,
  });

  Future<void> storeSelectedTenant({
    required AppUser user,
    required TenantMembership tenant,
  });

  TenantMembership? loadSelectedTenant(AppUser user);

  Future<void> clearSelectedTenant();
}

class SupabaseTenantRepository implements TenantRepository {
  SupabaseTenantRepository({required AppConfig config, SupabaseClient? client})
    : _config = config,
      _client = client ?? _safeClient();

  final AppConfig _config;
  final SupabaseClient? _client;

  static const localWorkspaceMode = TenantContext.localWorkspaceMode;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<TenantMembership>> loadMemberships(AppUser user) async {
    if (_config.authBypassEnabled || user.isDevBypass) {
      return [
        const TenantMembership(
          tenantId: TenantContext.devBypassTenantId,
          tenantName: TenantContext.devBypassTenantName,
          role: TenantRole.owner,
        ),
      ];
    }
    final client = _requireClient();
    final rows = await client
        .from('tenant_users')
        .select(
          'tenant_id, role, status, tenants(id, name, legal_name, status)',
        )
        .eq('user_id', user.id)
        .eq('status', 'active');
    return [
      for (final row in rows as List)
        _membershipFromRow(Map<String, dynamic>.from(row as Map)),
    ];
  }

  @override
  Future<TenantMembership> createFirstTenant({
    required AppUser user,
    required String companyName,
  }) async {
    final name = companyName.trim().isEmpty
        ? 'Nouvelle société'
        : companyName.trim();
    if (_config.authBypassEnabled || user.isDevBypass) {
      return TenantMembership(
        tenantId: TenantContext.devBypassTenantId,
        tenantName: name,
        role: TenantRole.owner,
      );
    }
    final client = _requireClient();
    final tenant = await client
        .from('tenants')
        .insert({'name': name, 'owner_user_id': user.id, 'status': 'active'})
        .select('id, name, legal_name, status')
        .single();
    final tenantId = tenant['id'] as String;
    await client.from('profiles').upsert({
      'id': user.id,
      'full_name': user.displayName,
    });
    await client.from('tenant_users').insert({
      'tenant_id': tenantId,
      'user_id': user.id,
      'role': TenantRole.owner.value,
      'status': 'active',
    });
    return TenantMembership(
      tenantId: tenantId,
      tenantName: tenant['name'] as String? ?? name,
      legalName: tenant['legal_name'] as String? ?? '',
      role: TenantRole.owner,
      status: tenant['status'] as String? ?? 'active',
    );
  }

  @override
  Future<void> storeSelectedTenant({
    required AppUser user,
    required TenantMembership tenant,
  }) async {
    writePersistentValue(selectedTenantIdStorageKey, tenant.tenantId);
    writePersistentValue(selectedTenantNameStorageKey, tenant.tenantName);
    writePersistentValue(selectedUserIdStorageKey, user.id);
    writePersistentValue(localWorkspaceModeStorageKey, localWorkspaceMode);
  }

  @override
  TenantMembership? loadSelectedTenant(AppUser user) {
    final selectedUserId = readPersistentValue(selectedUserIdStorageKey);
    if (selectedUserId != user.id) return null;
    final tenantId = readPersistentValue(selectedTenantIdStorageKey);
    final tenantName = readPersistentValue(selectedTenantNameStorageKey);
    if (tenantId == null || tenantId.isEmpty) return null;
    return TenantMembership(
      tenantId: tenantId,
      tenantName: tenantName?.isNotEmpty == true ? tenantName! : 'Société',
      role: TenantRole.owner,
    );
  }

  @override
  Future<void> clearSelectedTenant() async {
    deletePersistentValue(selectedTenantIdStorageKey);
    deletePersistentValue(selectedTenantNameStorageKey);
    deletePersistentValue(selectedUserIdStorageKey);
  }

  TenantMembership _membershipFromRow(Map<String, dynamic> row) {
    final tenant = Map<String, dynamic>.from(
      row['tenants'] as Map? ?? const {},
    );
    return TenantMembership(
      tenantId: row['tenant_id'] as String? ?? tenant['id'] as String? ?? '',
      tenantName: tenant['name'] as String? ?? 'Société',
      legalName: tenant['legal_name'] as String? ?? '',
      role: tenantRoleFromValue(row['role']),
      status:
          row['status'] as String? ?? tenant['status'] as String? ?? 'active',
    );
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw const AuthRepositoryException(
        'Supabase n’est pas initialisé. Vérifiez la configuration.',
      );
    }
    return client;
  }
}
