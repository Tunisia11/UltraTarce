import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/audit_service.dart';

sealed class WarehouseState {
  const WarehouseState();
}

class WarehouseInitial extends WarehouseState {
  const WarehouseInitial();
}

class WarehouseLoading extends WarehouseState {
  const WarehouseLoading();
}

class WarehouseLoaded extends WarehouseState {
  const WarehouseLoaded({
    required this.warehouses,
    this.selectedWarehouseId = '',
  });

  final List<Warehouse> warehouses;
  final String selectedWarehouseId;

  Warehouse? get defaultWarehouse {
    final active = warehouses.where((warehouse) => warehouse.active).toList();
    if (active.isNotEmpty) return active.first;
    return warehouses.isEmpty ? null : warehouses.first;
  }
}

class WarehouseFailure extends WarehouseState {
  const WarehouseFailure(this.message);

  final String message;
}

class WarehouseDeleteResult {
  const WarehouseDeleteResult({required this.snapshot, required this.archived});

  final AppSnapshot snapshot;
  final bool archived;
}

class WarehouseCubit extends Cubit<WarehouseState> {
  WarehouseCubit(this._warehouseRepository, this._auditRepository)
    : super(const WarehouseInitial());

  final WarehouseRepository _warehouseRepository;
  final AuditRepository _auditRepository;

  List<Warehouse> get warehouses => _warehouseRepository.getWarehouses();

  void loadWarehouses() {
    emit(const WarehouseLoading());
    try {
      final warehouses = _warehouseRepository.getWarehouses();
      emit(
        WarehouseLoaded(
          warehouses: warehouses,
          selectedWarehouseId:
              _warehouseRepository.getDefaultWarehouse()?.id ?? '',
        ),
      );
    } catch (error) {
      emit(WarehouseFailure(error.toString()));
    }
  }

  AppSnapshot createWarehouse(Warehouse warehouse) {
    _warehouseRepository.createWarehouse(warehouse);
    final snapshot = _appendAudit(
      action: 'Création dépôt',
      target: warehouse.name,
      detail: warehouse.code,
    );
    loadWarehouses();
    return snapshot;
  }

  AppSnapshot updateWarehouse(Warehouse warehouse) {
    _warehouseRepository.updateWarehouse(warehouse);
    final snapshot = _appendAudit(
      action: 'Modification dépôt',
      target: warehouse.name,
      detail: warehouse.code,
    );
    loadWarehouses();
    return snapshot;
  }

  AppSnapshot archiveWarehouse(Warehouse warehouse) {
    final snapshot = _warehouseRepository.archiveWarehouse(warehouse);
    loadWarehouses();
    return snapshot;
  }

  WarehouseDeleteResult deleteOrArchiveWarehouse(Warehouse warehouse) {
    final shouldArchive =
        _warehouseRepository.hasStock(warehouse.id) ||
        _warehouseRepository.isUsed(warehouse.id);
    final snapshot = shouldArchive
        ? _warehouseRepository.archiveWarehouse(warehouse)
        : _warehouseRepository.deleteWarehouse(warehouse);
    loadWarehouses();
    return WarehouseDeleteResult(snapshot: snapshot, archived: shouldArchive);
  }

  void selectDefaultWarehouse(String warehouseId) {
    final current = state;
    if (current is! WarehouseLoaded) return;
    emit(
      WarehouseLoaded(
        warehouses: current.warehouses,
        selectedWarehouseId: warehouseId,
      ),
    );
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
