import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/subscription_status_repository.dart';
import 'subscription_gate_state.dart';

class SubscriptionGateCubit extends Cubit<SubscriptionGateState> {
  SubscriptionGateCubit({required this.tenantId, required this.repository})
    : super(SubscriptionGateLoading());

  final String tenantId;
  final SubscriptionStatusRepository repository;

  Future<void> checkSubscription() async {
    emit(SubscriptionGateLoading());

    final statusModel = await repository.checkStatus(tenantId);

    if (statusModel == null) {
      // Offline and no cache. Allow pilot mode with offline flag
      emit(
        const SubscriptionGateAllowed(
          status: SubscriptionStatusModel(status: 'active', plan: 'pilot'),
          isOfflineFallback: true,
        ),
      );
      return;
    }

    if (statusModel.status == 'suspended' ||
        statusModel.status == 'cancelled') {
      emit(SubscriptionGateBlocked(statusModel));
    } else {
      emit(SubscriptionGateAllowed(status: statusModel));
    }
  }
}
