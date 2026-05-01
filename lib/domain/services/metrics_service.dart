import '../../core/iterable_extensions.dart';
import '../app_enums.dart';
import '../app_models.dart';
import 'invoice_accounting_service.dart';

class DashboardMetrics {
  const DashboardMetrics({
    required this.dailySales,
    required this.monthlySales,
    required this.unpaidAmount,
    required this.lowStockCount,
    required this.draftDocumentCount,
  });

  final double dailySales;
  final double monthlySales;
  final double unpaidAmount;
  final int lowStockCount;
  final int draftDocumentCount;
}

class RecentActivitySummary {
  const RecentActivitySummary({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final double? trailing;
}

class MetricsService {
  const MetricsService._();

  static bool sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static double dailySales(
    Iterable<BusinessDocument> documents, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final invoices = documents
        .where(
          (document) =>
              document.type == DocumentType.facture &&
              document.status == DocumentStatus.validated &&
              sameDay(document.date, current),
        )
        .fold(0.0, (total, document) => total + document.netToPay);
    final credits = InvoiceAccountingService.salesCreditTotal(
      documents,
      where: (document) => sameDay(document.date, current),
    );
    return (invoices - credits).clamp(0, invoices).toDouble();
  }

  static double monthlySales(
    Iterable<BusinessDocument> documents, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final invoices = documents
        .where(
          (document) =>
              document.type == DocumentType.facture &&
              document.status == DocumentStatus.validated &&
              document.date.year == current.year &&
              document.date.month == current.month,
        )
        .fold(0.0, (total, document) => total + document.netToPay);
    final credits = InvoiceAccountingService.salesCreditTotal(
      documents,
      where: (document) =>
          document.date.year == current.year &&
          document.date.month == current.month,
    );
    return (invoices - credits).clamp(0, invoices).toDouble();
  }

  static List<Product> lowStockProducts(Iterable<Product> products) {
    return products
        .where(
          (product) =>
              product.active &&
              product.stockTracked &&
              product.totalStock <= product.minStock,
        )
        .toList();
  }

  static List<BusinessDocument> draftDocuments(
    Iterable<BusinessDocument> documents,
  ) {
    return documents
        .where((document) => document.status == DocumentStatus.draft)
        .toList();
  }

  static double unpaidAmount(Iterable<BusinessDocument> documents) {
    return documents
        .where(
          (document) =>
              document.type == DocumentType.facture &&
              document.status == DocumentStatus.validated,
        )
        .fold(
          0.0,
          (total, invoice) =>
              total +
              InvoiceAccountingService.invoiceRemainingDue(documents, invoice),
        );
  }

  static DashboardMetrics dashboardMetrics({
    required Iterable<BusinessDocument> documents,
    required Iterable<Product> products,
    DateTime? now,
  }) {
    return DashboardMetrics(
      dailySales: dailySales(documents, now: now),
      monthlySales: monthlySales(documents, now: now),
      unpaidAmount: unpaidAmount(documents),
      lowStockCount: lowStockProducts(products).length,
      draftDocumentCount: draftDocuments(documents).length,
    );
  }

  static List<MapEntry<Product, int>> bestSellers(
    Iterable<BusinessDocument> documents,
    Iterable<Product> products, {
    int limit = 4,
  }) {
    final quantities = <String, int>{};
    for (final document in documents.where(
      (document) =>
          (document.type == DocumentType.facture ||
              document.type == DocumentType.creditNote) &&
          document.status == DocumentStatus.validated,
    )) {
      for (final line in document.lines) {
        final delta = document.type == DocumentType.creditNote
            ? -line.quantity
            : line.quantity;
        quantities[line.productId] = (quantities[line.productId] ?? 0) + delta;
      }
    }
    final result = [
      for (final entry in quantities.entries)
        if (entry.value > 0)
          products
              .where((product) => product.id == entry.key)
              .map((product) => MapEntry(product, entry.value))
              .firstOrNull,
    ].whereType<MapEntry<Product, int>>().toList();
    result.sort((a, b) => b.value.compareTo(a.value));
    return result.take(limit).toList();
  }

  static List<RecentActivitySummary> recentActivitySummaries(
    Iterable<BusinessDocument> documents, {
    int limit = 5,
  }) {
    return documents
        .take(limit)
        .map(
          (document) => RecentActivitySummary(
            title: document.number,
            subtitle: '${document.type.label} · ${document.partnerName}',
            trailing: InvoiceAccountingService.documentDisplayNet(
              documents,
              document,
            ),
          ),
        )
        .toList();
  }
}
