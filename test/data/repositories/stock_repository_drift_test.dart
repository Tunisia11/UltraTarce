import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/stock_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/stock_mutation_service.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('StockRepository writes stock movements through Drift', () async {
    final product = testProduct(stock: 1);
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(products: [product]),
    );
    final repository = StockRepository(harness.appRepository);

    repository.applyStockMutation(
      StockMutationResult(
        products: [
          product.copyWith(stockByWarehouse: {'wh-main': 4}),
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

    expect(await harness.database.stockDao.getMovements(), hasLength(1));
    expect(
      await harness.database.stockDao.getCurrentStock(product.id, 'wh-main'),
      3,
    );
  });
}
