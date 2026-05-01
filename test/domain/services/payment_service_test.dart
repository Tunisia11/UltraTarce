import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/payment_service.dart';

void main() {
  test('calculates remaining amount and partial payment status', () {
    expect(PaymentService.remainingAmount(netToPay: 119, paidAmount: 40), 79);
    expect(
      PaymentService.status(netToPay: 119, paidAmount: 40),
      PaymentStatus.partial,
    );
  });

  test('calculates full payment status and paid amount', () {
    final invoice = _invoice(
      payments: [
        PaymentEntry(
          id: 'pay-1',
          date: DateTime(2026, 5, 1),
          amount: 119,
          method: PaymentMethod.cash,
        ),
      ],
    );

    expect(PaymentService.paidAmount(invoice), 119);
    expect(PaymentService.invoiceRemainingDue([invoice], invoice), 0);
    expect(
      PaymentService.invoicePaymentStatus([invoice], invoice),
      PaymentStatus.paid,
    );
  });
}

BusinessDocument _invoice({List<PaymentEntry> payments = const []}) {
  return BusinessDocument(
    id: 'fac-1',
    type: DocumentType.facture,
    number: 'FAC-2026-0001',
    status: DocumentStatus.validated,
    partnerId: 'c1',
    partnerName: 'Client',
    partnerTaxId: '',
    partnerAddress: '',
    date: DateTime(2026, 5, 1),
    lines: const [
      DocumentLine(
        productId: 'p1',
        label: 'Article',
        sku: 'ART',
        quantity: 1,
        unitHt: 100,
        tvaRate: TvaRate.rate19,
      ),
    ],
    warehouseId: 'main',
    payments: payments,
  );
}
