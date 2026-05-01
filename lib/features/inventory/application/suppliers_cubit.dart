import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';

class SuppliersState {
  const SuppliersState({
    required this.suppliers,
    required this.filteredSuppliers,
    this.query = '',
  });

  factory SuppliersState.initial() =>
      const SuppliersState(suppliers: [], filteredSuppliers: []);

  final List<Partner> suppliers;
  final List<Partner> filteredSuppliers;
  final String query;
}

class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit(this._supplierRepository, this._auditRepository)
    : super(SuppliersState.initial());

  final SupplierRepository _supplierRepository;
  final AuditRepository _auditRepository;

  void loadSuppliers() {
    final suppliers = _supplierRepository.getAll();
    emit(SuppliersState(suppliers: suppliers, filteredSuppliers: suppliers));
  }

  void searchSuppliers(String query) {
    emit(
      SuppliersState(
        suppliers: _supplierRepository.getAll(),
        filteredSuppliers: _supplierRepository.search(query),
        query: query,
      ),
    );
  }

  AppSnapshot createSupplier(Partner supplier) {
    _supplierRepository.upsert(
      supplier.copyWith(type: PartnerType.supplier),
      status: 'Fournisseur sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Création tiers',
      target: supplier.name,
      detail: PartnerType.supplier.label,
    );
    loadSuppliers();
    return snapshot;
  }

  AppSnapshot updateSupplier(Partner supplier) {
    _supplierRepository.upsert(
      supplier.copyWith(type: PartnerType.supplier),
      status: 'Fournisseur sauvegardé.',
    );
    final snapshot = _appendAudit(
      action: 'Modification tiers',
      target: supplier.name,
      detail: PartnerType.supplier.label,
    );
    loadSuppliers();
    return snapshot;
  }

  AppSnapshot archiveSupplier(Partner supplier) {
    _supplierRepository.archive(supplier, status: 'Tiers sauvegardés.');
    final snapshot = _appendAudit(
      action: 'Désactivation tiers',
      target: supplier.name,
      detail: PartnerType.supplier.label,
    );
    loadSuppliers();
    return snapshot;
  }

  AppSnapshot deleteOrArchiveSupplier(Partner supplier) {
    final used = _supplierRepository.isUsed(supplier.id);
    if (used) {
      _supplierRepository.archive(supplier, status: 'Tiers sauvegardés.');
    } else {
      _supplierRepository.delete(supplier, status: 'Tiers sauvegardés.');
    }
    final snapshot = _appendAudit(
      action: used ? 'Désactivation tiers' : 'Suppression tiers',
      target: supplier.name,
      detail: PartnerType.supplier.label,
    );
    loadSuppliers();
    return snapshot;
  }

  AppSnapshot _appendAudit({
    required String action,
    required String target,
    required String detail,
  }) {
    return _auditRepository.saveAll(
      AuditService.append(
        events: _auditRepository.getAll(),
        action: action,
        target: target,
        detail: detail,
      ),
      status: 'Audit sauvegardé.',
    );
  }
}
