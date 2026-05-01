import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/sequence_service.dart';

void main() {
  test('generates Devis, BL, Facture, and Avoir numbers without reset', () {
    final sequences = SequenceService.initialSequences();
    final now = DateTime(2026, 5, 1);

    expect(
      SequenceService.consumeNextNumber(
        sequences: sequences,
        type: DocumentType.devis,
        now: now,
      ),
      'DEV-2026-0001',
    );
    expect(
      SequenceService.consumeNextNumber(
        sequences: sequences,
        type: DocumentType.bl,
        now: now,
      ),
      'BL-2026-0001',
    );
    expect(
      SequenceService.consumeNextNumber(
        sequences: sequences,
        type: DocumentType.facture,
        now: now,
      ),
      'FAC-2026-0001',
    );
    expect(
      SequenceService.consumeNextNumber(
        sequences: sequences,
        type: DocumentType.creditNote,
        now: now,
      ),
      'AVR-2026-0001',
    );
    expect(
      SequenceService.consumeNextNumber(
        sequences: sequences,
        type: DocumentType.facture,
        now: now,
      ),
      'FAC-2026-0002',
    );
  });

  test('reconciles next sequence from existing documents for current year', () {
    final reconciled = SequenceService.reconcile(
      sequences: {DocumentType.facture: 2},
      documents: [
        _document(type: DocumentType.facture, number: 'FAC-2026-0007'),
        _document(type: DocumentType.facture, number: 'FAC-2025-0099'),
        _document(type: DocumentType.creditNote, number: 'AVR-2026-0003'),
      ],
      now: DateTime(2026, 5, 1),
    );

    expect(reconciled[DocumentType.facture], 8);
    expect(reconciled[DocumentType.creditNote], 4);
  });
}

BusinessDocument _document({
  required DocumentType type,
  required String number,
}) {
  return BusinessDocument(
    id: number,
    type: type,
    number: number,
    status: DocumentStatus.draft,
    partnerId: 'c1',
    partnerName: 'Client',
    partnerTaxId: '',
    partnerAddress: '',
    date: DateTime(2026, 5, 1),
    lines: const [],
    warehouseId: 'main',
  );
}
