import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/client_repository.dart';
import 'package:ultra_trace/data/repositories/document_repository.dart';
import 'package:ultra_trace/data/repositories/product_repository.dart';
import 'package:ultra_trace/data/repositories/stock_repository.dart';
import 'package:ultra_trace/data/repositories/supplier_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/payment_service.dart';
import 'package:ultra_trace/domain/services/stock_mutation_service.dart';

import '../repositories/drift_repository_test_helpers.dart';

void main() {
  test('create and update product enqueue sync outbox rows', () async {
    final harness = await createDriftRepositoryHarness();
    final repository = ProductRepository(harness.appRepository);

    final product = testProduct(id: 'p-sync');
    repository.upsert(product, status: 'Produit sauvegardé.');
    repository.upsert(
      product.copyWith(name: 'Produit modifié'),
      status: 'Produit sauvegardé.',
    );
    await harness.appRepository.flushPendingWrites();

    final rows = await harness.syncOutboxRepository.listPending(
      tenantId: 'local_legacy_tenant',
      limit: 20,
    );
    expect(rows.where((row) => row.entityType == 'products'), hasLength(2));
  });

  test('create client and supplier enqueue partner sync rows', () async {
    final harness = await createDriftRepositoryHarness();
    final clients = ClientRepository(harness.appRepository);
    final suppliers = SupplierRepository(harness.appRepository);

    clients.upsert(
      testPartner(id: 'client-sync'),
      status: 'Client sauvegardé.',
    );
    suppliers.upsert(
      testPartner(
        id: 'supplier-sync',
        type: PartnerType.supplier,
        name: 'Fournisseur Sync',
      ),
      status: 'Fournisseur sauvegardé.',
    );
    await harness.appRepository.flushPendingWrites();

    final rows = await harness.syncOutboxRepository.listPending(
      tenantId: 'local_legacy_tenant',
      limit: 20,
    );
    expect(rows.where((row) => row.entityType == 'partners'), hasLength(2));
  });

  test('create document and add payment enqueue document child rows', () async {
    final invoice = testDocument();
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(
        products: [testProduct()],
        partners: [testPartner()],
      ),
    );
    final repository = DocumentRepository(harness.appRepository);

    repository.upsert(invoice, status: 'Facture sauvegardée.');
    await harness.appRepository.flushPendingWrites();

    final paid = PaymentService.recordPayment(
      [invoice],
      invoice,
      PaymentEntry(
        id: 'pay-sync',
        date: DateTime(2026, 5, 1),
        amount: 50,
        method: PaymentMethod.cash,
      ),
      formatMoney: (value) => value.toStringAsFixed(3),
    );
    repository.upsert(paid, status: 'Paiement sauvegardé.');
    await harness.appRepository.flushPendingWrites();

    final rows = await harness.syncOutboxRepository.listPending(
      tenantId: 'local_legacy_tenant',
      limit: 40,
    );
    expect(rows.map((row) => row.entityType), contains('documents'));
    expect(rows.map((row) => row.entityType), contains('document_lines'));
    expect(rows.map((row) => row.entityType), contains('payments'));
  });

  test('stock adjustment enqueues product and stock movement rows', () async {
    final product = testProduct(stock: 2);
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(products: [product]),
    );
    final repository = StockRepository(harness.appRepository);

    repository.applyStockMutation(
      StockMutationResult(
        products: [
          product.copyWith(stockByWarehouse: {'wh-main': 5}),
        ],
        lines: const [],
        movements: [
          StockMovement(
            date: DateTime(2026, 5, 1),
            productId: product.id,
            productName: product.name,
            documentNumber: 'AJ-SYNC',
            direction: StockDirection.inbound,
            quantity: 3,
            warehouseId: 'wh-main',
          ),
        ],
      ),
      status: 'Stock ajusté.',
    );
    await harness.appRepository.flushPendingWrites();

    final rows = await harness.syncOutboxRepository.listPending(
      tenantId: 'local_legacy_tenant',
      limit: 20,
    );
    expect(rows.map((row) => row.entityType), contains('products'));
    expect(rows.map((row) => row.entityType), contains('stock_movements'));
  });
}
