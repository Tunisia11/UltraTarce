import '../../domain/app_models.dart';
import '../local/database/app_database.dart';
import '../local/database/mappers/product_mapper.dart';
import '../local/database/mappers/warehouse_mapper.dart';
import 'app_repository.dart';

class WarehouseRepository {
  WarehouseRepository(this._appRepository);

  final AppRepository _appRepository;

  List<Warehouse> getWarehouses() =>
      List<Warehouse>.from(_appRepository.snapshot.warehouses);

  Stream<List<Warehouse>> watchWarehouses() async* {
    yield getWarehouses();
  }

  Warehouse? getDefaultWarehouse() {
    final warehouses = getWarehouses();
    final active = warehouses.where((warehouse) => warehouse.active).toList();
    if (active.isNotEmpty) return active.first;
    return warehouses.isEmpty ? null : warehouses.first;
  }

  bool hasStock(String warehouseId) {
    return _appRepository.snapshot.products.any(
      (product) => product.stockIn(warehouseId) > 0,
    );
  }

  bool isUsed(String warehouseId) {
    return _appRepository.snapshot.documents.any(
      (document) => document.warehouseId == warehouseId,
    );
  }

  AppSnapshot createWarehouse(Warehouse warehouse) {
    final snapshot = _appRepository.snapshot;
    final warehouses = [...snapshot.warehouses, warehouse];
    final products = snapshot.products.map((product) {
      final stock = Map<String, int>.from(product.stockByWarehouse);
      stock[warehouse.id] = stock[warehouse.id] ?? 0;
      return product.copyWith(stockByWarehouse: stock);
    }).toList();
    return _saveSnapshot(
      warehouses: warehouses,
      products: products,
      status: 'Dépôt sauvegardé.',
      write: (database) async {
        final tenantId = _appRepository.tenantId;
        await database.transaction(() async {
          await database.warehouseDao.upsertWarehouse(
            WarehouseMapper.toCompanion(warehouse, tenantId: tenantId),
          );
          for (final product in products) {
            await database.productDao.upsertProduct(
              ProductMapper.toCompanion(product, tenantId: tenantId),
            );
          }
        });
      },
    );
  }

  AppSnapshot updateWarehouse(Warehouse warehouse) {
    final warehouses = getWarehouses();
    final index = warehouses.indexWhere((item) => item.id == warehouse.id);
    if (index >= 0) {
      warehouses[index] = warehouse;
    } else {
      warehouses.add(warehouse);
    }
    return _saveSnapshot(
      warehouses: warehouses,
      status: 'Dépôt sauvegardé.',
      write: (database) => database.warehouseDao.upsertWarehouse(
        WarehouseMapper.toCompanion(
          warehouse,
          tenantId: _appRepository.tenantId,
        ),
      ),
    );
  }

  AppSnapshot archiveWarehouse(Warehouse warehouse) {
    final warehouses = getWarehouses();
    final index = warehouses.indexWhere((item) => item.id == warehouse.id);
    if (index >= 0) {
      warehouses[index] = warehouse.copyWith(active: false);
    }
    return _saveSnapshot(
      warehouses: warehouses,
      status: 'Dépôt désactivé.',
      write: (database) => database.warehouseDao.archiveWarehouse(
        warehouse.id,
        tenantId: _appRepository.tenantId,
      ),
    );
  }

  AppSnapshot deleteWarehouse(Warehouse warehouse) {
    final warehouses = getWarehouses()
      ..removeWhere((item) => item.id == warehouse.id);
    return _saveSnapshot(
      warehouses: warehouses,
      status: 'Dépôt supprimé.',
      write: (database) => database.warehouseDao.deleteWarehouse(
        warehouse.id,
        tenantId: _appRepository.tenantId,
      ),
    );
  }

  AppSnapshot _saveSnapshot({
    required List<Warehouse> warehouses,
    List<Product>? products,
    required String status,
    required Future<void> Function(AppDatabase database) write,
  }) {
    final snapshot = _appRepository.snapshot;
    return _appRepository.commitDaoMutation(
      AppSnapshot(
        company: snapshot.company,
        warehouses: warehouses,
        categories: snapshot.categories,
        products: products ?? snapshot.products,
        partners: snapshot.partners,
        documents: snapshot.documents,
        movements: snapshot.movements,
        sequences: snapshot.sequences,
        auditEvents: snapshot.auditEvents,
      ),
      status: status,
      write: write,
    );
  }
}
