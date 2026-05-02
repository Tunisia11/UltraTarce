import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../storage/app_storage.dart';
import '../../../storage/app_storage_keys.dart';

class SubscriptionStatusModel {
  const SubscriptionStatusModel({
    required this.status,
    required this.plan,
    this.trialEndsAt,
    this.currentPeriodEndsAt,
  });

  final String status;
  final String plan;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEndsAt;
}

class SubscriptionStatusRepository {
  SubscriptionStatusRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<SubscriptionStatusModel?> checkStatus(String tenantId) async {
    try {
      final res = await _client
          .from('tenant_subscriptions')
          .select('status, plan, trial_ends_at, current_period_ends_at')
          .eq('tenant_id', tenantId)
          .maybeSingle();

      if (res != null) {
        final status = res['status'] as String? ?? 'active';
        final plan = res['plan'] as String? ?? 'pilot';
        final trialEnds = res['trial_ends_at'] != null
            ? DateTime.parse(res['trial_ends_at'] as String)
            : null;
        final periodEnds = res['current_period_ends_at'] != null
            ? DateTime.parse(res['current_period_ends_at'] as String)
            : null;

        // Cache locally
        writePersistentValue(
          '${subscriptionStatusStorageKey}_$tenantId',
          status,
        );
        writePersistentValue('${subscriptionPlanStorageKey}_$tenantId', plan);
        if (trialEnds != null)
          writePersistentValue(
            '${subscriptionTrialEndStorageKey}_$tenantId',
            trialEnds.toIso8601String(),
          );
        if (periodEnds != null)
          writePersistentValue(
            '${subscriptionPeriodEndStorageKey}_$tenantId',
            periodEnds.toIso8601String(),
          );

        return SubscriptionStatusModel(
          status: status,
          plan: plan,
          trialEndsAt: trialEnds,
          currentPeriodEndsAt: periodEnds,
        );
      } else {
        // Missing row means pilot mode by default
        return const SubscriptionStatusModel(status: 'active', plan: 'pilot');
      }
    } catch (_) {
      // Network error or offline
      return _loadFromCache(tenantId);
    }
  }

  SubscriptionStatusModel? _loadFromCache(String tenantId) {
    final status = readPersistentValue(
      '${subscriptionStatusStorageKey}_$tenantId',
    );
    if (status == null) return null; // No cache, return null so gate handles it

    final plan =
        readPersistentValue('${subscriptionPlanStorageKey}_$tenantId') ??
        'pilot';
    final tStr = readPersistentValue(
      '${subscriptionTrialEndStorageKey}_$tenantId',
    );
    final pStr = readPersistentValue(
      '${subscriptionPeriodEndStorageKey}_$tenantId',
    );

    return SubscriptionStatusModel(
      status: status,
      plan: plan,
      trialEndsAt: tStr != null ? DateTime.tryParse(tStr) : null,
      currentPeriodEndsAt: pStr != null ? DateTime.tryParse(pStr) : null,
    );
  }
}
