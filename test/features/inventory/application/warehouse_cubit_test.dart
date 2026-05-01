import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/inventory/application/warehouse_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('WarehouseCubit loads warehouses', () {
    final repositories = createTestRepositories();
    final cubit = WarehouseCubit(
      repositories.warehouseRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.loadWarehouses();

    final state = cubit.state;
    expect(state, isA<WarehouseLoaded>());
    expect((state as WarehouseLoaded).warehouses.single.id, testWarehouseId);
  });

  test('WarehouseCubit creates warehouse and initializes product stock', () {
    final product = testProduct(stock: 3);
    final repositories = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final cubit = WarehouseCubit(
      repositories.warehouseRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.createWarehouse(
      const Warehouse(
        id: 'wh-sousse',
        name: 'Dépôt Sousse',
        city: 'Sousse',
        code: 'SOU',
      ),
    );

    final snapshot = repositories.appRepository.snapshot;
    expect(snapshot.warehouses, hasLength(2));
    expect(snapshot.products.single.stockIn('wh-sousse'), 0);
    expect(snapshot.auditEvents.first.action, 'Création dépôt');
  });

  test('WarehouseCubit updates warehouse', () {
    final repositories = createTestRepositories();
    final cubit = WarehouseCubit(
      repositories.warehouseRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.updateWarehouse(
      const Warehouse(
        id: testWarehouseId,
        name: 'Dépôt modifié',
        city: 'Tunis',
        code: 'TUN',
      ),
    );

    expect(
      repositories.appRepository.snapshot.warehouses.single.name,
      'Dépôt modifié',
    );
    expect(
      repositories.appRepository.snapshot.auditEvents.first.action,
      'Modification dépôt',
    );
  });
}
