import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/admin_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  AdminDashboardCubit(this._repository) : super(const AdminDashboardInitial());

  final AdminRepository _repository;
  AdminRepository get repository => _repository;

  Future<void> loadDashboard() async {
    emit(const AdminDashboardLoading());
    try {
      final overview = await _repository.loadOverview();
      final tenants = await _repository.loadTenants();
      emit(AdminDashboardLoaded(overview: overview, tenants: tenants));
    } catch (e) {
      emit(AdminDashboardError(e.toString()));
    }
  }

  // Reloads without showing full loading state if we already have data
  Future<void> refresh() async {
    try {
      final overview = await _repository.loadOverview();
      final tenants = await _repository.loadTenants();
      emit(AdminDashboardLoaded(overview: overview, tenants: tenants));
    } catch (e) {
      // Keep existing state or show a snackbar (handled in UI)
    }
  }
}
