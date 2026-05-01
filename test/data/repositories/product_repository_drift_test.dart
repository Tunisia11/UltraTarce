import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/product_repository.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test(
    'ProductRepository writes product create/update/archive through Drift',
    () async {
      final harness = await createDriftRepositoryHarness();
      final repository = ProductRepository(harness.appRepository);

      final created = testProduct(id: 'p-new', name: 'Scanner');
      repository.upsert(created, status: 'Produit créé.');
      await harness.appRepository.flushPendingWrites();

      var row = await harness.database.productDao.getProductById(created.id);
      expect(row?.name, 'Scanner');

      repository.upsert(
        created.copyWith(name: 'Scanner Pro'),
        status: 'Produit modifié.',
      );
      await harness.appRepository.flushPendingWrites();
      row = await harness.database.productDao.getProductById(created.id);
      expect(row?.name, 'Scanner Pro');

      repository.archive(created, status: 'Produit archivé.');
      await harness.appRepository.flushPendingWrites();
      row = await harness.database.productDao.getProductById(created.id);
      expect(row?.isActive, isFalse);
    },
  );
}
