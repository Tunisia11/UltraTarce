import '../app_enums.dart';
import '../app_models.dart';

class FiscalTotals {
  const FiscalTotals({
    required this.totalHt,
    required this.totalTva,
    required this.totalTtc,
    required this.timbreFiscal,
    required this.netToPay,
    required this.tvaBreakdown,
  });

  final double totalHt;
  final double totalTva;
  final double totalTtc;
  final double timbreFiscal;
  final double netToPay;
  final Map<TvaRate, double> tvaBreakdown;
}

class TaxService {
  const TaxService._();

  static double tvaAmount({required double taxableHt, required TvaRate rate}) {
    return taxableHt * rate.multiplier;
  }

  static double totalTtc({required double taxableHt, required TvaRate rate}) {
    return taxableHt + tvaAmount(taxableHt: taxableHt, rate: rate);
  }

  static double timbreFiscalAmount({
    required bool enabled,
    required double configuredAmount,
  }) {
    return enabled ? configuredAmount : 0;
  }

  static Map<TvaRate, double> tvaBreakdown(Iterable<DocumentLine> lines) {
    final values = <TvaRate, double>{};
    for (final line in lines) {
      values[line.tvaRate] =
          (values[line.tvaRate] ?? 0) +
          tvaAmount(taxableHt: line.totalHt, rate: line.tvaRate);
    }
    return values;
  }

  static FiscalTotals fiscalTotals({
    required Iterable<DocumentLine> lines,
    required bool applyTimbreFiscal,
    required double timbreFiscalAmount,
  }) {
    final lineList = lines.toList();
    final totalHt = lineList.fold(0.0, (total, line) => total + line.totalHt);
    final totalTva = lineList.fold(
      0.0,
      (total, line) =>
          total + tvaAmount(taxableHt: line.totalHt, rate: line.tvaRate),
    );
    final totalTtc = totalHt + totalTva;
    final timbre = TaxService.timbreFiscalAmount(
      enabled: applyTimbreFiscal,
      configuredAmount: timbreFiscalAmount,
    );
    return FiscalTotals(
      totalHt: totalHt,
      totalTva: totalTva,
      totalTtc: totalTtc,
      timbreFiscal: timbre,
      netToPay: totalTtc + timbre,
      tvaBreakdown: tvaBreakdown(lineList),
    );
  }
}
