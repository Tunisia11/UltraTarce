import '../app_enums.dart';
import '../app_models.dart';
import 'tax_service.dart';

class PricingService {
  const PricingService._();

  static double grossHt({required int quantity, required double unitHt}) {
    return unitHt * quantity;
  }

  static double discountAmount({
    required int quantity,
    required double unitHt,
    required double discountRate,
  }) {
    return grossHt(quantity: quantity, unitHt: unitHt) *
        (discountRate.clamp(0, 100) / 100);
  }

  static double lineTotalHt({
    required int quantity,
    required double unitHt,
    required double discountRate,
  }) {
    return grossHt(quantity: quantity, unitHt: unitHt) -
        discountAmount(
          quantity: quantity,
          unitHt: unitHt,
          discountRate: discountRate,
        );
  }

  static double lineTvaAmount({
    required int quantity,
    required double unitHt,
    required double discountRate,
    required TvaRate tvaRate,
  }) {
    return TaxService.tvaAmount(
      taxableHt: lineTotalHt(
        quantity: quantity,
        unitHt: unitHt,
        discountRate: discountRate,
      ),
      rate: tvaRate,
    );
  }

  static double lineTotalTtc({
    required int quantity,
    required double unitHt,
    required double discountRate,
    required TvaRate tvaRate,
  }) {
    final totalHt = lineTotalHt(
      quantity: quantity,
      unitHt: unitHt,
      discountRate: discountRate,
    );
    return TaxService.totalTtc(taxableHt: totalHt, rate: tvaRate);
  }

  static double documentTotalHt(Iterable<DocumentLine> lines) {
    return lines.fold(0.0, (total, line) => total + line.totalHt);
  }

  static double documentTotalTva(Iterable<DocumentLine> lines) {
    return lines.fold(0.0, (total, line) => total + line.tvaAmount);
  }

  static double documentTotalTtc(Iterable<DocumentLine> lines) {
    return documentTotalHt(lines) + documentTotalTva(lines);
  }

  static double documentNetToPay({
    required Iterable<DocumentLine> lines,
    required bool applyTimbreFiscal,
    required double timbreFiscalAmount,
  }) {
    return documentTotalTtc(lines) +
        TaxService.timbreFiscalAmount(
          enabled: applyTimbreFiscal,
          configuredAmount: timbreFiscalAmount,
        );
  }

  static double documentDisplayNet(BusinessDocument document) {
    return documentNetToPay(
      lines: document.lines,
      applyTimbreFiscal: document.applyTimbreFiscal,
      timbreFiscalAmount: document.timbreFiscalAmount,
    );
  }
}
