import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/app_repository.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/metrics_service.dart';

class DashboardState {
  const DashboardState({
    required this.dailySales,
    required this.monthlySales,
    required this.lowStockCount,
    required this.unpaidAmount,
    required this.draftDocuments,
    required this.bestSellers,
  });

  factory DashboardState.initial() => const DashboardState(
    dailySales: 0,
    monthlySales: 0,
    lowStockCount: 0,
    unpaidAmount: 0,
    draftDocuments: [],
    bestSellers: [],
  );

  final double dailySales;
  final double monthlySales;
  final int lowStockCount;
  final double unpaidAmount;
  final List<BusinessDocument> draftDocuments;
  final List<MapEntry<Product, int>> bestSellers;
}

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._appRepository) : super(DashboardState.initial());

  final AppRepository _appRepository;

  void loadDashboard() => refreshDashboard();

  void refreshDashboard() {
    final snapshot = _appRepository.snapshot;
    final metrics = MetricsService.dashboardMetrics(
      documents: snapshot.documents,
      products: snapshot.products,
    );
    emit(
      DashboardState(
        dailySales: metrics.dailySales,
        monthlySales: metrics.monthlySales,
        lowStockCount: metrics.lowStockCount,
        unpaidAmount: metrics.unpaidAmount,
        draftDocuments: MetricsService.draftDocuments(snapshot.documents),
        bestSellers: MetricsService.bestSellers(
          snapshot.documents,
          snapshot.products,
        ),
      ),
    );
  }
}
