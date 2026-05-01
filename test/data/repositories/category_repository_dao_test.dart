import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/category_repository.dart';
import 'package:ultra_trace/domain/app_models.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('category create and update persist after reload', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = CategoryRepository(harness.appRepository);

    const category = Category(id: 'cat-new', name: 'Accessoires');
    repository.createCategory(category);
    repository.updateCategory(
      category.copyWith(name: 'Accessoires Pro'),
      oldName: 'Accessoires',
    );
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(
      restored!.categories.map((item) => item.name),
      contains('Accessoires Pro'),
    );
  });

  test('category rename updates product category references', () async {
    final product = testProduct().copyWith(category: 'Général');
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(products: [product]),
    );
    final repository = CategoryRepository(harness.appRepository);

    repository.updateCategory(
      const Category(id: 'cat-main', name: 'Nouveau Général'),
      oldName: 'Général',
    );
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.products.single.category, 'Nouveau Général');
  });
}
