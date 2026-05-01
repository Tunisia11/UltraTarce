import '../app_enums.dart';
import '../app_models.dart';

class InvoiceAccountingService {
  const InvoiceAccountingService._();

  static List<BusinessDocument> creditNotesForInvoice(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice, {
    bool validatedOnly = false,
  }) {
    return documents
        .where(
          (document) =>
              document.type == DocumentType.creditNote &&
              document.sourceNumber == invoice.number &&
              document.status != DocumentStatus.canceled &&
              (!validatedOnly || document.status == DocumentStatus.validated),
        )
        .toList();
  }

  static String lineReturnKey(DocumentLine line) =>
      '${line.productId}|${line.sku}|${line.unitHt}|${line.tvaRate.name}';

  static int creditedQuantityForLine(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
    DocumentLine line,
  ) {
    final key = lineReturnKey(line);
    return creditNotesForInvoice(documents, invoice).fold(0, (
      total,
      creditNote,
    ) {
      final credited = creditNote.lines
          .where((creditLine) => lineReturnKey(creditLine) == key)
          .fold(0, (lineTotal, creditLine) => lineTotal + creditLine.quantity);
      return total + credited;
    });
  }

  static int returnableQuantityForLine(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
    DocumentLine line,
  ) {
    return (line.quantity - creditedQuantityForLine(documents, invoice, line))
        .clamp(0, line.quantity)
        .toInt();
  }

  static bool invoiceHasReturnableLines(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    return invoice.lines.any(
      (line) => returnableQuantityForLine(documents, invoice, line) > 0,
    );
  }

  static double creditedAmountForInvoice(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    return creditNotesForInvoice(
      documents,
      invoice,
      validatedOnly: true,
    ).fold(0.0, (total, creditNote) => total + creditNote.netToPay);
  }

  static double invoiceNetAfterCredits(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    final credited = creditedAmountForInvoice(documents, invoice);
    return (invoice.netToPay - credited).clamp(0, invoice.netToPay).toDouble();
  }

  static double invoiceRemainingDue(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    final due = invoiceNetAfterCredits(documents, invoice) - invoice.paidAmount;
    return due.clamp(0, invoice.netToPay).toDouble();
  }

  static PaymentStatus effectivePaymentStatus(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    final effectiveNet = invoiceNetAfterCredits(documents, invoice);
    if (effectiveNet <= .001) return PaymentStatus.paid;
    if (invoice.paidAmount <= .001) return PaymentStatus.unpaid;
    if (invoice.paidAmount + .001 >= effectiveNet) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }

  static double documentDisplayNet(
    Iterable<BusinessDocument> documents,
    BusinessDocument document,
  ) {
    if (document.type != DocumentType.facture) return document.netToPay;
    return invoiceNetAfterCredits(documents, document);
  }

  static double salesCreditTotal(
    Iterable<BusinessDocument> documents, {
    bool Function(BusinessDocument document)? where,
  }) {
    return documents
        .where(
          (document) =>
              document.type == DocumentType.creditNote &&
              document.status == DocumentStatus.validated &&
              (where == null || where(document)),
        )
        .fold(0.0, (total, document) => total + document.netToPay);
  }
}
