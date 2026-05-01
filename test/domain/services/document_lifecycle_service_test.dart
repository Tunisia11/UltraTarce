import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/document_lifecycle_service.dart';

void main() {
  test('conversion from Devis to BL keeps totals and client data', () {
    final quote = _document(
      type: DocumentType.devis,
      number: 'DEV-2026-0001',
      status: DocumentStatus.validated,
    );

    final bl = DocumentLifecycleService.buildBlFromQuote(
      source: quote,
      id: 'bl-1',
      number: 'BL-2026-0001',
      date: DateTime(2026, 5, 1),
    );

    expect(bl.partnerId, quote.partnerId);
    expect(bl.partnerName, quote.partnerName);
    expect(bl.partnerTaxId, quote.partnerTaxId);
    expect(bl.sourceNumber, quote.number);
    expect(bl.netToPay, quote.netToPay);
  });

  test('conversion from BL to Facture keeps totals and client data', () {
    final bl = _document(
      type: DocumentType.bl,
      number: 'BL-2026-0001',
      status: DocumentStatus.validated,
    );

    final invoice = DocumentLifecycleService.buildInvoiceFromBl(
      source: bl,
      id: 'fac-1',
      number: 'FAC-2026-0001',
      date: DateTime(2026, 5, 1),
      applyTimbreFiscal: true,
      timbreFiscalAmount: 1,
    );

    expect(invoice.partnerId, bl.partnerId);
    expect(invoice.sourceNumber, bl.number);
    expect(invoice.status, DocumentStatus.validated);
    expect(invoice.netToPay, bl.netToPay + 1);
  });

  test('status transition helpers preserve validation and cancel rules', () {
    final canceled = _document(
      type: DocumentType.facture,
      number: 'FAC-2026-0002',
      status: DocumentStatus.canceled,
    );
    final draft = _document(
      type: DocumentType.facture,
      number: 'FAC-2026-0003',
      status: DocumentStatus.draft,
    );

    expect(
      DocumentLifecycleService.validationBlockReason(canceled),
      contains('Validation bloquée'),
    );
    expect(
      DocumentLifecycleService.markValidated(
        draft,
        lines: draft.lines,
        stockApplied: true,
      ).status,
      DocumentStatus.validated,
    );
    expect(
      DocumentLifecycleService.markCanceled(draft).status,
      DocumentStatus.canceled,
    );
  });
}

BusinessDocument _document({
  required DocumentType type,
  required String number,
  required DocumentStatus status,
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
    date: DateTime(2026, 5, 1),
    lines: const [
      DocumentLine(
        productId: 'p1',
        label: 'Article',
        sku: 'ART',
        quantity: 2,
        unitHt: 100,
        tvaRate: TvaRate.rate19,
      ),
    ],
    warehouseId: 'main',
  );
}
