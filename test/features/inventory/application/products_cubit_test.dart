import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/application/products_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('ProductsCubit creates product through repository', () {
    final repositories = createTestRepositories();
    final cubit = ProductsCubit(
      repositories.productRepository,
      repositories.stockRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    final product = testProduct(stock: 4, minStock: 1);

    cubit.createProduct(product);

    expect(repositories.appRepository.snapshot.products, hasLength(1));
    expect(repositories.appRepository.snapshot.products.single.id, product.id);
    expect(cubit.state.products.single.id, product.id);
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Création produit',
    );
  });

  test('ProductsCubit updates product through repository', () {
    final product = testProduct();
    final repositories = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final cubit = ProductsCubit(
      repositories.productRepository,
      repositories.stockRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.updateProduct(product.copyWith(name: 'Article modifié'));

    expect(
      repositories.appRepository.snapshot.products.single.name,
      'Article modifié',
    );
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Modification produit',
    );
  });
}
