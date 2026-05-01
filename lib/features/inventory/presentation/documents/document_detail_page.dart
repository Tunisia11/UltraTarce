part of '../inventory_shell_page.dart';

extension _InventoryDocumentDetailPage on _InventoryHomePageState {
  Widget _buildDocumentFlowStrip(BusinessDocument document) {
    final source = _documentByNumber(document.sourceNumber);
    final children = _childDocumentsOf(document);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Chaîne', style: TextStyle(fontWeight: FontWeight.w900)),
          if (source != null)
            DocumentLinkChip(
              label: source.number,
              muted: false,
              onTap: () => _selectDocument(source),
            )
          else
            const DocumentLinkChip(label: 'Origine directe', muted: true),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.muted),
          DocumentLinkChip(
            label: document.number,
            muted: false,
            onTap: () => _selectDocument(document),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: AppColors.muted),
          if (children.isEmpty)
            const DocumentLinkChip(label: 'Aucune suite', muted: true)
          else
            for (final child in children)
              DocumentLinkChip(
                label: child.number,
                muted: false,
                onTap: () => _selectDocument(child),
              ),
        ],
      ),
    );
  }

  Widget _buildDocumentSafetyBanner(BusinessDocument document) {
    final color = switch (document.status) {
      DocumentStatus.draft => AppColors.warning,
      DocumentStatus.validated => AppColors.success,
      DocumentStatus.canceled => AppColors.danger,
    };
    final title = switch (document.status) {
      DocumentStatus.draft => 'Brouillon modifiable',
      DocumentStatus.validated => 'Validé et verrouillé',
      DocumentStatus.canceled => 'Document annulé',
    };
    final stockText = switch (document.type) {
      DocumentType.devis => 'Aucun stock ne bouge sur un devis.',
      DocumentType.bl when document.stockApplied =>
        'Stock déjà sorti de ${_warehouseById(document.warehouseId).name}.',
      DocumentType.bl => 'Stock sortira uniquement à la validation.',
      DocumentType.facture when document.sourceNumber != null =>
        'Facture liée au BL ${document.sourceNumber}: pas de deuxième sortie stock.',
      DocumentType.facture when document.stockApplied =>
        'Facture directe validée: stock déjà sorti.',
      DocumentType.facture => 'Facture directe: stock sortira à la validation.',
      DocumentType.stockEntry when document.stockApplied =>
        'Entrée validée: stock déjà augmenté.',
      DocumentType.stockEntry => 'Stock augmentera à la validation.',
      DocumentType.creditNote when document.stockApplied =>
        'Avoir validé: stock déjà réintégré.',
      DocumentType.creditNote => 'Stock sera réintégré à la validation.',
      DocumentType.supplierOrder => 'Commande fournisseur sans stock.',
    };
    final paymentText = document.type == DocumentType.facture
        ? ' Paiement: ${_effectivePaymentStatus(document).label}, reste ${formatMoney(_invoiceRemainingDue(document))}.'
        : '';
    final statusText = document.status == DocumentStatus.canceled
        ? ' Les actions métier sont bloquées; le PDF reste consultable.'
        : document.status == DocumentStatus.validated
        ? ' Les lignes ne sont plus modifiables.'
        : ' Vous pouvez encore modifier les lignes avant validation.';
    return InlineNotice(
      icon: document.status == DocumentStatus.validated
          ? Icons.lock_outline
          : document.status == DocumentStatus.canceled
          ? Icons.block
          : Icons.edit_note_outlined,
      title: title,
      message: '$stockText$statusText$paymentText',
      color: color,
    );
  }

  Widget _buildDocumentPreview(BusinessDocument document) {
    final company = document.companySnapshot ?? _company;
    return Panel(
      title: 'Aperçu A4',
      trailing: OutlinedButton.icon(
        onPressed: _pdfExportInProgress
            ? null
            : () => _exportDocumentPdf(document),
        icon: const Icon(Icons.print_outlined),
        label: const Text('Télécharger PDF'),
      ),
      child: Center(
        child: Container(
          width: 620,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LogoImage(
                          source: company.logoSource,
                          fallbackText: company.name,
                          size: 58,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(_companyDisplayAddress(company)),
                              Text('MF: ${company.taxId}'),
                              Text('${company.phone} · ${company.email}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        document.type.label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(document.number),
                      Text(formatDate(document.date)),
                      const SizedBox(height: 4),
                      SmallChip(
                        label: document.status == DocumentStatus.canceled
                            ? 'Annulé'
                            : document.status == DocumentStatus.validated
                            ? 'Non modifiable'
                            : 'Brouillon',
                        color: document.status == DocumentStatus.canceled
                            ? AppColors.danger
                            : document.status == DocumentStatus.validated
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 28),
              Wrap(
                spacing: 18,
                runSpacing: 8,
                children: [
                  PreviewInfo(label: 'Tiers', value: document.partnerName),
                  PreviewInfo(
                    label: 'Matricule fiscal',
                    value: document.partnerTaxId,
                  ),
                  PreviewInfo(label: 'Adresse', value: document.partnerAddress),
                  PreviewInfo(
                    label: 'Magasin',
                    value: _warehouseById(document.warehouseId).name,
                  ),
                  if (document.sourceNumber != null)
                    PreviewInfo(
                      label: 'Origine',
                      value: document.sourceNumber!,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _buildDocumentFlowStrip(document),
              const SizedBox(height: 10),
              _buildDocumentSafetyBanner(document),
              const SizedBox(height: 18),
              PreviewLines(lines: document.lines),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(width: 280, child: _previewTotals(document)),
              ),
              const SizedBox(height: 18),
              Text(
                company.invoiceFooter.isEmpty
                    ? 'TVA calculée sur les prix hors taxe. Le transport de marchandises doit être accompagné par une facture, BL ou document équivalent.'
                    : '${company.invoiceFooter}\nTVA calculée sur les prix hors taxe. Le transport de marchandises doit être accompagné par une facture, BL ou document équivalent.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              if (document.lines.any(
                (line) => line.serialNumbers.isNotEmpty,
              )) ...[
                const SizedBox(height: 10),
                Text(
                  'N° série: ${document.lines.expand((line) => line.serialNumbers).join(', ')}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewTotals(BusinessDocument document) {
    return Column(
      children: [
        PreviewTotalRow(
          label: 'Total HT',
          value: formatMoney(_documentTotalHt(document)),
        ),
        for (final entry in _documentTvaBreakdown(document).entries)
          PreviewTotalRow(
            label: 'TVA ${entry.key.label}',
            value: formatMoney(entry.value),
          ),
        if (document.applyTimbreFiscal)
          PreviewTotalRow(
            label: 'Timbre fiscal',
            value: formatMoney(document.timbreFiscalAmount),
          ),
        const Divider(),
        PreviewTotalRow(
          label: 'Net à payer',
          value: formatMoney(_documentNetToPay(document)),
          strong: true,
        ),
      ],
    );
  }
}
