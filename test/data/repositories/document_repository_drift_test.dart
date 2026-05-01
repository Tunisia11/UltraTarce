import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/repositories/document_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';

import 'drift_repository_test_helpers.dart';

void main() {
  test(
    'DocumentRepository writes documents with lines and payments through Drift',
    () async {
      final harness = await createDriftRepositoryHarness(
        snapshot: testSnapshot(
          products: [testProduct()],
          partners: [testPartner()],
        ),
      );
      final repository = DocumentRepository(harness.appRepository);
      final document = testDocument(
        payments: [
          PaymentEntry(
            id: 'pay1',
            date: DateTime(2026, 5, 1),
            amount: 100,
            method: PaymentMethod.cash,
          ),
        ],
      );

      repository.upsert(document, status: 'Facture créée.');
      await harness.appRepository.flushPendingWrites();

      final bundle = await harness.database.documentDao
          .getDocumentWithLinesAndPayments(document.id);
      expect(bundle, isNotNull);
      expect(bundle!.document.number, 'FAC-2026-0001');
      expect(bundle.lines, hasLength(1));
      expect(bundle.payments.single.amount, 100);
    },
  );
}
