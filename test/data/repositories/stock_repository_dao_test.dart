import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/stock_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/stock_mutation_service.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test(
    'stock movement persists and current stock calculates after reload',
    () async {
      final product = testProduct(stock: 2);
      final harness = await createDriftRepositoryHarness(
        snapshot: testSnapshot(products: [product]),
      );
      final repository = StockRepository(harness.appRepository);

      repository.applyStockMutation(
        StockMutationResult(
          products: [
            product.copyWith(stockByWarehouse: {'wh-main': 5}),
          ],
          lines: const [],
          movements: [
            StockMovement(
              date: DateTime(2026, 5, 1),
              productId: product.id,
              productName: product.name,
              documentNumber: 'AJ-001',
              direction: StockDirection.inbound,
              quantity: 3,
              warehouseId: 'wh-main',
            ),
          ],
        ),
        status: 'Stock ajusté.',
      );
      await harness.appRepository.flushPendingWrites();

      final restored = await harness.store.loadSnapshot();
      expect(restored!.movements, hasLength(1));
      expect(restored.products.single.stockByWarehouse['wh-main'], 5);
      expect(
        await harness.database.stockDao.getCurrentStock(product.id, 'wh-main'),
        3,
      );
    },
  );
}
