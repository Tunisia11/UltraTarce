import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/metrics_service.dart';

void main() {
  test('calculates daily and monthly sales net of credit notes', () {
    final documents = [
      _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0001',
        status: DocumentStatus.validated,
        date: DateTime(2026, 5, 1),
        lines: [_line(quantity: 2)],
      ),
      _document(
        type: DocumentType.creditNote,
        number: 'AVR-2026-0001',
        status: DocumentStatus.validated,
        date: DateTime(2026, 5, 1),
        lines: [_line(quantity: 1)],
      ),
      _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0002',
        status: DocumentStatus.validated,
        date: DateTime(2026, 5, 2),
        lines: [_line(quantity: 1)],
      ),
    ];

    expect(
      MetricsService.dailySales(documents, now: DateTime(2026, 5, 1)),
      119,
    );
    expect(
      MetricsService.monthlySales(documents, now: DateTime(2026, 5, 3)),
      238,
    );
  });

  test('counts low stock and unpaid validated invoices', () {
    final product = Product(
      id: 'p1',
      name: 'Article',
      sku: 'ART',
      category: 'Cat',
      purchaseHt: 50,
      saleHt: 100,
      tvaRate: TvaRate.rate19,
      minStock: 2,
      serialTracked: false,
      stockByWarehouse: const {'main': 2},
      serialsByWarehouse: const {},
      imageUrl: '',
    );
    final invoice = _document(
      type: DocumentType.facture,
      number: 'FAC-2026-0003',
      status: DocumentStatus.validated,
      date: DateTime(2026, 5, 1),
      lines: [_line(quantity: 1)],
    );

    final metrics = MetricsService.dashboardMetrics(
      documents: [invoice],
      products: [product],
      now: DateTime(2026, 5, 1),
    );

    expect(metrics.lowStockCount, 1);
    expect(metrics.unpaidAmount, 119);
    expect(metrics.draftDocumentCount, 0);
  });
}

DocumentLine _line({required int quantity}) {
  return DocumentLine(
    productId: 'p1',
    label: 'Article',
    sku: 'ART',
    quantity: quantity,
    unitHt: 100,
    tvaRate: TvaRate.rate19,
  );
}

BusinessDocument _document({
  required DocumentType type,
  required String number,
  required DocumentStatus status,
  required DateTime date,
  required List<DocumentLine> lines,
}) {
  return BusinessDocument(
    id: number,
    type: type,
    number: number,
    status: status,
    partnerId: 'c1',
    partnerName: 'Client',
    partnerTaxId: '',
    partnerAddress: '',
    date: date,
    lines: lines,
    warehouseId: 'main',
  );
}
