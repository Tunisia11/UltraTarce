import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/admin/application/admin_dashboard_cubit.dart';
import 'package:ultra_trace/features/admin/application/admin_dashboard_state.dart';
import 'package:ultra_trace/features/admin/data/admin_models.dart';
import 'package:ultra_trace/features/admin/data/admin_repository.dart';

class FakeAdminRepository implements AdminRepository {
  @override
  Future<bool> checkIsPlatformAdmin() async => true;

  @override
  Future<AdminOverview> loadOverview() async {
    return const AdminOverview(
      totalTenants: 5,
      activeTenants: 4,
      totalUsers: 10,
      totalProducts: 50,
      totalDocuments: 100,
      totalSyncErrors: 2,
      totalSyncConflicts: 0,
      trialTenants: 1,
      overdueTenants: 0,
      suspendedTenants: 0,
      cancelledTenants: 0,
    );
  }

  @override
  Future<List<AdminTenantOverview>> loadTenants() async {
    return [
      AdminTenantOverview(
        tenantId: 't1',
        tenantName: 'Tenant 1',
        status: 'active',
        userCount: 2,
        productCount: 10,
        documentCount: 20,
        syncErrorCount: 0,
        createdAt: DateTime(2025),
      ),
    ];
  }

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
  group('AdminDashboardCubit', () {
    late AdminDashboardCubit cubit;
    late FakeAdminRepository repository;

    setUp(() {
      repository = FakeAdminRepository();
      cubit = AdminDashboardCubit(repository as AdminRepository);
    });

    test('initial state is AdminDashboardInitial', () {
      expect(cubit.state, isA<AdminDashboardInitial>());
    });

    test('loadDashboard emits loading then loaded', () async {
      final future = cubit.loadDashboard();
      expect(cubit.state, isA<AdminDashboardLoading>());

      await future;

      expect(cubit.state, isA<AdminDashboardLoaded>());
      final loadedState = cubit.state as AdminDashboardLoaded;
      expect(loadedState.overview.totalTenants, 5);
      expect(loadedState.tenants.length, 1);
    });
  });
}
