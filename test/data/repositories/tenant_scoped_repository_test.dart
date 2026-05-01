import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/repositories/backup_repository.dart';
import 'package:ultra_trace/data/repositories/client_repository.dart';
import 'package:ultra_trace/data/repositories/document_repository.dart';
import 'package:ultra_trace/data/repositories/product_repository.dart';
import 'package:ultra_trace/data/repositories/stock_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('repositories only expose rows for the selected tenant', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(),
      tenantContext: const TenantContext(tenantIdOverride: 'tenant-a'),
    );
    addTearDown(database.close);

    final tenantA = await createDriftRepositoryHarness(
      databaseOverride: database,
      tenantId: 'tenant-a',
      snapshot: testSnapshot(
        products: [testProduct(id: 'shared-product', name: 'Produit A')],
        partners: [testPartner(id: 'shared-client', name: 'Client A')],
        documents: [testDocument(id: 'shared-document')],
        movements: [
          StockMovement(
            date: DateTime(2026, 5, 1),
            productId: 'shared-product',
            productName: 'Produit A',
            documentNumber: 'A-001',
            direction: StockDirection.inbound,
            quantity: 3,
            warehouseId: 'wh-main',
          ),
        ],
      ),
    );
    final tenantB = await createDriftRepositoryHarness(
      databaseOverride: database,
      tenantId: 'tenant-b',
      snapshot: testSnapshot(
        products: [testProduct(id: 'shared-product', name: 'Produit B')],
        partners: [testPartner(id: 'shared-client', name: 'Client B')],
        documents: [testDocument(id: 'shared-document')],
        movements: [
          StockMovement(
            date: DateTime(2026, 5, 1),
            productId: 'shared-product',
            productName: 'Produit B',
            documentNumber: 'B-001',
            direction: StockDirection.inbound,
            quantity: 7,
            warehouseId: 'wh-main',
          ),
        ],
      ),
    );

    tenantA.appRepository.setSnapshot(
      (await tenantA.store.loadSnapshot())!,
      status: 'Tenant A',
    );
    tenantB.appRepository.setSnapshot(
      (await tenantB.store.loadSnapshot())!,
      status: 'Tenant B',
    );

    expect(
      ProductRepository(tenantA.appRepository).getAll().single.name,
      'Produit A',
    );
    expect(
      ProductRepository(tenantB.appRepository).getAll().single.name,
      'Produit B',
    );
    expect(
      ClientRepository(tenantA.appRepository).getAll().single.name,
      'Client A',
    );
    expect(
      ClientRepository(tenantB.appRepository).getAll().single.name,
      'Client B',
    );
    expect(DocumentRepository(tenantA.appRepository).getAll(), hasLength(1));
    expect(DocumentRepository(tenantB.appRepository).getAll(), hasLength(1));
    expect(
      StockRepository(tenantA.appRepository).movements.single.documentNumber,
      'A-001',
    );
    expect(
      StockRepository(tenantB.appRepository).movements.single.documentNumber,
      'B-001',
    );
  });

  test('backup export and restore are scoped to the selected tenant', () async {
    final database = AppDatabase.forTesting(
      NativeDatabase.memory(),
      tenantContext: const TenantContext(tenantIdOverride: 'tenant-a'),
    );
    addTearDown(database.close);

    final tenantA = await createDriftRepositoryHarness(
      databaseOverride: database,
      tenantId: 'tenant-a',
      snapshot: testSnapshot(
        products: [testProduct(id: 'p-a', name: 'Article A')],
      ),
    );
    final tenantB = await createDriftRepositoryHarness(
      databaseOverride: database,
      tenantId: 'tenant-b',
      snapshot: testSnapshot(
        products: [testProduct(id: 'p-b', name: 'Article B')],
      ),
    );
    tenantA.appRepository.setSnapshot(
      (await tenantA.store.loadSnapshot())!,
      status: 'Tenant A',
    );
    tenantB.appRepository.setSnapshot(
      (await tenantB.store.loadSnapshot())!,
      status: 'Tenant B',
    );

    final backupA = BackupRepository(tenantA.appRepository).exportBackup();
    expect(backupA, contains('Article A'));
    expect(backupA, isNot(contains('Article B')));

    final backupB = BackupRepository(tenantB.appRepository);
    backupB.confirmRestore(
      BackupImportPreview(
        testSnapshot(
          products: [testProduct(id: 'p-new', name: 'Article B2')],
        ),
      ),
      status: 'Base restaurée.',
    );
    await tenantB.appRepository.flushPendingWrites();

    final restoredA = await tenantA.store.loadSnapshot();
    final restoredB = await tenantB.store.loadSnapshot();
    expect(restoredA!.products.single.name, 'Article A');
    expect(restoredB!.products.single.name, 'Article B2');
  });
}
