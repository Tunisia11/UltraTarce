import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_models.dart';
import '../data/tenant_repository.dart';
import 'tenant_state.dart';

class TenantCubit extends Cubit<TenantState> {
  TenantCubit(this._tenantRepository) : super(const TenantInitial());

  final TenantRepository _tenantRepository;

  Future<void> loadMemberships(AppUser user) async {
    emit(const TenantLoading());
    try {
      final memberships = await _tenantRepository.loadMemberships(user);
      if (memberships.isEmpty) {
        emit(const TenantEmpty());
        return;
      }
      final stored = _tenantRepository.loadSelectedTenant(user);
      final selected = _matchingMembership(stored, memberships);
      if (selected != null) {
        await _tenantRepository.storeSelectedTenant(
          user: user,
          tenant: selected,
        );
        emit(
          TenantSelected(memberships: memberships, selectedTenant: selected),
        );
        return;
      }
      if (memberships.length == 1) {
        await selectTenant(user: user, tenant: memberships.single);
        return;
      }
      emit(TenantLoaded(memberships));
    } catch (error) {
      emit(TenantFailure(_friendlyMessage(error)));
    }
  }

  Future<void> selectTenant({
    required AppUser user,
    required TenantMembership tenant,
    List<TenantMembership>? memberships,
  }) async {
    try {
      await _tenantRepository.storeSelectedTenant(user: user, tenant: tenant);
      emit(
        TenantSelected(
          memberships: memberships ?? [tenant],
          selectedTenant: tenant,
        ),
      );
    } catch (error) {
      emit(TenantFailure(_friendlyMessage(error)));
    }
  }

  Future<void> createFirstTenant({
    required AppUser user,
    required String companyName,
  }) async {
    emit(const TenantLoading());
    try {
      final tenant = await _tenantRepository.createFirstTenant(
        user: user,
        companyName: companyName,
      );
      await _tenantRepository.storeSelectedTenant(user: user, tenant: tenant);
      emit(TenantSelected(memberships: [tenant], selectedTenant: tenant));
    } catch (error) {
      emit(
        TenantFailure(
          'Compte créé, mais impossible de créer la société. Réessayez.',
          companyName: companyName,
        ),
      );
    }
  }

  Future<void> clearSelection() async {
    await _tenantRepository.clearSelectedTenant();
    emit(const TenantInitial());
  }

  TenantMembership? _matchingMembership(
    TenantMembership? stored,
    List<TenantMembership> memberships,
  ) {
    if (stored == null) return null;
    for (final membership in memberships) {
      if (membership.tenantId == stored.tenantId) return membership;
    }
    return null;
  }

  String _friendlyMessage(Object error) {
    if (error is AuthRepositoryException) return error.message;
    return 'Impossible de charger les sociétés associées à ce compte.';
  }
}
