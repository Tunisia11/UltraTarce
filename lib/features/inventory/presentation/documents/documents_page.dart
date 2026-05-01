part of '../inventory_shell_page.dart';

extension _InventoryDocumentsPage on _InventoryHomePageState {
  Widget _buildDocuments({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Documents',
          subtitle: 'Suivi avancé des ventes, paiements et PDF.',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _updateState(() => _section = Section.sales),
              icon: const Icon(Icons.add),
              label: const Text('Faire une vente'),
            ),
            OutlinedButton.icon(
              onPressed: _exportDocumentsCsv,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Exporter CSV'),
            ),
          ],
        ),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildDocumentsTable()),
              const SizedBox(width: 18),
              Expanded(
                flex: 5,
                child: _selectedDocument == null
                    ? const EmptyState(
                        text: 'Choisissez un document pour voir l’aperçu.',
                      )
                    : _buildDocumentPreview(_selectedDocument!),
              ),
            ],
          )
        else ...[
          _buildDocumentsTable(),
          const SizedBox(height: 18),
          if (_selectedDocument != null)
            _buildDocumentPreview(_selectedDocument!),
        ],
      ],
    );
  }

  Widget _buildDocumentsTable() {
    final draftCount = _documents
        .where((document) => document.status == DocumentStatus.draft)
        .length;
    return Panel(
      title: 'Documents',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SmallChip(label: '${_documents.length} document(s)'),
          SmallChip(
            label: '$draftCount à valider',
            color: draftCount == 0 ? AppColors.success : AppColors.warning,
          ),
        ],
      ),
      child: _documents.isEmpty
          ? const EmptyState(
              text: 'Aucun document pour le moment.',
              icon: Icons.description_outlined,
            )
          : Column(
              children: [
                for (final document in _documents)
                  _buildDocumentListCard(document),
              ],
            ),
    );
  }

  Widget _buildDocumentListCard(BusinessDocument document) {
    final selected = document.id == _selectedDocumentId;
    final children = _childDocumentsOf(document);
    final warehouse = _warehouseById(document.warehouseId);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: .06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: .35)
              : AppColors.border.withValues(alpha: .16),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _updateState(() => _selectedDocumentId = document.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                document.number,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              SmallChip(
                                label: document.type.shortLabel,
                                muted: true,
                              ),
                              _documentStatusChip(document),
                              if (document.type == DocumentType.facture)
                                _paymentStatusChip(document),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            document.partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              formatDate(document.date),
                              warehouse.code.isEmpty
                                  ? warehouse.name
                                  : warehouse.code,
                              if (document.sourceNumber != null)
                                'origine ${document.sourceNumber}',
                              if (children.isNotEmpty)
                                'suite ${children.map((child) => child.number).join(', ')}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Net',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          formatMoney(_documentDisplayNet(document)),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _documentPrimaryAction(document),
                    OutlinedButton.icon(
                      onPressed: () => _updateState(() {
                        _selectedDocumentId = document.id;
                      }),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('Voir'),
                    ),
                  ],
                ),
                if (document.type == DocumentType.facture &&
                    document.status == DocumentStatus.draft) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _blockedAction(
                        label: 'Paiement',
                        reason:
                            'Validez d’abord ${document.number} avant d’enregistrer un encaissement.',
                      ),
                      _blockedAction(
                        label: 'Avoir',
                        reason:
                            'Validez d’abord ${document.number} avant de préparer un avoir.',
                      ),
                    ],
                  ),
                ],
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 4),
                    title: const Text(
                      'Actions avancées',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: const Text('PDF, WhatsApp, retour, annulation.'),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _documentActions(document),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _documentPrimaryAction(BusinessDocument document) {
    if (document.status == DocumentStatus.draft) {
      return ElevatedButton.icon(
        onPressed: () => _validateDocument(document),
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Valider'),
      );
    }
    if (document.status != DocumentStatus.canceled &&
        document.type == DocumentType.bl &&
        _activeChildOf(document, DocumentType.facture) == null) {
      return ElevatedButton.icon(
        onPressed: () => _convertToInvoice(document),
        icon: const Icon(Icons.receipt_long_outlined, size: 16),
        label: const Text('Facturer'),
      );
    }
    if (document.status != DocumentStatus.canceled &&
        document.type == DocumentType.supplierOrder &&
        _activeChildOf(document, DocumentType.stockEntry) == null) {
      return ElevatedButton.icon(
        onPressed: () => _receiveSupplierOrder(document),
        icon: const Icon(Icons.inventory_2_outlined, size: 16),
        label: const Text('Réceptionner'),
      );
    }
    if (document.type == DocumentType.facture &&
        document.status == DocumentStatus.validated &&
        _invoiceRemainingDue(document) > .001) {
      return ElevatedButton.icon(
        onPressed: () => _showPaymentDialog(document),
        icon: const Icon(Icons.payments_outlined, size: 16),
        label: const Text('Encaisser'),
      );
    }
    return OutlinedButton.icon(
      onPressed: _pdfExportInProgress
          ? null
          : () => _exportDocumentPdf(document),
      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
      label: const Text('Télécharger PDF'),
    );
  }

  Widget _documentActions(BusinessDocument document) {
    final buttons = <Widget>[];
    if (document.status == DocumentStatus.draft) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _validateDocument(document),
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('Valider'),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _editDocumentDraft(document),
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Modifier'),
        ),
      );
    }
    if (document.status != DocumentStatus.canceled &&
        document.type == DocumentType.devis) {
      final existing = _activeChildOf(document, DocumentType.bl);
      buttons.add(
        existing == null
            ? OutlinedButton.icon(
                onPressed: () => _convertToBl(document),
                icon: const Icon(Icons.local_shipping_outlined, size: 16),
                label: const Text('Créer BL'),
              )
            : _blockedAction(
                label: 'BL existe',
                reason:
                    '${existing.number} existe déjà. Ouvrez-le pour continuer la chaîne sans doublon.',
              ),
      );
    }
    if (document.status != DocumentStatus.canceled &&
        document.type == DocumentType.bl) {
      final existing = _activeChildOf(document, DocumentType.facture);
      buttons.add(
        existing == null
            ? ElevatedButton.icon(
                onPressed: () => _convertToInvoice(document),
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: const Text('Facturer'),
              )
            : _blockedAction(
                label: 'Facture existe',
                reason:
                    '${existing.number} existe déjà. Ouvrez la facture existante pour éviter un doublon.',
                primary: true,
              ),
      );
    }
    if (document.status != DocumentStatus.canceled &&
        document.type == DocumentType.supplierOrder) {
      final existing = _activeChildOf(document, DocumentType.stockEntry);
      buttons.add(
        existing == null
            ? ElevatedButton.icon(
                onPressed: () => _receiveSupplierOrder(document),
                icon: const Icon(Icons.inventory_2_outlined, size: 16),
                label: const Text('Réceptionner'),
              )
            : _blockedAction(
                label: 'Déjà reçu',
                reason:
                    '${existing.number} existe déjà. La double réception créerait un stock faux.',
                primary: true,
              ),
      );
    }
    if (document.type == DocumentType.facture &&
        document.status != DocumentStatus.canceled) {
      if (document.status != DocumentStatus.validated) {
        buttons.add(
          _blockedAction(
            label: 'Avoir',
            reason:
                'Validez d’abord ${document.number} avant de préparer un avoir.',
          ),
        );
        buttons.add(
          _blockedAction(
            label: 'Paiement',
            reason:
                'Validez d’abord ${document.number} avant d’enregistrer un encaissement.',
          ),
        );
      } else {
        buttons.add(
          _invoiceHasReturnableLines(document)
              ? OutlinedButton.icon(
                  onPressed: () => _createCreditNoteFromInvoice(document),
                  icon: const Icon(Icons.undo_outlined, size: 16),
                  label: const Text('Avoir'),
                )
              : _blockedAction(
                  label: 'Avoir complet',
                  reason:
                      'Toutes les quantités de cette facture sont déjà couvertes par un avoir actif.',
                ),
        );
        buttons.add(
          _invoiceRemainingDue(document) <= .001
              ? _blockedAction(
                  label: 'Payée',
                  reason:
                      'Aucun paiement à ajouter: cette facture est déjà soldée.',
                )
              : OutlinedButton.icon(
                  onPressed: () => _showPaymentDialog(document),
                  icon: const Icon(Icons.payments_outlined, size: 16),
                  label: const Text('Paiement'),
                ),
        );
      }
    }
    if (document.status != DocumentStatus.canceled) {
      final cancelBlockReason = _cancelBlockReason(document);
      buttons.add(
        cancelBlockReason == null
            ? OutlinedButton.icon(
                onPressed: () => _cancelDocument(document),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text('Annuler'),
              )
            : _blockedAction(
                label: 'Annuler bloqué',
                reason: cancelBlockReason,
              ),
      );
    }
    buttons.add(
      OutlinedButton.icon(
        onPressed: _pdfExportInProgress
            ? null
            : () => _exportDocumentPdf(document),
        icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
        label: const Text('Télécharger PDF'),
      ),
    );
    if (document.type == DocumentType.facture ||
        document.type == DocumentType.devis ||
        document.type == DocumentType.bl) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _shareWhatsApp(document),
          icon: const Icon(Icons.share_outlined, size: 16),
          label: const Text('WhatsApp'),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: buttons);
  }

  Widget _blockedAction({
    required String label,
    required String reason,
    bool primary = false,
  }) {
    final button = primary
        ? ElevatedButton(onPressed: null, child: Text(label))
        : OutlinedButton(onPressed: null, child: Text(label));
    return Tooltip(message: reason, child: button);
  }

  Widget _documentStatusChip(BusinessDocument document) {
    switch (document.status) {
      case DocumentStatus.draft:
        return const SmallChip(label: 'Brouillon', color: AppColors.warning);
      case DocumentStatus.validated:
        return const SmallChip(label: 'Validé', color: AppColors.success);
      case DocumentStatus.canceled:
        return const SmallChip(label: 'Annulé', color: AppColors.danger);
    }
  }

  Widget _paymentStatusChip(BusinessDocument document) {
    final status = _effectivePaymentStatus(document);
    return SmallChip(
      label: status.label,
      color: switch (status) {
        PaymentStatus.unpaid => AppColors.danger,
        PaymentStatus.partial => AppColors.warning,
        PaymentStatus.paid => AppColors.success,
      },
    );
  }

  BusinessDocument? _documentByNumber(String? number) {
    if (number == null) return null;
    return _documents
        .where((document) => document.number == number)
        .firstOrNull;
  }

  List<BusinessDocument> _childDocumentsOf(BusinessDocument source) {
    return _documents
        .where(
          (document) =>
              document.sourceNumber == source.number &&
              document.status != DocumentStatus.canceled,
        )
        .toList();
  }

  void _selectDocument(BusinessDocument document) {
    _updateState(() {
      _selectedDocumentId = document.id;
      _section = Section.documents;
    });
  }
}
