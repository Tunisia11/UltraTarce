import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/warehouse_repository.dart';
import 'package:ultra_trace/domain/app_models.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test(
    'warehouse create initializes product stock maps and persists',
    () async {
      final harness = await createDriftRepositoryHarness(
        snapshot: testSnapshot(products: [testProduct()]),
      );
      final repository = WarehouseRepository(harness.appRepository);

      repository.createWarehouse(
        const Warehouse(id: 'wh-sousse', name: 'Dépôt Sousse', city: 'Sousse'),
      );
      await harness.appRepository.flushPendingWrites();

      final restored = await harness.store.loadSnapshot();
      expect(
        restored!.warehouses.map((warehouse) => warehouse.id),
        contains('wh-sousse'),
      );
      expect(restored.products.single.stockByWarehouse['wh-sousse'], 0);
    },
  );

  test('warehouse update persists after reload', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = WarehouseRepository(harness.appRepository);

    repository.updateWarehouse(
      const Warehouse(id: 'wh-main', name: 'Dépôt Centre', city: 'Tunis'),
    );
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.warehouses.single.name, 'Dépôt Centre');
  });
}
