import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/invoice_accounting_service.dart';
import 'package:ultra_trace/domain/services/stock_integrity_service.dart';

void main() {
  group('InvoiceAccountingService', () {
    test('validated credit notes reduce invoice net and remaining due', () {
      final invoiceLine = _line(quantity: 2);
      final invoice = _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0001',
        status: DocumentStatus.validated,
        lines: [invoiceLine],
      );
      final creditNote = _document(
        type: DocumentType.creditNote,
        number: 'AVR-2026-0001',
        status: DocumentStatus.validated,
        sourceNumber: invoice.number,
        lines: [_line(quantity: 1)],
      );
      final documents = [invoice, creditNote];

      expect(
        InvoiceAccountingService.creditedAmountForInvoice(documents, invoice),
        1190,
      );
      expect(
        InvoiceAccountingService.invoiceNetAfterCredits(documents, invoice),
        1190,
      );
      expect(
        InvoiceAccountingService.invoiceRemainingDue(documents, invoice),
        1190,
      );
      expect(
        InvoiceAccountingService.returnableQuantityForLine(
          documents,
          invoice,
          invoiceLine,
        ),
        1,
      );
      expect(
        InvoiceAccountingService.effectivePaymentStatus(documents, invoice),
        PaymentStatus.unpaid,
      );

      final paidInvoice = invoice.copyWith(
        payments: [
          PaymentEntry(
            id: 'pay-1',
            date: DateTime(2026, 4, 22),
            amount: 1190,
            method: PaymentMethod.cash,
          ),
        ],
      );

      expect(
        InvoiceAccountingService.invoiceRemainingDue([
          paidInvoice,
          creditNote,
        ], paidInvoice),
        0,
      );
      expect(
        InvoiceAccountingService.effectivePaymentStatus([
          paidInvoice,
          creditNote,
        ], paidInvoice),
        PaymentStatus.paid,
      );
    });

    test('canceled credit notes do not reduce invoice accounting', () {
      final invoice = _document(
        type: DocumentType.facture,
        number: 'FAC-2026-0002',
        status: DocumentStatus.validated,
        lines: [_line(quantity: 1)],
      );
      final canceledCreditNote = _document(
        type: DocumentType.creditNote,
        number: 'AVR-2026-0002',
        status: DocumentStatus.canceled,
        sourceNumber: invoice.number,
        lines: [_line(quantity: 1)],
      );
      final documents = [invoice, canceledCreditNote];

      expect(
        InvoiceAccountingService.creditedAmountForInvoice(documents, invoice),
        0,
      );
      expect(
        InvoiceAccountingService.invoiceNetAfterCredits(documents, invoice),
        1190,
      );
      expect(
        InvoiceAccountingService.invoiceHasReturnableLines(documents, invoice),
        isTrue,
      );
    });
  });

  group('StockIntegrityService', () {
    test('generates unique movement numbers per prefix and year', () {
      final movements = [
        _movement(documentNumber: 'TRF-2026-0001'),
        _movement(documentNumber: 'TRF-2026-0003'),
        _movement(documentNumber: 'AJU-2026-0009'),
      ];

      expect(
        StockIntegrityService.nextMovementNumber(
          movements,
          'TRF',
          now: DateTime(2026, 4, 22),
        ),
        'TRF-2026-0004',
      );
    });

    test('validates serial tracked outbound and inbound actions', () {
      const product = Product(
        id: 'p1',
        name: 'Scanner Pro',
        sku: 'SCAN-PRO',
        category: 'Scanner',
        purchaseHt: 600,
        saleHt: 900,
        tvaRate: TvaRate.rate19,
        minStock: 1,
        serialTracked: true,
        stockByWarehouse: {'main': 2},
        serialsByWarehouse: {
          'main': ['SN-1', 'SN-2'],
        },
        imageUrl: '',
      );

      expect(
        StockIntegrityService.serialActionError(
          product: product,
          warehouseId: 'main',
          quantity: 1,
          serialNumbers: const ['SN-1'],
          inbound: false,
        ),
        isNull,
      );
      expect(
        StockIntegrityService.serialActionError(
          product: product,
          warehouseId: 'main',
          quantity: 1,
          serialNumbers: const [],
          inbound: false,
        ),
        contains('exactement'),
      );
      expect(
        StockIntegrityService.serialActionError(
          product: product,
          warehouseId: 'main',
          quantity: 1,
          serialNumbers: const ['SN-9'],
          inbound: false,
        ),
        contains('indisponibles'),
      );
      expect(
        StockIntegrityService.serialActionError(
          product: product,
          warehouseId: 'main',
          quantity: 1,
          serialNumbers: const ['SN-1'],
          inbound: true,
        ),
        contains('déjà présente'),
      );
    });
  });
}

DocumentLine _line({required int quantity}) {
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
  required List<DocumentLine> lines,
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
    lines: lines,
    warehouseId: 'main',
    sourceNumber: sourceNumber,
  );
}

StockMovement _movement({required String documentNumber}) {
  return StockMovement(
    date: DateTime(2026, 4, 22),
    productId: 'p1',
    productName: 'TV Samsung',
    documentNumber: documentNumber,
    direction: StockDirection.outbound,
    quantity: 1,
    warehouseId: 'main',
  );
}
