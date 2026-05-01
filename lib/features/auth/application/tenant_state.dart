import '../data/auth_models.dart';

sealed class TenantState {
  const TenantState();
}

class TenantInitial extends TenantState {
  const TenantInitial();
}

class TenantLoading extends TenantState {
  const TenantLoading();
}

class TenantLoaded extends TenantState {
  const TenantLoaded(this.memberships);

  final List<TenantMembership> memberships;
}

class TenantSelected extends TenantState {
  const TenantSelected({
    required this.memberships,
    required this.selectedTenant,
  });

  final List<TenantMembership> memberships;
  final TenantMembership selectedTenant;
}

class TenantEmpty extends TenantState {
  const TenantEmpty();
}

class TenantFailure extends TenantState {
  const TenantFailure(this.message);

  final String message;
}
