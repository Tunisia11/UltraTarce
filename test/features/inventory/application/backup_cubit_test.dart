import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/application/backup_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('BackupCubit restore refreshes app state', () {
    final product = testProduct();
    final sourceRepositories = createTestRepositories(
      snapshot: testSnapshot(products: [product]),
    );
    final backupJson = sourceRepositories.backupRepository.exportBackup();

    final targetRepositories = createTestRepositories();
    final cubit = BackupCubit(
      targetRepositories.backupRepository,
      targetRepositories.auditRepository,
    );
    addTearDown(cubit.close);

    final preview = cubit.importBackupPreview(backupJson);
    cubit.confirmRestore(preview);

    expect(
      targetRepositories.appRepository.snapshot.products.single.id,
      product.id,
    );
    expect(
      targetRepositories.appRepository.snapshot.auditEvents.first.action,
      'Restauration',
    );
    expect(cubit.state.restoredSnapshot?.products.single.id, product.id);
  });
}
