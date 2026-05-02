import '../data/subscription_status_repository.dart';

abstract class SubscriptionGateState {
  const SubscriptionGateState();
}

class SubscriptionGateLoading extends SubscriptionGateState {}

class SubscriptionGateAllowed extends SubscriptionGateState {
  const SubscriptionGateAllowed({
    required this.status,
    this.isOfflineFallback = false,
  });

  final SubscriptionStatusModel status;
  final bool isOfflineFallback;

  bool get showTrialBanner => status.status == 'trial';
  bool get showOverdueBanner => status.status == 'overdue';
}

class SubscriptionGateBlocked extends SubscriptionGateState {
  const SubscriptionGateBlocked(this.status);
  final SubscriptionStatusModel status;
}
