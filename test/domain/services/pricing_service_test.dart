import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/pricing_service.dart';

void main() {
  test('calculates line totals with discount and TVA', () {
    expect(PricingService.grossHt(quantity: 2, unitHt: 100), 200);
    expect(
      PricingService.discountAmount(quantity: 2, unitHt: 100, discountRate: 10),
      20,
    );
    expect(
      PricingService.lineTotalHt(quantity: 2, unitHt: 100, discountRate: 10),
      180,
    );
    expect(
      PricingService.lineTotalTtc(
        quantity: 2,
        unitHt: 100,
        discountRate: 10,
        tvaRate: TvaRate.rate19,
      ),
      214.2,
    );
  });

  test('calculates document totals and net a payer', () {
    final lines = [
      _line(quantity: 2, unitHt: 100, tvaRate: TvaRate.rate19),
      _line(quantity: 1, unitHt: 50, tvaRate: TvaRate.rate7),
    ];

    expect(PricingService.documentTotalHt(lines), 250);
    expect(PricingService.documentTotalTva(lines), 41.5);
    expect(PricingService.documentTotalTtc(lines), 291.5);
    expect(
      PricingService.documentNetToPay(
        lines: lines,
        applyTimbreFiscal: true,
        timbreFiscalAmount: 1,
      ),
      292.5,
    );
  });
}

DocumentLine _line({
  required int quantity,
  required double unitHt,
  required TvaRate tvaRate,
}) {
  return DocumentLine(
    productId: 'p1',
    label: 'Article',
    sku: 'ART',
    quantity: quantity,
    unitHt: unitHt,
    tvaRate: tvaRate,
  );
}
