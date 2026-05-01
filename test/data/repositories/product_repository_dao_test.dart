import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/local/database/mappers/product_mapper.dart';
import 'package:ultra_trace/data/repositories/product_repository.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('product create inserts one product row', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = ProductRepository(harness.appRepository);

    repository.upsert(testProduct(id: 'p-new'), status: 'Produit sauvegardé.');
    await harness.appRepository.flushPendingWrites();

    final rows = await harness.database.productDao.getAllProducts();
    expect(
      rows.where((row) => ProductMapper.fromRow(row).id == 'p-new'),
      hasLength(1),
    );
  });

  test('product update and archive persist after reload', () async {
    final product = testProduct(id: 'p1', name: 'Initial');
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(products: [product]),
    );
    final repository = ProductRepository(harness.appRepository);

    final updated = product.copyWith(name: 'Modifié');
    repository.upsert(updated, status: 'Produit sauvegardé.');
    repository.archive(updated, status: 'Catalogue sauvegardé.');
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.products.single.name, 'Modifié');
    expect(restored.products.single.active, isFalse);
  });
}
