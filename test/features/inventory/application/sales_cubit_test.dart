import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/inventory/application/sales_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('SalesCubit creates sale and updates totals', () {
    final product = testProduct(stock: 10, minStock: 1);
    final client = testClient();
    final repositories = createTestRepositories(
      snapshot: testSnapshot(products: [product], partners: [client]),
    );
    final cubit = SalesCubit(
      repositories.documentRepository,
      repositories.stockRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.startSale(type: DocumentType.facture);
    cubit.selectClient(client.id);
    cubit.selectWarehouse(testWarehouseId);
    cubit.addLine(product, quantity: 2);

    expect(cubit.state.totalHt, 200);
    expect(cubit.state.totalTva, 38);
    expect(
      cubit.state.netToPay(repositories.appRepository.snapshot.company),
      239,
    );

    cubit.createSale(
      id: 'sale-1',
      number: 'FAC-2026-0001',
      client: client,
      company: repositories.appRepository.snapshot.company,
      date: DateTime(2026, 5),
      warehouseId: testWarehouseId,
    );

    final document = repositories.appRepository.snapshot.documents.single;
    expect(document.number, 'FAC-2026-0001');
    expect(document.type, DocumentType.facture);
    expect(document.lines.single.quantity, 2);
    expect(document.netToPay, 239);
    expect(cubit.state.createdDocument?.id, document.id);
  });

  test('SalesCubit creates payment when needed', () {
    final invoice = testInvoice();
    final repositories = createTestRepositories(
      snapshot: testSnapshot(documents: [invoice]),
    );
    final cubit = SalesCubit(
      repositories.documentRepository,
      repositories.stockRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.addPayment(
      document: invoice,
      documents: repositories.documentRepository.getAll(),
      payment: PaymentEntry(
        id: 'pay-1',
        date: DateTime(2026, 5),
        amount: invoice.netToPay,
        method: PaymentMethod.cash,
      ),
      formatMoney: testFormatMoney,
    );

    final updated = repositories.appRepository.snapshot.documents.single;
    expect(updated.paymentStatus, PaymentStatus.paid);
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Paiement',
    );
  });
}
