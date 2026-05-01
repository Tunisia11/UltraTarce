import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/domain/app_enums.dart';
import 'package:ultra_trace/domain/app_models.dart';
import 'package:ultra_trace/domain/services/tax_service.dart';

void main() {
  test('calculates Tunisian TVA and timbre fiscal', () {
    expect(TaxService.tvaAmount(taxableHt: 100, rate: TvaRate.rate19), 19);
    expect(TaxService.totalTtc(taxableHt: 100, rate: TvaRate.rate7), 107);
    expect(
      TaxService.timbreFiscalAmount(enabled: true, configuredAmount: 1),
      1,
    );
    expect(
      TaxService.timbreFiscalAmount(enabled: false, configuredAmount: 1),
      0,
    );
  });

  test('builds fiscal totals and TVA breakdown', () {
    final totals = TaxService.fiscalTotals(
      lines: [
        _line(quantity: 1, unitHt: 100, tvaRate: TvaRate.rate19),
        _line(quantity: 2, unitHt: 50, tvaRate: TvaRate.rate7),
      ],
      applyTimbreFiscal: true,
      timbreFiscalAmount: 1,
    );

    expect(totals.totalHt, 200);
    expect(totals.totalTva, 26);
    expect(totals.totalTtc, 226);
    expect(totals.timbreFiscal, 1);
    expect(totals.netToPay, 227);
    expect(totals.tvaBreakdown[TvaRate.rate19], 19);
    expect(totals.tvaBreakdown[TvaRate.rate7], closeTo(7, .000001));
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
