import '../app_enums.dart';
import '../app_models.dart';
import 'invoice_accounting_service.dart';

class PaymentService {
  const PaymentService._();

  static double paidAmount(BusinessDocument document) {
    return document.payments.fold(
      0.0,
      (total, payment) => total + payment.amount,
    );
  }

  static double remainingAmount({
    required double netToPay,
    required double paidAmount,
  }) {
    return (netToPay - paidAmount).clamp(0, netToPay).toDouble();
  }

  static PaymentStatus status({
    required double netToPay,
    required double paidAmount,
  }) {
    if (paidAmount <= 0) return PaymentStatus.unpaid;
    if (paidAmount + .001 >= netToPay) return PaymentStatus.paid;
    return PaymentStatus.partial;
  }

  static double invoiceRemainingDue(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    return InvoiceAccountingService.invoiceRemainingDue(documents, invoice);
  }

  static PaymentStatus invoicePaymentStatus(
    Iterable<BusinessDocument> documents,
    BusinessDocument invoice,
  ) {
    return InvoiceAccountingService.effectivePaymentStatus(documents, invoice);
  }

  static String? paymentBlockReason(
    Iterable<BusinessDocument> documents,
    BusinessDocument document,
  ) {
    if (document.type != DocumentType.facture) {
      return 'Paiement bloqué. Seules les factures peuvent recevoir un encaissement.';
    }
    if (document.status == DocumentStatus.canceled) {
      return 'Paiement bloqué. ${document.number} est annulée; aucun encaissement ne doit être ajouté.';
    }
    if (document.status != DocumentStatus.validated) {
      return 'Paiement bloqué. ${document.number} doit être validée avant tout encaissement.';
    }
    final remainingDue = InvoiceAccountingService.invoiceRemainingDue(
      documents,
      document,
    );
    if (remainingDue <= .001) {
      return 'Paiement inutile. ${document.number} est déjà payée; aucun reste à encaisser.';
    }
    return null;
  }

  static String? paymentAmountError(
    Iterable<BusinessDocument> documents,
    BusinessDocument document,
    double amount, {
    required String Function(double value) formatMoney,
  }) {
    final remainingDue = InvoiceAccountingService.invoiceRemainingDue(
      documents,
      document,
    );
    if (amount <= 0 || amount - remainingDue > .001) {
      return 'Paiement refusé. Saisissez un montant entre 0 et ${formatMoney(remainingDue)}.';
    }
    return null;
  }

  static BusinessDocument recordPayment(
    Iterable<BusinessDocument> documents,
    BusinessDocument document,
    PaymentEntry payment, {
    required String Function(double value) formatMoney,
  }) {
    final blockReason = paymentBlockReason(documents, document);
    if (blockReason != null) {
      throw StateError(blockReason);
    }
    final amountError = paymentAmountError(
      documents,
      document,
      payment.amount,
      formatMoney: formatMoney,
    );
    if (amountError != null) {
      throw StateError(amountError);
    }
    return document.copyWith(payments: [...document.payments, payment]);
  }
}
