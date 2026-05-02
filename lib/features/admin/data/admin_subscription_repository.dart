import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_subscription_models.dart';

class AdminSubscriptionRepository {
  AdminSubscriptionRepository(this._client);

  final SupabaseClient _client;

  Future<List<AdminTenantSubscription>> loadSubscriptions() async {
    final res = await _client
        .from('tenant_subscriptions')
        .select('*, tenants(name, tenant_users(user_id, role))');

    final usersRes = await _client.from('profiles').select('id, full_name');
    final userMap = {
      for (final u in usersRes) u['id'] as String: u['full_name'] as String?,
    };

    final docs = await _client
        .from('documents')
        .select('tenant_id, created_at');

    return res.map((row) {
      final tenantInfo = row['tenants'] as Map<String, dynamic>? ?? {};
      final tenantUsers = tenantInfo['tenant_users'] as List<dynamic>? ?? [];

      String? ownerEmail;
      for (final tu in tenantUsers) {
        if (tu['role'] == 'owner') {
          ownerEmail = userMap[tu['user_id']];
          break;
        }
      }

      final tenantId = row['tenant_id'] as String;
      final tDocs = docs.where((d) => d['tenant_id'] == tenantId).toList();
      DateTime? lastActivity;
      for (final d in tDocs) {
        if (d['created_at'] != null) {
          final date = DateTime.tryParse(d['created_at'] as String);
          if (date != null &&
              (lastActivity == null || date.isAfter(lastActivity))) {
            lastActivity = date;
          }
        }
      }

      return AdminTenantSubscription(
        id: row['id'] as String,
        tenantId: tenantId,
        tenantName: tenantInfo['name'] as String? ?? 'Inconnu',
        plan: row['plan'] as String,
        status: row['status'] as String,
        billingCycle: row['billing_cycle'] as String,
        priceTnd: (row['price_tnd'] as num?)?.toDouble(),
        seatsLimit: row['seats_limit'] as int?,
        trialStartedAt: row['trial_started_at'] != null
            ? DateTime.parse(row['trial_started_at'] as String)
            : null,
        trialEndsAt: row['trial_ends_at'] != null
            ? DateTime.parse(row['trial_ends_at'] as String)
            : null,
        currentPeriodStartedAt: row['current_period_started_at'] != null
            ? DateTime.parse(row['current_period_started_at'] as String)
            : null,
        currentPeriodEndsAt: row['current_period_ends_at'] != null
            ? DateTime.parse(row['current_period_ends_at'] as String)
            : null,
        suspendedAt: row['suspended_at'] != null
            ? DateTime.parse(row['suspended_at'] as String)
            : null,
        cancelledAt: row['cancelled_at'] != null
            ? DateTime.parse(row['cancelled_at'] as String)
            : null,
        adminNotes: row['admin_notes'] as String?,
        updatedAt: DateTime.parse(row['updated_at'] as String),
        updatedBy: row['updated_by'] as String?,
        ownerEmail: ownerEmail,
        userCount: tenantUsers.length,
        documentCount: tDocs.length,
        lastActivityDate: lastActivity,
      );
    }).toList();
  }

  Future<AdminTenantSubscription?> loadSubscriptionForTenant(
    String tenantId,
  ) async {
    final subs = await loadSubscriptions();
    for (final s in subs) {
      if (s.tenantId == tenantId) return s;
    }
    return null;
  }

  Future<void> updateStatus({
    required String tenantId,
    required String status,
    String? adminNotes,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updated_by': _client.auth.currentUser?.id,
    };
    if (adminNotes != null) updates['admin_notes'] = adminNotes;
    if (status == 'suspended') {
      updates['suspended_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (status == 'cancelled') {
      updates['cancelled_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await _client
        .from('tenant_subscriptions')
        .update(updates)
        .eq('tenant_id', tenantId);
  }

  Future<void> updatePlan({
    required String tenantId,
    required String plan,
    required String billingCycle,
    double? priceTnd,
    int? seatsLimit,
    DateTime? currentPeriodEndsAt,
    String? adminNotes,
    required String status,
  }) async {
    final updates = <String, dynamic>{
      'plan': plan,
      'billing_cycle': billingCycle,
      'price_tnd': priceTnd,
      'seats_limit': seatsLimit,
      'current_period_ends_at': currentPeriodEndsAt?.toUtc().toIso8601String(),
      'updated_by': _client.auth.currentUser?.id,
      'status': status,
    };
    if (adminNotes != null) updates['admin_notes'] = adminNotes;

    if (status == 'suspended') {
      updates['suspended_at'] = DateTime.now().toUtc().toIso8601String();
    }
    if (status == 'cancelled') {
      updates['cancelled_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await _client.from('tenant_subscriptions').upsert({
      'tenant_id': tenantId,
      ...updates,
    }, onConflict: 'tenant_id');
  }
}
