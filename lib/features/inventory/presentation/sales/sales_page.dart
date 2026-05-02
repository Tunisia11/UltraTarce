part of '../inventory_shell_page.dart';

extension _InventorySalesPage on _InventoryHomePageState {
  Widget _buildSales({required bool isDesktop}) {
    final missingClient = _clients.where((client) => client.active).isEmpty;
    final missingProduct = _products.where((product) => product.active).isEmpty;
    if (missingClient || missingProduct) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: 'Faire une vente',
            subtitle:
                'Créez d’abord un client et un produit, puis Trace Ultra vous guide.',
          ),
          _buildGettingStartedPanel(),
        ],
      );
    }

    final successDocument = _lastSaleSuccessDocument;
    if (successDocument != null &&
        _editingDocumentId == null &&
        _draftLines.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: 'Faire une vente',
            subtitle:
                'Vente validée. Vous pouvez encaisser, télécharger le PDF ou repartir sur une nouvelle vente.',
          ),
          _buildSaleSuccessPanel(successDocument),
        ],
      );
    }

    final draftDocument = BusinessDocument(
      id: 'draft-preview',
      type: _newDocumentType,
      number: '${_newDocumentType.prefix}-${DateTime.now().year}-000X',
      status: DocumentStatus.draft,
      partnerId: _selectedClient.id,
      partnerName: _selectedClient.name,
      partnerTaxId: _selectedClient.taxId,
      partnerAddress: _selectedClient.address,
      date: DateTime.now(),
      lines: _draftLines,
      warehouseId: _selectedWarehouseId,
      companySnapshot: _company,
      note: 'Aperçu avant création.',
      applyTimbreFiscal:
          _newDocumentType == DocumentType.facture &&
          _company.timbreFiscalEnabled,
      timbreFiscalAmount: _company.timbreFiscalAmount,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Faire une vente',
          subtitle: _newDocumentType == DocumentType.bonSortie
              ? 'Préparez le départ du camion : transférez le stock du dépôt vers le véhicule.'
              : 'Client, produit, quantité, validation. Le reste est automatique.',
        ),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildDocumentComposer()),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    _buildSalesSpeedPanel(draftDocument),
                    if (_showAdvancedSaleOptions) ...[
                      const SizedBox(height: 18),
                      _buildDocumentPreview(draftDocument),
                    ],
                  ],
                ),
              ),
            ],
          )
        else ...[
          _buildDocumentComposer(),
          const SizedBox(height: 18),
          _buildSalesSpeedPanel(draftDocument),
          if (_showAdvancedSaleOptions) ...[
            const SizedBox(height: 18),
            _buildDocumentPreview(draftDocument),
          ],
        ],
      ],
    );
  }

  Widget _buildSaleSuccessPanel(BusinessDocument document) {
    final remainingDue = document.type == DocumentType.facture
        ? _invoiceRemainingDue(document)
        : 0.0;
    return Panel(
      key: _saleSuccessKey,
      title: 'Vente validée',
      icon: Icons.check_circle_outline,
      subtitle: 'Le document est prêt pour paiement, PDF ou consultation.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InlineNotice(
            icon: Icons.check_circle_outline,
            title: 'Vente terminée',
            message:
                '${document.partnerName} · ${formatMoney(_documentDisplayNet(document))} · ${_warehouseById(document.warehouseId).name}',
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: remainingDue > .001
                    ? () => _showPaymentDialog(document)
                    : null,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Encaisser paiement'),
              ),
              OutlinedButton.icon(
                onPressed: _pdfExportInProgress
                    ? null
                    : () => _exportDocumentPdf(document),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('Télécharger PDF'),
              ),
              OutlinedButton.icon(
                onPressed: () => _shareWhatsApp(document),
                icon: const Icon(Icons.share_outlined),
                label: const Text('Envoyer WhatsApp'),
              ),
              OutlinedButton.icon(
                onPressed: () => _updateState(() {
                  _selectedDocumentId = document.id;
                  _section = Section.documents;
                }),
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Voir document'),
              ),
              TextButton.icon(
                onPressed: () {
                  _updateState(() {
                    _lastSaleSuccessDocumentId = null;
                    _newDocumentType = DocumentType.facture;
                    _showAdvancedSaleOptions = false;
                  });
                  _focusProductSearchSoon();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Nouvelle vente'),
              ),
            ],
          ),
          if (remainingDue <= .001) ...[
            const SizedBox(height: 12),
            const SmallChip(label: 'Paiement soldé', color: AppColors.success),
          ],
        ],
      ),
    );
  }

  Widget _buildSalesSpeedPanel(BusinessDocument draftDocument) {
    final hasLines = draftDocument.lines.isNotEmpty;
    final stockWarnings = draftDocument.lines.where((line) {
      final product = _productById(line.productId);
      final remaining =
          product.stockIn(draftDocument.warehouseId) -
          _quantityForProductInLines(product.id, draftDocument.lines);
      return product.stockTracked && remaining <= product.minStock;
    }).toList();
    final actionLabel = _editingDocumentId == null
        ? (_showAdvancedSaleOptions
              ? 'Valider cette vente'
              : 'Valider la vente')
        : 'Mettre à jour le brouillon';

    return Panel(
      title: 'Résumé vente',
      icon: Icons.receipt_long_outlined,
      subtitle: 'Total TTC, net à payer et validation du document.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TotalItem(
                  label: 'Client',
                  value: draftDocument.partnerName,
                  strong: true,
                ),
              ),
              SmallChip(
                label: _showAdvancedSaleOptions
                    ? 'Options avancées'
                    : 'Vente rapide',
                color: _showAdvancedSaleOptions
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total TTC / Net à payer',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  formatMoney(_documentNetToPay(draftDocument)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${draftDocument.lines.length} ligne(s) · ${_selectedWarehouse.name}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (stockWarnings.isNotEmpty) ...[
            const SizedBox(height: 14),
            InlineNotice(
              icon: Icons.warning_amber_outlined,
              title: 'Stock à surveiller',
              message:
                  'Après ces lignes, stock faible sur ${stockWarnings.map((line) => line.sku).join(', ')}. Réduisez la quantité ou préparez un réassort si nécessaire.',
              color: AppColors.warning,
            ),
          ],
          const SizedBox(height: 14),
          InlineNotice(
            icon: Icons.verified_user_outlined,
            title: hasLines ? 'Prêt' : 'Ajoutez un produit',
            message: hasLines
                ? 'Validation, stock et document seront faits en une seule action.'
                : 'Ajoutez au moins un produit pour valider la vente.',
            color: hasLines ? AppColors.primary : AppColors.muted,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: _salesValidateKey,
              onPressed: hasLines
                  ? () =>
                        _createDocument(validateNow: _editingDocumentId == null)
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: Text(actionLabel),
            ),
          ),
          if (_editingDocumentId == null && _showAdvancedSaleOptions) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: hasLines ? () => _createDocument() : null,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Mettre en attente'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentComposer() {
    final selectableWarehouses = _warehouses
        .where(
          (warehouse) =>
              warehouse.active || warehouse.id == _selectedWarehouseId,
        )
        .toList();
    final showWarehousePicker = selectableWarehouses.length > 1;

    return Focus(
      focusNode: _salesShortcutFocusNode,
      onKeyEvent: _handleSalesKey,
      child: Panel(
        title: 'Vente rapide',
        subtitle: 'Recherchez un produit, ajustez la quantité, puis validez.',
        icon: Icons.point_of_sale_outlined,
        trailing: const SmallChip(label: 'Entrée pour ajouter'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _fieldBox(
                  width: 360,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_selectedClientId),
                    initialValue: _selectedClientId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Client'),
                    items: [
                      for (final client in _clients.where(
                        (client) =>
                            client.active || client.id == _selectedClientId,
                      ))
                        DropdownMenuItem(
                          value: client.id,
                          child: Text(
                            client.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _updateState(() => _selectedClientId = value);
                      _focusProductSearchSoon();
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showPartnerDialog(type: PartnerType.client),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Créer client'),
                ),
                if (showWarehousePicker)
                  _fieldBox(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('sale-$_selectedWarehouseId'),
                      initialValue: _selectedWarehouseId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Magasin'),
                      items: [
                        for (final warehouse in selectableWarehouses)
                          DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _updateState(() => _selectedWarehouseId = value);
                        _focusProductSearchSoon();
                      },
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SmallChip(
                      label: 'Magasin: ${_selectedWarehouse.name}',
                      color: AppColors.primary,
                    ),
                  ),
                if (_newDocumentType == DocumentType.bonSortie) ...[
                  const SizedBox(width: 12),
                  _fieldBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('target-$_selectedTargetWarehouseId'),
                      initialValue: _selectedTargetWarehouseId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Vers le dépôt (Camion)',
                      ),
                      items: [
                        for (final warehouse in _warehouses.where(
                          (w) => w.active && w.id != _selectedWarehouseId,
                        ))
                          DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(
                              warehouse.type == 'mobile'
                                  ? 'Camion · ${warehouse.name}'
                                  : warehouse.name,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _updateState(() => _selectedTargetWarehouseId = value);
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _buildSaleAdvancedOptions(),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  key: _salesProductSearchKey,
                  width: 560,
                  child: Autocomplete<Product>(
                    displayStringForOption: (product) =>
                        '${product.sku} · ${product.name}',
                    optionsBuilder: (textEditingValue) {
                      final query = textEditingValue.text.toLowerCase().trim();
                      final activeProducts = _products
                          .where((product) => product.active)
                          .toList();
                      if (query.isEmpty) return const Iterable<Product>.empty();
                      final matches =
                          activeProducts
                              .where(
                                (product) =>
                                    _productMatchesQuery(product, query),
                              )
                              .toList()
                            ..sort(
                              (a, b) => _productSearchScore(
                                a,
                                query,
                              ).compareTo(_productSearchScore(b, query)),
                            );
                      return matches.take(12);
                    },
                    onSelected: (product) {
                      _updateState(() => _selectedProductId = product.id);
                      _focusQuantitySoon();
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          _productSearchFocusNode = focusNode;
                          _activeProductSearchController = controller;
                          if (_productSearchController.text.isNotEmpty &&
                              controller.text.isEmpty) {
                            controller.text = _productSearchController.text;
                          }
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) {
                              _addDraftLine();
                              _focusProductSearchSoon();
                            },
                            decoration: InputDecoration(
                              labelText: 'Rechercher un produit',
                              hintText:
                                  'Rechercher un produit par nom, code ou SKU',
                              helperText:
                                  'Choisissez un produit, puis appuyez sur Entrée pour l’ajouter.',
                              prefixIcon: const Icon(Icons.search),
                            ),
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(8),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 540,
                              maxHeight: 260,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final product = options.elementAt(index);
                                final stock = product.stockIn(
                                  _selectedWarehouseId,
                                );
                                final remaining =
                                    stock -
                                    _quantityForProductInLines(
                                      product.id,
                                      _draftLines,
                                    ) -
                                    _selectedSalesQuantity();
                                final risky =
                                    product.stockTracked &&
                                    (remaining < 0 ||
                                        remaining <= product.minStock);
                                return InkWell(
                                  onTap: () => onSelected(product),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                product.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${product.sku} · ${product.category} · ${formatMoney(product.saleTtc)} TTC',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: AppColors.muted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        SmallChip(
                                          label: product.stockTracked
                                              ? 'Après: $remaining'
                                              : 'Non suivi',
                                          color: risky
                                              ? AppColors.warning
                                              : AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _fieldBox(
                  width: 178,
                  child: Row(
                    children: [
                      SquareIconButton(
                        icon: Icons.remove,
                        tooltip: 'Quantité -',
                        onPressed: () => _bumpQuantity(-1),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _quantityController,
                          focusNode: _quantityFocusNode,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addDraftLine(),
                          decoration: const InputDecoration(
                            labelText: 'Quantité',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SquareIconButton(
                        icon: Icons.add,
                        tooltip: 'Quantité +',
                        onPressed: () => _bumpQuantity(1),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addDraftLine,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter à la vente'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildSelectedProductStrip(),
            if (_salesFeedbackText != null) ...[
              const SizedBox(height: 10),
              InlineNotice(
                icon: _salesFeedbackIsError
                    ? Icons.error_outline
                    : Icons.done_all_outlined,
                title: _salesFeedbackIsError
                    ? 'Action bloquée'
                    : 'Produit ajouté',
                message: _salesFeedbackText!,
                color: _salesFeedbackIsError
                    ? AppColors.danger
                    : AppColors.success,
              ),
            ],
            const SizedBox(height: 18),
            _buildDraftLinesTable(),
            if (_draftLines.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildTotals(_draftLines),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => _updateState(() {
                  _draftLines.clear();
                  _editingDocumentId = null;
                }),
                icon: const Icon(Icons.clear),
                label: const Text('Vider la vente'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaleAdvancedOptions() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: .55),
        border: Border.all(color: AppColors.border.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded:
              _showAdvancedSaleOptions || _editingDocumentId != null,
          onExpansionChanged: (expanded) =>
              _updateState(() => _showAdvancedSaleOptions = expanded),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(Icons.tune_outlined),
          title: const Text(
            'Options avancées',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: const Text(
            'À utiliser seulement pour les cas non standard.',
          ),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _fieldBox(
                  width: 140,
                  child: TextField(
                    controller: _discountController,
                    focusNode: _discountFocusNode,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addDraftLine(),
                    decoration: const InputDecoration(labelText: 'Remise %'),
                  ),
                ),
                _fieldBox(
                  child: DropdownButtonFormField<DocumentType>(
                    key: ValueKey(_newDocumentType),
                    initialValue: _newDocumentType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Document interne',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: DocumentType.facture,
                        child: Text('Vente directe'),
                      ),
                      DropdownMenuItem(
                        value: DocumentType.bl,
                        child: Text('Livraison avant paiement'),
                      ),
                      DropdownMenuItem(
                        value: DocumentType.devis,
                        child: Text('Proposition / devis'),
                      ),
                      DropdownMenuItem(
                        value: DocumentType.bonSortie,
                        child: Text('Bon de sortie (Transfert Camion)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (_editingDocumentId != null) return;
                      if (value == null) return;
                      _updateState(() => _newDocumentType = value);
                      _focusProductSearchSoon();
                    },
                  ),
                ),
                const SmallChip(
                  label: 'Masqué du flux normal',
                  color: AppColors.warning,
                ),
                if (_selectedClient.taxId.isNotEmpty)
                  SmallChip(label: 'MF: ${_selectedClient.taxId}', muted: true),
                if (_selectedClient.address.isNotEmpty)
                  SmallChip(label: 'Adresse client enregistrée', muted: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedProductStrip() {
    final stock = _selectedProduct.stockIn(_selectedWarehouseId);
    final remainingAfterAdd = _stockRemainingAfterAdding(_selectedProduct);
    final low =
        _selectedProduct.stockTracked &&
        remainingAfterAdd <= _selectedProduct.minStock;
    final insufficient = _selectedProduct.stockTracked && remainingAfterAdd < 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insufficient
            ? AppColors.danger.withValues(alpha: .08)
            : low
            ? AppColors.warning.withValues(alpha: .10)
            : AppColors.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: insufficient
              ? AppColors.danger.withValues(alpha: .35)
              : low
              ? AppColors.warning.withValues(alpha: .35)
              : AppColors.primary.withValues(alpha: .25),
        ),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            _selectedProduct.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          SmallChip(label: _selectedProduct.sku),
          SmallChip(label: 'Quantité ${_selectedSalesQuantity()}'),
          SmallChip(label: '${formatMoney(_selectedProduct.saleTtc)} TTC'),
          SmallChip(label: 'TVA ${_selectedProduct.tvaRate.label}'),
          SmallChip(
            label: _selectedProduct.stockTracked
                ? 'Stock actuel $stock'
                : 'Stock non suivi',
            color: low ? AppColors.warning : AppColors.primary,
          ),
          if (_selectedProduct.stockTracked && (low || insufficient))
            SmallChip(
              label: 'Après ajout $remainingAfterAdd',
              color: insufficient
                  ? AppColors.danger
                  : low
                  ? AppColors.warning
                  : AppColors.primary,
            ),
          SmallChip(
            label: _selectedWarehouse.code.isEmpty
                ? _selectedWarehouse.name
                : _selectedWarehouse.code,
            muted: true,
          ),
          if (insufficient)
            const SmallChip(
              label: 'Stock insuffisant',
              color: AppColors.danger,
            ),
          if (low)
            const SmallChip(label: 'Stock faible', color: AppColors.warning),
          if (_selectedProduct.serialTracked)
            const SmallChip(label: 'N° série'),
        ],
      ),
    );
  }

  Widget _buildDraftLinesTable() {
    if (_draftLines.isEmpty) {
      return const EmptyState(
        text:
            'Cherchez un produit, choisissez la quantité, puis appuyez sur Entrée.',
        icon: Icons.keyboard_return,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < _draftLines.length; index++) ...[
          _buildDraftLineCard(index),
          if (index != _draftLines.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildDraftLineCard(int index) {
    final line = _draftLines[index];
    final product = _productById(line.productId);
    final available = product.stockIn(_selectedWarehouseId);
    final remainingAfterDocument =
        available - _quantityForProductInLines(product.id, _draftLines);
    final low =
        product.stockTracked && remainingAfterDocument <= product.minStock;
    final insufficient = product.stockTracked && remainingAfterDocument < 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: insufficient
            ? AppColors.danger.withValues(alpha: .07)
            : low
            ? AppColors.warning.withValues(alpha: .07)
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: insufficient
              ? AppColors.danger.withValues(alpha: .35)
              : low
              ? AppColors.warning.withValues(alpha: .35)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    SmallChip(label: line.sku, muted: true),
                    if (line.discountRate > 0)
                      SmallChip(
                        label:
                            'Remise ${line.discountRate.toStringAsFixed(1)}%',
                        color: AppColors.cyan,
                      ),
                    if (product.stockTracked && (low || insufficient))
                      SmallChip(
                        label: 'Après vente $remainingAfterDocument',
                        color: insufficient
                            ? AppColors.danger
                            : AppColors.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          LineQuantityStepper(
            quantity: line.quantity,
            onMinus: () => _updateDraftLineQuantity(index, line.quantity - 1),
            onPlus: () => _updateDraftLineQuantity(index, line.quantity + 1),
            onSubmitted: (value) => _updateDraftLineQuantity(index, value),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 126,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(_lineTotalTtc(line)),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${formatMoney(line.unitHt)} HT/u',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (product.serialTracked)
            OutlinedButton(
              onPressed: () => _chooseLineSerials(index),
              child: Text(
                line.serialNumbers.isEmpty
                    ? 'Séries'
                    : '${line.serialNumbers.length}/${line.quantity}',
              ),
            ),
          IconButton(
            tooltip: 'Retirer',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _updateState(() => _draftLines.removeAt(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(List<DocumentLine> lines) {
    final fiscalTotals = TaxService.fiscalTotals(
      lines: lines,
      applyTimbreFiscal:
          _newDocumentType == DocumentType.facture &&
          _company.timbreFiscalEnabled,
      timbreFiscalAmount: _company.timbreFiscalAmount,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                TotalItem(
                  label: 'HT',
                  value: formatMoney(fiscalTotals.totalHt),
                ),
                TotalItem(
                  label: 'TVA',
                  value: formatMoney(fiscalTotals.totalTva),
                ),
                if (fiscalTotals.timbreFiscal > 0)
                  TotalItem(
                    label: 'Timbre',
                    value: formatMoney(fiscalTotals.timbreFiscal),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Net à payer',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              Text(
                formatMoney(fiscalTotals.netToPay),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
