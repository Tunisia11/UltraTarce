import '../data/admin_subscription_models.dart';

abstract class AdminSubscriptionState {
  const AdminSubscriptionState();
}

class AdminSubscriptionInitial extends AdminSubscriptionState {}

class AdminSubscriptionLoading extends AdminSubscriptionState {}

class AdminSubscriptionLoaded extends AdminSubscriptionState {
  const AdminSubscriptionLoaded(this.subscriptions);
  final List<AdminTenantSubscription> subscriptions;
}

class AdminSubscriptionError extends AdminSubscriptionState {
  const AdminSubscriptionError(this.message);
  final String message;
}
