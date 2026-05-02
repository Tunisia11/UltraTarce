import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_models.dart';

class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<bool> checkIsPlatformAdmin() async {
    try {
      final res = await _client.rpc('is_platform_admin');
      return res == true;
    } catch (_) {
      return false;
    }
  }

  Future<AdminOverview> loadOverview() async {
    final tenantsRes = await _client
        .from('tenants')
        .select('id, status, created_at');
    final subsRes = await _client.from('tenant_subscriptions').select('status');
    final usersRes = await _client.from('tenant_users').select('id');
    final productsRes = await _client.from('products').select('id');
    final docsRes = await _client.from('documents').select('id, created_at');
    final syncErrorsRes = await _client
        .from('sync_errors')
        .select('id, created_at');
    final syncConflictsRes = await _client.from('sync_conflicts').select('id');

    DateTime? latestActivity;
    for (final doc in docsRes) {
      if (doc['created_at'] != null) {
        final date = DateTime.tryParse(doc['created_at'] as String);
        if (date != null &&
            (latestActivity == null || date.isAfter(latestActivity))) {
          latestActivity = date;
        }
      }
    }

    DateTime? latestError;
    for (final err in syncErrorsRes) {
      if (err['created_at'] != null) {
        final date = DateTime.tryParse(err['created_at'] as String);
        if (date != null &&
            (latestError == null || date.isAfter(latestError))) {
          latestError = date;
        }
      }
    }

    int activeTenants = 0;
    int trialTenants = 0;
    int overdueTenants = 0;
    int suspendedTenants = 0;
    int cancelledTenants = 0;

    for (final s in subsRes) {
      final st = s['status'] as String?;
      if (st == 'active')
        activeTenants++;
      else if (st == 'trial')
        trialTenants++;
      else if (st == 'overdue')
        overdueTenants++;
      else if (st == 'suspended')
        suspendedTenants++;
      else if (st == 'cancelled')
        cancelledTenants++;
    }

    return AdminOverview(
      totalTenants: tenantsRes.length,
      activeTenants: activeTenants,
      trialTenants: trialTenants,
      overdueTenants: overdueTenants,
      suspendedTenants: suspendedTenants,
      cancelledTenants: cancelledTenants,
      totalUsers: usersRes.length,
      totalProducts: productsRes.length,
      totalDocuments: docsRes.length,
      totalSyncErrors: syncErrorsRes.length,
      totalSyncConflicts: syncConflictsRes.length,
      latestActivityTime: latestActivity,
      latestSyncErrorTime: latestError,
    );
  }

  Future<List<AdminTenantOverview>> loadTenants() async {
    final tenants = await _client
        .from('tenants')
        .select('*, tenant_users(user_id, role)');
    final users = await _client.from('profiles').select('id, email');
    final products = await _client.from('products').select('tenant_id');
    final docs = await _client
        .from('documents')
        .select('tenant_id, created_at');
    final errors = await _client
        .from('sync_errors')
        .select('tenant_id, status');

    final userEmailMap = {
      for (final u in users)
        u['id'] as String: u['email'] as String? ?? 'Email non disponible',
    };

    return tenants.map((t) {
      final tenantId = t['id'] as String;

      final tenantUsers = (t['tenant_users'] as List<dynamic>? ?? []);
      String? ownerEmail;
      for (final tu in tenantUsers) {
        if (tu['role'] == 'owner') {
          ownerEmail = userEmailMap[tu['user_id']];
          break;
        }
      }

      final pCount = products.where((p) => p['tenant_id'] == tenantId).length;
      final dList = docs.where((d) => d['tenant_id'] == tenantId).toList();
      final eCount = errors
          .where((e) => e['tenant_id'] == tenantId && e['status'] != 'resolved')
          .length;

      DateTime? lastActivity;
      for (final doc in dList) {
        if (doc['created_at'] != null) {
          final date = DateTime.tryParse(doc['created_at'] as String);
          if (date != null &&
              (lastActivity == null || date.isAfter(lastActivity))) {
            lastActivity = date;
          }
        }
      }

      return AdminTenantOverview(
        tenantId: tenantId,
        tenantName: t['name'] as String? ?? 'Inconnu',
        status: t['status'] as String? ?? 'active',
        ownerEmail: ownerEmail,
        userCount: tenantUsers.length,
        productCount: pCount,
        documentCount: dList.length,
        syncErrorCount: eCount,
        lastActivityDate: lastActivity,
        createdAt: DateTime.parse(t['created_at'] as String),
      );
    }).toList();
  }

  Future<AdminTenantDetail> loadTenantDetail(String tenantId) async {
    final tenant = await _client
        .from('tenants')
        .select()
        .eq('id', tenantId)
        .maybeSingle();
    final company = await _client
        .from('companies')
        .select()
        .eq('tenant_id', tenantId)
        .maybeSingle();
    final subscription = await _client
        .from('tenant_subscriptions')
        .select()
        .eq('tenant_id', tenantId)
        .maybeSingle();

    final tenantUsersRaw = await _client
        .from('tenant_users')
        .select('id, tenant_id, user_id, role, status, created_at')
        .eq('tenant_id', tenantId);

    // Fetch profiles separately – no FK from tenant_users to profiles
    final profilesList = await _client
        .from('profiles')
        .select('id, email, full_name');
    final profileMap = {for (final p in profilesList) p['id'] as String: p};

    // Merge profile data into each tenant_user row
    final tenantUsers = tenantUsersRaw.map((tu) {
      final userId = tu['user_id'] as String?;
      final profile = userId != null ? profileMap[userId] : null;
      return {
        ...tu,
        'profiles': profile ?? {'email': null, 'full_name': null},
      };
    }).toList();

    final productsCount =
        (await _client.from('products').select('id').eq('tenant_id', tenantId))
            .length;
    final partnersCount =
        (await _client.from('partners').select('id').eq('tenant_id', tenantId))
            .length;
    final docsCount =
        (await _client.from('documents').select('id').eq('tenant_id', tenantId))
            .length;
    final paymentsCount =
        (await _client.from('payments').select('id').eq('tenant_id', tenantId))
            .length;
    final stockMovementsCount =
        (await _client
                .from('stock_movements')
                .select('id')
                .eq('tenant_id', tenantId))
            .length;
    final syncErrorsCount =
        (await _client
                .from('sync_errors')
                .select('id')
                .eq('tenant_id', tenantId))
            .length;
    final syncConflictsCount =
        (await _client
                .from('sync_conflicts')
                .select('id')
                .eq('tenant_id', tenantId))
            .length;

    final recentErrors = await _client
        .from('sync_errors')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(20);
    final recentDocs = await _client
        .from('documents')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(20);
    final recentAudit = await _client
        .from('audit_events')
        .select()
        .eq('tenant_id', tenantId)
        .order('created_at', ascending: false)
        .limit(20);

    return AdminTenantDetail(
      tenantInfo: tenant ?? {},
      companyInfo: company ?? {},
      subscriptionInfo: subscription,
      users: tenantUsers,
      counts: {
        'products': productsCount,
        'partners': partnersCount,
        'documents': docsCount,
        'payments': paymentsCount,
        'stock_movements': stockMovementsCount,
        'sync_errors': syncErrorsCount,
        'sync_conflicts': syncConflictsCount,
      },
      recentErrors: recentErrors,
      recentDocuments: recentDocs,
      recentAuditEvents: recentAudit,
    );
  }

  Future<AdminSyncHealth> loadSyncHealth() async {
    final errors = await _client
        .from('sync_errors')
        .select('*, tenants(name)')
        .order('created_at', ascending: false);
    final conflicts = await _client
        .from('sync_conflicts')
        .select('*, tenants(name)')
        .order('created_at', ascending: false);

    final Map<String, List<Map<String, dynamic>>> byTenant = {};
    final Map<String, int> byCode = {};

    for (final e in errors) {
      final tenantId = e['tenant_id'] as String? ?? 'unknown';
      byTenant.putIfAbsent(tenantId, () => []).add(e);

      final code = e['error_code'] as String? ?? 'unknown';
      byCode[code] = (byCode[code] ?? 0) + 1;
    }

    return AdminSyncHealth(
      errorsByTenant: byTenant,
      latestErrors: errors.take(50).toList(),
      latestConflicts: conflicts.take(50).toList(),
      errorsByCode: byCode,
    );
  }
}
