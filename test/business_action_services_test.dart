import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/document_lifecycle_service.dart';
import 'package:ultra_trace/domain/services/payment_service.dart';
import 'package:ultra_trace/domain/services/return_service.dart';
import 'package:ultra_trace/domain/services/stock_service.dart';

void main() {
  group('DocumentLifecycleService', () {
    test('prevents canceling a quote that already has an active BL', () {
      final quote = _document(
        type: DocumentType.devis,
        number: 'DEV-2026-0001',
        status: DocumentStatus.validated,
      );
      final bl = _document(
        type: DocumentType.bl,
        number: 'BL-2026-0001',
        status: DocumentStatus.draft,
        sourceNumber: quote.number,
      );

      expect(
        DocumentLifecycleService.cancelBlockReason([quote, bl], quote),
        contains(bl.number),
      );
      expect(
        DocumentLifecycleService.conversionBlockReason(
          [quote, bl],
          quote,
          DocumentType.bl,
        ),
        contains('Conversion bloquée'),
      );
    });

    test('builds linked documents with the correct source relationship', () {
      final quote = _document(
        type: DocumentType.devis,
        number: 'DEV-2026-0002',
        status: DocumentStatus.validated,
      );
      final bl = DocumentLifecycleService.buildBlFromQuote(
        source: quote,
        id: 'bl-id',
        number: 'BL-2026-0002',
        date: DateTime(2026, 4, 22),
      );
      final invoice = DocumentLifecycleService.buildInvoiceFromBl(
        source: bl.copyWith(status: DocumentStatus.validated),
        id: 'fac-id',
        number: 'FAC-2026-0002',
        date: DateTime(2026, 4, 22),
        applyTimbreFiscal: true,
        timbreFiscalAmount: 1,
      );

      expect(bl.sourceNumber, quote.number);
      expect(bl.status, DocumentStatus.draft);
      expect(invoice.sourceNumber, bl.number);
      expect(invoice.status, DocumentStatus.validated);
      expect(invoice.applyTimbreFiscal, isTrue);
    });
  });

  group('PaymentService', () {
    test('blocks draft invoices and overpayments', () {
      final draftInvoice = _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0003',
        status: DocumentStatus.draft,
      );
      final validatedInvoice = draftInvoice.copyWith(
        status: DocumentStatus.validated,
      );

      expect(
        PaymentService.paymentBlockReason([draftInvoice], draftInvoice),
        contains('doit être validée'),
      );
      expect(
        PaymentService.paymentAmountError(
          [validatedInvoice],
          validatedInvoice,
          2000,
          formatMoney: _money,
        ),
        contains('Paiement refusé'),
      );
    });

    test('records valid payment without mutating the original invoice', () {
      final invoice = _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0004',
        status: DocumentStatus.validated,
      );
      final updated = PaymentService.recordPayment(
        [invoice],
        invoice,
        PaymentEntry(
          id: 'pay-1',
          date: DateTime(2026, 4, 22),
          amount: 500,
          method: PaymentMethod.cash,
        ),
        formatMoney: _money,
      );

      expect(invoice.payments, isEmpty);
      expect(updated.payments.single.amount, 500);
    });
  });

  group('ReturnService', () {
    test('blocks returns on draft invoices', () {
      final invoice = _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0005',
        status: DocumentStatus.draft,
      );

      expect(
        ReturnService.creditNoteBlockReason([invoice], invoice),
        contains('doit être validée'),
      );
    });

    test('builds partial credit notes and rejects over-return quantities', () {
      final invoice = _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0006',
        status: DocumentStatus.validated,
        lines: [_line(quantity: 2)],
      );
      final selectedLine = invoice.lines.single.copyWith(quantity: 1);

      expect(
        ReturnService.selectedLinesError(
          [invoice],
          invoice,
          [invoice.lines.single.copyWith(quantity: 3)],
        ),
        contains('Maximum: 2'),
      );

      final creditNote = ReturnService.buildCreditNoteFromInvoice(
        documents: [invoice],
        invoice: invoice,
        selectedLines: [selectedLine],
        id: 'avoir-id',
        number: 'AVR-2026-0001',
        date: DateTime(2026, 4, 22),
        note: '',
      );

      expect(creditNote.type, DocumentType.creditNote);
      expect(creditNote.status, DocumentStatus.draft);
      expect(creditNote.sourceNumber, invoice.number);
      expect(creditNote.lines.single.quantity, 1);
    });
  });

  group('StockService', () {
    test('reports stock shortage and serial selection errors', () {
      const product = Product(
        id: 'p1',
        name: 'TV Samsung',
        sku: 'TV-SAM',
        category: 'TV',
        purchaseHt: 800,
        saleHt: 1000,
        tvaRate: TvaRate.rate19,
        minStock: 1,
        serialTracked: true,
        stockByWarehouse: {'main': 1},
        serialsByWarehouse: {
          'main': ['SN-1'],
        },
        imageUrl: '',
      );

      expect(
        StockService.stockAvailabilityErrorFor(
          lines: [_line(quantity: 2)],
          warehouseId: 'main',
          productById: (_) => product,
          warehouseNameById: (_) => 'Magasin principal',
        ),
        contains('Stock insuffisant'),
      );
      expect(
        StockService.serialSelectionErrorFor(
          lines: [_line(quantity: 1)],
          warehouseId: 'main',
          productById: (_) => product,
        ),
        contains('Numéros de série requis'),
      );
    });
  });
}

String _money(double value) => '${value.toStringAsFixed(3)} TND';

DocumentLine _line({int quantity = 1}) {
  return DocumentLine(
    productId: 'p1',
    label: 'TV Samsung',
    sku: 'TV-SAM',
    quantity: quantity,
    unitHt: 1000,
    tvaRate: TvaRate.rate19,
  );
}

BusinessDocument _document({
  required DocumentType type,
  required String number,
  required DocumentStatus status,
  List<DocumentLine>? lines,
  String? sourceNumber,
}) {
  return BusinessDocument(
    id: number,
    type: type,
    number: number,
    status: status,
    partnerId: 'c1',
    partnerName: 'Client Test',
    partnerTaxId: '1234567/A/M/000',
    partnerAddress: 'Tunis',
    date: DateTime(2026, 4, 22),
    lines: lines ?? [_line()],
    warehouseId: 'main',
    sourceNumber: sourceNumber,
  );
}
