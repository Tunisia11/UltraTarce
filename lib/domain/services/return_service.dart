import '../app_enums.dart';
import '../app_models.dart';
import 'invoice_accounting_service.dart';

class ReturnService {
  const ReturnService._();

  static String? creditNoteBlockReason(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    if (invoice.type != DocumentType.facture) {
      return 'Avoir bloqué. Un avoir client doit être créé depuis une facture.';
    }
    if (invoice.status != DocumentStatus.validated) {
      return 'Avoir bloqué. ${invoice.number} doit être validée avant de créer un retour client.';
    }
    if (!InvoiceAccountingService.invoiceHasReturnableLines(
      documents,
      invoice,
    )) {
      return 'Avoir bloqué. Toutes les quantités de ${invoice.number} sont déjà couvertes par un avoir actif.';
    }
    return null;
  }

  static List<DocumentLine> returnableLines(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    return [
      for (final line in invoice.lines)
        if (InvoiceAccountingService.returnableQuantityForLine(
              documents,
              invoice,
              line,
            ) >
            0)
          line,
    ];
  }

  static String? selectedLinesError(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
    Iterable<DocumentLine> selectedLines,
  ) {
    final selected = selectedLines.toList();
    if (selected.isEmpty) {
      return 'Avoir vide refusé. Saisissez au moins une quantité retournée.';
    }

    final maxByKey = {
      for (final line in invoice.lines)
        InvoiceAccountingService.lineReturnKey(
          line,
        ): InvoiceAccountingService.returnableQuantityForLine(
          documents,
          invoice,
          line,
        ),
    };
    for (final line in selected) {
      final key = InvoiceAccountingService.lineReturnKey(line);
      final max = maxByKey[key] ?? 0;
      if (line.quantity <= 0 || line.quantity > max) {
        return 'Quantité retour invalide pour ${line.label}. Maximum: $max.';
      }
    }
    return null;
  }

  static BusinessDocument buildCreditNoteFromInvoice({
    required Iterable<BusinessDocument> documents,
    required BusinessDocument invoice,
    required List<DocumentLine> selectedLines,
    required String id,
    required String number,
    required DateTime date,
    required String note,
  }) {
    final blockReason = creditNoteBlockReason(documents, invoice);
    if (blockReason != null) {
      throw StateError(blockReason);
    }
    final selectedError = selectedLinesError(documents, invoice, selectedLines);
    if (selectedError != null) {
      throw StateError(selectedError);
    }
    return BusinessDocument(
      id: id,
      type: DocumentType.creditNote,
      number: number,
      status: DocumentStatus.draft,
      partnerId: invoice.partnerId,
      partnerName: invoice.partnerName,
      partnerTaxId: invoice.partnerTaxId,
      partnerAddress: invoice.partnerAddress,
      date: date,
      lines: selectedLines,
      warehouseId: invoice.warehouseId,
      companySnapshot: invoice.companySnapshot,
      sourceNumber: invoice.number,
      note: note.isEmpty ? 'Retour client lié à ${invoice.number}.' : note,
    );
  }
}
