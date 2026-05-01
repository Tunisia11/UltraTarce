import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/features/inventory/application/documents_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('DocumentsCubit adds payment and updates status', () {
    final product = testProduct(stock: 5);
    final client = testClient();
    final invoice = testInvoice(product: product, client: client);
    final repositories = createTestRepositories(
      snapshot: testSnapshot(
        products: [product],
        partners: [client],
        documents: [invoice],
      ),
    );
    final cubit = DocumentsCubit(
      repositories.documentRepository,
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
    expect(updated.payments, hasLength(1));
    expect(updated.paymentStatus, PaymentStatus.paid);
    expect(cubit.state.documents.single.paymentStatus, PaymentStatus.paid);
    expect(
      repositories.appRepository.snapshot.auditEvents.single.action,
      'Paiement',
    );
  });

  test('DocumentsCubit converts Devis to BL', () {
    final product = testProduct();
    final client = testClient();
    final quote = _document(
      id: 'dev-1',
      type: DocumentType.devis,
      number: 'DEV-2026-0001',
      product: product,
      client: client,
    );
    final repositories = createTestRepositories(
      snapshot: testSnapshot(
        products: [product],
        partners: [client],
        documents: [quote],
      ),
    );
    final cubit = DocumentsCubit(
      repositories.documentRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.convertDevisToBl(
      source: quote,
      id: 'bl-1',
      number: 'BL-2026-0001',
      date: DateTime(2026, 5),
    );

    final bl = repositories.appRepository.snapshot.documents.first;
    expect(bl.type, DocumentType.bl);
    expect(bl.sourceNumber, quote.number);
    expect(bl.partnerName, quote.partnerName);
    expect(bl.netToPay, quote.netToPay);
  });

  test('DocumentsCubit converts BL to Facture', () {
    final product = testProduct();
    final client = testClient();
    final bl = _document(
      id: 'bl-1',
      type: DocumentType.bl,
      number: 'BL-2026-0001',
      status: DocumentStatus.validated,
      product: product,
      client: client,
    );
    final repositories = createTestRepositories(
      snapshot: testSnapshot(
        products: [product],
        partners: [client],
        documents: [bl],
      ),
    );
    final cubit = DocumentsCubit(
      repositories.documentRepository,
      repositories.auditRepository,
    );
    addTearDown(cubit.close);

    cubit.convertBlToFacture(
      source: bl,
      id: 'fac-1',
      number: 'FAC-2026-0001',
      date: DateTime(2026, 5),
      applyTimbreFiscal: true,
      timbreFiscalAmount: 1,
    );

    final invoice = repositories.appRepository.snapshot.documents.first;
    expect(invoice.type, DocumentType.facture);
    expect(invoice.status, DocumentStatus.validated);
    expect(invoice.sourceNumber, bl.number);
    expect(invoice.partnerName, bl.partnerName);
    expect(invoice.netToPay, bl.netToPay + 1);
  });
}

BusinessDocument _document({
  required String id,
  required DocumentType type,
  required String number,
  required Product product,
  required Partner client,
  DocumentStatus status = DocumentStatus.draft,
}) {
  return BusinessDocument(
    id: id,
    type: type,
    number: number,
    status: status,
    partnerId: client.id,
    partnerName: client.name,
    partnerTaxId: client.taxId,
    partnerAddress: client.address,
    date: DateTime(2026, 5),
    lines: [
      DocumentLine(
        productId: product.id,
        label: product.name,
        sku: product.sku,
        quantity: 2,
        unitHt: product.saleHt,
        tvaRate: product.tvaRate,
      ),
    ],
    warehouseId: testWarehouseId,
  );
}
