import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/backup_repository.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test(
    'BackupRepository exports AppSnapshot-compatible JSON from Drift state',
    () async {
      final harness = await createDriftRepositoryHarness(
        snapshot: testSnapshot(
          products: [testProduct()],
          partners: [testPartner()],
        ),
      );
      final repository = BackupRepository(harness.appRepository);

      final raw = repository.exportBackup();

      expect(raw, contains('Article test'));
      expect(raw, contains('Client Test'));
    },
  );

  test('BackupRepository restore replaces Drift state', () async {
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(
        products: [testProduct(id: 'old', name: 'Ancien')],
      ),
    );
    final repository = BackupRepository(harness.appRepository);
    final preview = BackupImportPreview(
      testSnapshot(
        products: [testProduct(id: 'new', name: 'Nouveau')],
      ),
    );

    repository.confirmRestore(preview, status: 'Sauvegarde restaurée.');
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.products.single.name, 'Nouveau');
  });
}
