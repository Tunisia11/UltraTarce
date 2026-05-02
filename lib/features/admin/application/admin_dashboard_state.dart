import '../data/admin_models.dart';

abstract class AdminDashboardState {
  const AdminDashboardState();
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  const AdminDashboardLoaded({required this.overview, required this.tenants});

  final AdminOverview overview;
  final List<AdminTenantOverview> tenants;
}

class AdminDashboardError extends AdminDashboardState {
  const AdminDashboardError(this.message);
  final String message;
}
