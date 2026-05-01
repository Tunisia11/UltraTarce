import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/inventory/application/category_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('CategoryCubit loads categories', () {
    final repositories = createTestRepositories();
    final cubit = CategoryCubit(repositories.categoryRepository);
    addTearDown(cubit.close);

    cubit.loadCategories();

    final state = cubit.state;
    expect(state, isA<CategoryLoaded>());
    expect((state as CategoryLoaded).categories.single.name, 'Général');
  });

  test('CategoryCubit creates category', () {
    final repositories = createTestRepositories();
    final cubit = CategoryCubit(repositories.categoryRepository);
    addTearDown(cubit.close);

    cubit.createCategory(
      const Category(id: 'cat-accessoires', name: 'Accessoires'),
    );

    expect(repositories.appRepository.snapshot.categories, hasLength(2));
    expect(
      repositories.appRepository.snapshot.categories.last.name,
      'Accessoires',
    );
  });

  test('CategoryCubit updates category and product references', () {
    final product = testProduct();
    final category = const Category(id: 'cat-main', name: 'Général');
    final repositories = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final cubit = CategoryCubit(repositories.categoryRepository);
    addTearDown(cubit.close);

    cubit.updateCategory(
      category.copyWith(name: 'Pièces'),
      oldName: category.name,
    );

    final snapshot = repositories.appRepository.snapshot;
    expect(snapshot.categories.single.name, 'Pièces');
    expect(snapshot.products.single.category, 'Pièces');
  });
}
