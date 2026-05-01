import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/features/inventory/application/stock_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('StockCubit creates adjustment', () {
    final product = testProduct(stock: 0, minStock: 1);
    final repositories = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final cubit = StockCubit(
      repositories.stockRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.adjustStock(
      productId: product.id,
      warehouseId: testWarehouseId,
      direction: StockDirection.inbound,
      quantity: 5,
      serialNumbers: const [],
      movementNumber: 'AJ-001',
      date: DateTime(2026, 5),
      serialGenerator: testSerialGenerator,
    );

    final updatedProduct = repositories.appRepository.snapshot.products.single;
    final movement = repositories.appRepository.snapshot.movements.single;
    expect(updatedProduct.stockIn(testWarehouseId), 5);
    expect(movement.direction, StockDirection.inbound);
    expect(movement.quantity, 5);
    expect(cubit.state.products.single.stockIn(testWarehouseId), 5);
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Ajustement stock',
    );
  });
}
