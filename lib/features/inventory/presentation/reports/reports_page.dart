part of '../inventory_shell_page.dart';

extension _InventoryReportsPage on _InventoryHomePageState {
  Widget _buildReports() {
    final validatedInvoices = _documents
        .where(
          (document) =>
              document.type == DocumentType.facture &&
              document.status == DocumentStatus.validated,
        )
        .toList();
    final validatedCreditNotes = _documents
        .where(
          (document) =>
              document.type == DocumentType.creditNote &&
              document.status == DocumentStatus.validated,
        )
        .toList();
    final salesByCustomer = <String, double>{};
    final salesByProduct = <String, double>{};
    final purchaseReceivedTotal = _documents
        .where(
          (document) =>
              document.type == DocumentType.stockEntry &&
              document.status != DocumentStatus.canceled,
        )
        .fold(0.0, (total, document) => total + _documentNetToPay(document));
    final purchaseCommittedTotal = _documents
        .where(
          (document) =>
              document.type == DocumentType.supplierOrder &&
              document.status != DocumentStatus.canceled &&
              _activeChildOf(document, DocumentType.stockEntry) == null,
        )
        .fold(0.0, (total, document) => total + _documentNetToPay(document));
    for (final invoice in validatedInvoices) {
      salesByCustomer[invoice.partnerName] =
          (salesByCustomer[invoice.partnerName] ?? 0) +
          _documentNetToPay(invoice);
      for (final line in invoice.lines) {
        salesByProduct[line.label] =
            (salesByProduct[line.label] ?? 0) + _lineTotalTtc(line);
      }
    }
    for (final creditNote in validatedCreditNotes) {
      salesByCustomer[creditNote.partnerName] =
          (salesByCustomer[creditNote.partnerName] ?? 0) -
          _documentNetToPay(creditNote);
      for (final line in creditNote.lines) {
        salesByProduct[line.label] =
            (salesByProduct[line.label] ?? 0) - _lineTotalTtc(line);
      }
    }
    final estimatedMargin = validatedInvoices.fold(0.0, (total, invoice) {
      var margin = 0.0;
      for (final line in invoice.lines) {
        final product = _productById(line.productId);
        margin += (line.unitHt - product.purchaseHt) * line.quantity;
      }
      return total + margin;
    });
    final creditMarginImpact = validatedCreditNotes.fold(0.0, (
      total,
      creditNote,
    ) {
      var impact = 0.0;
      for (final line in creditNote.lines) {
        final product = _productById(line.productId);
        impact += (line.unitHt - product.purchaseHt) * line.quantity;
      }
      return total + impact;
    });
    final grossSales = validatedInvoices.fold(
      0.0,
      (total, doc) => total + _documentNetToPay(doc),
    );
    final creditTotal = validatedCreditNotes.fold(
      0.0,
      (total, doc) => total + _documentNetToPay(doc),
    );
    final netSales = (grossSales - creditTotal).clamp(0, grossSales).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Rapports',
          subtitle:
              'Lecture rapide des ventes, achats, stock faible et marge estimée.',
        ),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            MetricCard(
              label: 'Ventes nettes',
              value: formatMoney(netSales),
              detail: 'Factures - avoirs',
              accent: AppColors.primary,
              icon: Icons.receipt_long_outlined,
            ),
            MetricCard(
              label: 'Achats reçus',
              value: formatMoney(purchaseReceivedTotal),
              detail: 'Bons d’entrée',
              accent: AppColors.cyan,
              icon: Icons.local_shipping_outlined,
            ),
            MetricCard(
              label: 'Marge estimée',
              value: formatMoney(estimatedMargin - creditMarginImpact),
              detail: 'Nette des avoirs',
              accent: AppColors.success,
              icon: Icons.trending_up,
            ),
            MetricCard(
              label: 'Stock faible',
              value: '${_lowStockProducts.length}',
              detail: 'À commander',
              accent: AppColors.warning,
              icon: Icons.warning_amber_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Panel(
          title: 'Avoirs et achats à suivre',
          child: Column(
            children: [
              ListRow(
                leading: Icons.undo_outlined,
                title: 'Avoirs validés',
                subtitle:
                    '${validatedCreditNotes.length} document(s) déduits des ventes',
                trailing: SmallChip(label: '-${formatMoney(creditTotal)}'),
              ),
              ListRow(
                leading: Icons.pending_actions_outlined,
                title: 'Commandes non réceptionnées',
                subtitle: 'Commandes fournisseur encore sans bon d’entrée lié',
                trailing: SmallChip(label: formatMoney(purchaseCommittedTotal)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'Ventes par client',
          child: _simpleReportTable(salesByCustomer),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'Ventes par produit',
          child: _simpleReportTable(salesByProduct),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'Stock faible',
          child: _lowStockProducts.isEmpty
              ? const EmptyState(text: 'Aucun produit sous seuil.')
              : Column(
                  children: [
                    for (final product in _lowStockProducts)
                      ListRow(
                        leading: Icons.inventory_2_outlined,
                        title: product.name,
                        subtitle:
                            '${product.sku} · stock ${product.totalStock} · min ${product.minStock}',
                        trailing: const SmallChip(label: 'À commander'),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _simpleReportTable(Map<String, double> values) {
    if (values.isEmpty) {
      return const EmptyState(text: 'Aucune donnée pour le moment.');
    }
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: [
        for (final entry in entries.take(8))
          ListRow(
            leading: Icons.bar_chart,
            title: entry.key,
            subtitle: 'Total validé',
            trailing: SmallChip(label: formatMoney(entry.value)),
          ),
      ],
    );
  }
}
