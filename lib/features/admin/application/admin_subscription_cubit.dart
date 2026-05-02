import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/admin_subscription_repository.dart';
import 'admin_subscription_state.dart';

class AdminSubscriptionCubit extends Cubit<AdminSubscriptionState> {
  AdminSubscriptionCubit(this.repository) : super(AdminSubscriptionInitial());

  final AdminSubscriptionRepository repository;

  Future<void> loadSubscriptions() async {
    emit(AdminSubscriptionLoading());
    try {
      final subs = await repository.loadSubscriptions();
      emit(AdminSubscriptionLoaded(subs));
    } catch (e) {
      emit(AdminSubscriptionError(e.toString()));
    }
  }

  Future<void> updateSubscription({
    required String tenantId,
    required String plan,
    required String status,
    required String billingCycle,
    double? priceTnd,
    int? seatsLimit,
    DateTime? currentPeriodEndsAt,
    String? adminNotes,
  }) async {
    try {
      await repository.updatePlan(
        tenantId: tenantId,
        plan: plan,
        status: status,
        billingCycle: billingCycle,
        priceTnd: priceTnd,
        seatsLimit: seatsLimit,
        currentPeriodEndsAt: currentPeriodEndsAt,
        adminNotes: adminNotes,
      );
      await loadSubscriptions();
    } catch (e) {
      emit(AdminSubscriptionError(e.toString()));
    }
  }
}
