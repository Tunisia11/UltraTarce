import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/document_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/document_lifecycle_service.dart';
import 'package:ultra_trace/domain/services/payment_service.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test('create document with lines persists after reload', () async {
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(
        products: [testProduct()],
        partners: [testPartner()],
      ),
    );
    final repository = DocumentRepository(harness.appRepository);

    repository.upsert(testDocument(), status: 'Facture sauvegardée.');
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.documents.single.lines, hasLength(1));
  });

  test('add payment inserts payment and updates remaining amount', () async {
    final invoice = testDocument();
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(
        products: [testProduct()],
        partners: [testPartner()],
        documents: [invoice],
      ),
    );
    final repository = DocumentRepository(harness.appRepository);

    final updated = PaymentService.recordPayment(
      [invoice],
      invoice,
      PaymentEntry(
        id: 'pay1',
        date: DateTime(2026, 5, 1),
        amount: 239,
        method: PaymentMethod.cash,
      ),
      formatMoney: (value) => value.toStringAsFixed(3),
    );
    repository.upsert(updated, status: 'Paiement sauvegardé.');
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(restored!.documents.single.payments, hasLength(1));
    expect(restored.documents.single.remainingAmount, 0);
    expect(restored.documents.single.paymentStatus, PaymentStatus.paid);
  });

  test('document conversions persist after reload', () async {
    final quote = testDocument(
      id: 'dev1',
      type: DocumentType.devis,
      status: DocumentStatus.draft,
    );
    final harness = await createDriftRepositoryHarness(
      snapshot: testSnapshot(
        products: [testProduct()],
        partners: [testPartner()],
        documents: [quote],
      ),
    );
    final repository = DocumentRepository(harness.appRepository);

    final bl = DocumentLifecycleService.buildBlFromQuote(
      source: quote,
      id: 'bl1',
      number: 'BL-2026-0001',
      date: DateTime(2026, 5, 1),
    );
    repository.upsert(bl, status: 'BL sauvegardé.');
    final invoice = DocumentLifecycleService.buildInvoiceFromBl(
      source: bl,
      id: 'fac1',
      number: 'FAC-2026-0002',
      date: DateTime(2026, 5, 1),
      applyTimbreFiscal: true,
      timbreFiscalAmount: 1,
    );
    repository.upsert(invoice, status: 'Facture sauvegardée.');
    await harness.appRepository.flushPendingWrites();

    final restored = await harness.store.loadSnapshot();
    expect(
      restored!.documents.map((document) => document.type),
      contains(DocumentType.bl),
    );
    expect(
      restored.documents.map((document) => document.type),
      contains(DocumentType.facture),
    );
  });
}
