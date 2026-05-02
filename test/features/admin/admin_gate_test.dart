import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/admin/presentation/admin_gate.dart';
import 'package:ultra_trace/features/admin/data/admin_models.dart';
import 'package:ultra_trace/features/admin/data/admin_repository.dart';
import 'package:ultra_trace/features/admin/data/admin_subscription_models.dart';
import 'package:ultra_trace/features/admin/data/admin_subscription_repository.dart';

class FakeGateAdminSubscriptionRepository
    implements AdminSubscriptionRepository {
  @override
  Future<List<AdminTenantSubscription>> loadSubscriptions() async => [];

  @override
  Future<AdminTenantSubscription?> loadSubscriptionForTenant(
    String tenantId,
  ) async => null;

  @override
  Future<void> updateStatus({
    required String tenantId,
    required String status,
    String? adminNotes,
  }) async {}

  @override
  Future<void> updatePlan({
    required String tenantId,
    required String plan,
    required String billingCycle,
    double? priceTnd,
    int? seatsLimit,
    DateTime? currentPeriodEndsAt,
    String? adminNotes,
    required String status,
  }) async {}
}

class FakeGateAdminRepository implements AdminRepository {
  FakeGateAdminRepository(this.isAdmin);
  final bool isAdmin;

  @override
  Future<bool> checkIsPlatformAdmin() async => isAdmin;

  @override
  Future<AdminOverview> loadOverview() async {
    return const AdminOverview(
      totalTenants: 0,
      activeTenants: 0,
      totalUsers: 0,
      totalProducts: 0,
      totalDocuments: 0,
      totalSyncErrors: 0,
      totalSyncConflicts: 0,
      trialTenants: 0,
      overdueTenants: 0,
      suspendedTenants: 0,
      cancelledTenants: 0,
    );
  }

  @override
  Future<List<AdminTenantOverview>> loadTenants() async => [];

  @override
  Future<AdminSyncHealth> loadSyncHealth() async {
    return const AdminSyncHealth(
      errorsByTenant: {},
      latestErrors: [],
      latestConflicts: [],
      errorsByCode: {},
    );
  }

  @override
  Future<AdminTenantDetail> loadTenantDetail(String tenantId) async {
    return const AdminTenantDetail(
      tenantInfo: {},
      companyInfo: {},
      users: [],
      counts: {},
      recentErrors: [],
      recentDocuments: [],
      recentAuditEvents: [],
    );
  }
}

void main() {
  group('AdminGate', () {
    testWidgets('shows unauthorized when not admin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminGate(
            repository: FakeGateAdminRepository(false),
            subscriptionRepository: FakeGateAdminSubscriptionRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Accès administrateur non autorisé.'), findsOneWidget);
    });

    testWidgets('shows AdminShell when admin', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdminGate(
            repository: FakeGateAdminRepository(true),
            subscriptionRepository: FakeGateAdminSubscriptionRepository(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Administration Virex'), findsWidgets);
      expect(find.text('Vue générale'), findsWidgets);
    });
  });
}
