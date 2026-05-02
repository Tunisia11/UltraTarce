part of '../inventory_shell_page.dart';

extension _InventoryWorkflows on _InventoryHomePageState {
  Future<void> _showWarehouseDialog([Warehouse? warehouse]) async {
    final name = TextEditingController(text: warehouse?.name ?? '');
    final code = TextEditingController(text: warehouse?.code ?? '');
    final city = TextEditingController(text: warehouse?.city ?? '');
    final address = TextEditingController(text: warehouse?.address ?? '');
    var active = warehouse?.active ?? true;
    var type = warehouse?.type ?? 'depot';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(warehouse == null ? 'Nouveau dépôt' : 'Modifier dépôt'),
          content: SizedBox(
            width: 520,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dialogField(width: 300, controller: name, label: 'Nom'),
                _dialogField(width: 140, controller: code, label: 'Code'),
                _dialogField(width: 180, controller: city, label: 'Ville'),
                _dialogField(width: 440, controller: address, label: 'Adresse'),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Type de dépôt',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'depot',
                        child: Text('🏠 Dépôt fixe'),
                      ),
                      DropdownMenuItem(
                        value: 'mobile',
                        child: Text('🚚 Unité mobile (Camion)'),
                      ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => type = value ?? 'depot'),
                  ),
                ),
                _switchTile(
                  label: 'Actif',
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.text.trim().isEmpty || code.text.trim().isEmpty) {
                  _showMessage('Nom et code obligatoires.', isError: true);
                  return;
                }
                final updated = Warehouse(
                  id: warehouse?.id ?? _newId('dep'),
                  name: name.text.trim(),
                  city: city.text.trim(),
                  code: code.text.trim(),
                  address: address.text.trim(),
                  active: active,
                  type: type,
                );
                _updateState(() {
                  final cubit = _warehouseCubit;
                  if (warehouse == null) {
                    cubit.createWarehouse(updated);
                  } else {
                    cubit.updateWarehouse(updated);
                  }
                  _applyRepositoryState();
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteWarehouse(Warehouse warehouse) {
    final result = _warehouseCubit.deleteOrArchiveWarehouse(warehouse);
    _updateState(() => _applyRepositoryState());
    if (result.archived) {
      _showMessage('Dépôt utilisé: il a été désactivé.');
    }
  }

  void _deleteProduct(Product product) {
    _productsCubit.deleteOrArchiveProduct(product);
    _updateState(() => _applyRepositoryState());
  }

  Future<void> _showCategoryDialog([Category? category]) async {
    final name = TextEditingController(text: category?.name ?? '');
    var active = category?.active ?? true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(
            category == null ? 'Nouvelle catégorie' : 'Modifier catégorie',
          ),
          content: SizedBox(
            width: 420,
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _dialogField(width: 280, controller: name, label: 'Nom'),
                _switchTile(
                  label: 'Active',
                  value: active,
                  onChanged: (value) => setDialogState(() => active = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final cleanName = name.text.trim();
                if (cleanName.isEmpty) {
                  _showMessage('Nom obligatoire.', isError: true);
                  return;
                }
                final categoryCubit = _categoryCubit;
                final duplicate = categoryCubit.hasDuplicateName(
                  cleanName,
                  exceptId: category?.id,
                );
                if (duplicate) {
                  _showMessage('Catégorie déjà utilisée.', isError: true);
                  return;
                }
                _updateState(() {
                  if (category == null) {
                    categoryCubit.createCategory(
                      Category(
                        id: _newId('cat'),
                        name: cleanName,
                        active: active,
                      ),
                    );
                  } else {
                    categoryCubit.updateCategory(
                      category.copyWith(name: cleanName, active: active),
                      oldName: category.name,
                    );
                  }
                  _applyRepositoryState();
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteCategory(Category category) {
    final result = _categoryCubit.deleteOrArchiveCategory(category);
    _updateState(() => _applyRepositoryState());
    if (result.archived) {
      _showMessage('Catégorie utilisée: elle a été désactivée.');
    }
  }

  double _parseAmount(String raw, {double fallback = 0}) {
    return double.tryParse(raw.trim().replaceAll(',', '.')) ?? fallback;
  }

  Product _productById(String id) =>
      _products.firstWhere((product) => product.id == id);

  Warehouse? _warehouseByIdOrNull(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final warehouse in _warehouses) {
      if (warehouse.id == id) return warehouse;
    }
    return null;
  }

  Warehouse _warehouseById(String? id) {
    final warehouse = _warehouseByIdOrNull(id);
    if (warehouse != null) return warehouse;
    return const Warehouse(
      id: 'missing',
      name: 'Dépôt introuvable',
      city: '',
      code: '???',
      address: '',
    );
  }

  String _generatedSerial(String sku, int index) =>
      'SN-$sku-${DateTime.now().microsecondsSinceEpoch}-$index';

  String _nextMovementNumber(String prefix) =>
      StockIntegrityService.nextMovementNumber(_movements, prefix);

  BusinessDocument? _activeChildOf(
    BusinessDocument source,
    DocumentType targetType,
  ) {
    return DocumentLifecycleService.activeChildOf(
      _documents,
      source,
      targetType,
    );
  }

  String _lineReturnKey(DocumentLine line) =>
      InvoiceAccountingService.lineReturnKey(line);

  int _returnableQuantityForLine(BusinessDocument invoice, DocumentLine line) {
    return InvoiceAccountingService.returnableQuantityForLine(
      _documents,
      invoice,
      line,
    );
  }

  bool _invoiceHasReturnableLines(BusinessDocument invoice) {
    return InvoiceAccountingService.invoiceHasReturnableLines(
      _documents,
      invoice,
    );
  }

  double _creditedAmountForInvoice(BusinessDocument invoice) {
    return InvoiceAccountingService.creditedAmountForInvoice(
      _documents,
      invoice,
    );
  }

  double _invoiceNetAfterCredits(BusinessDocument invoice) {
    return InvoiceAccountingService.invoiceNetAfterCredits(_documents, invoice);
  }

  double _invoiceRemainingDue(BusinessDocument invoice) {
    return PaymentService.invoiceRemainingDue(_documents, invoice);
  }

  PaymentStatus _effectivePaymentStatus(BusinessDocument invoice) {
    return PaymentService.invoicePaymentStatus(_documents, invoice);
  }

  double _documentDisplayNet(BusinessDocument document) {
    return InvoiceAccountingService.documentDisplayNet(_documents, document);
  }

  double _documentTotalHt(BusinessDocument document) {
    return PricingService.documentTotalHt(document.lines);
  }

  double _documentTotalTva(BusinessDocument document) {
    return PricingService.documentTotalTva(document.lines);
  }

  double _documentNetToPay(BusinessDocument document) {
    return PricingService.documentNetToPay(
      lines: document.lines,
      applyTimbreFiscal: document.applyTimbreFiscal,
      timbreFiscalAmount: document.timbreFiscalAmount,
    );
  }

  double _lineTotalTtc(DocumentLine line) {
    return PricingService.lineTotalTtc(
      quantity: line.quantity,
      unitHt: line.unitHt,
      discountRate: line.discountRate,
      tvaRate: line.tvaRate,
    );
  }

  Map<TvaRate, double> _documentTvaBreakdown(BusinessDocument document) {
    return TaxService.tvaBreakdown(document.lines);
  }

  double _paidAmount(BusinessDocument document) {
    return PaymentService.paidAmount(document);
  }

  int _selectedSalesQuantity() {
    final quantity = int.tryParse(_quantityController.text.trim());
    return quantity == null || quantity <= 0 ? 1 : quantity;
  }

  int _quantityForProductInLines(String productId, List<DocumentLine> lines) {
    return StockMutationService.quantityForProductInLines(productId, lines);
  }

  int _stockRemainingAfterAdding(Product product) {
    return StockMutationService.stockRemainingAfterAdding(
      product: product,
      warehouseId: _selectedWarehouseId,
      draftLines: _draftLines,
      selectedQuantity: _selectedSalesQuantity(),
    );
  }

  bool _salesDocumentNeedsStock(DocumentType type) =>
      DocumentLifecycleService.salesDocumentNeedsStock(type);

  bool _productMatchesQuery(Product product, String query) {
    return product.name.toLowerCase().contains(query) ||
        product.sku.toLowerCase().contains(query) ||
        product.category.toLowerCase().contains(query) ||
        product.brand.toLowerCase().contains(query) ||
        (product.barcode?.toLowerCase().contains(query) ?? false);
  }

  int _productSearchScore(Product product, String query) {
    final sku = product.sku.toLowerCase();
    final name = product.name.toLowerCase();
    final barcode = product.barcode?.toLowerCase();
    if (barcode == query || sku == query) return 0;
    if (sku.startsWith(query)) return 1;
    if (name.startsWith(query)) return 2;
    if (barcode?.startsWith(query) ?? false) return 3;
    return 4;
  }

  List<_GlobalSearchResult> _globalSearchResults(String rawQuery) {
    final query = rawQuery.toLowerCase().trim();
    if (query.isEmpty) return const [];

    final results = <_GlobalSearchResult>[];
    final products =
        _products
            .where((product) => _productMatchesQuery(product, query))
            .toList()
          ..sort(
            (a, b) => _productSearchScore(
              a,
              query,
            ).compareTo(_productSearchScore(b, query)),
          );
    for (final product in products.take(6)) {
      results.add(
        _GlobalSearchResult(
          kind: _GlobalSearchKind.product,
          id: product.id,
          title: product.name,
          subtitle:
              'Produit · ${product.sku} · Stock ${product.totalStock} · ${formatMoney(product.saleTtc)} TTC',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    final partners = _partners.where((partner) {
      final haystack = [
        partner.name,
        partner.companyName,
        partner.contactName,
        partner.taxId,
        partner.phone,
        partner.email,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
    for (final partner in partners.take(5)) {
      final isClient = partner.type == PartnerType.client;
      results.add(
        _GlobalSearchResult(
          kind: isClient
              ? _GlobalSearchKind.client
              : _GlobalSearchKind.supplier,
          id: partner.id,
          title: partner.name,
          subtitle:
              '${isClient ? 'Client' : 'Fournisseur'} · ${partner.taxId.isEmpty ? partner.phone : partner.taxId}',
          icon: isClient ? Icons.groups_2_outlined : Icons.handshake_outlined,
        ),
      );
    }

    final documents = _documents.where((document) {
      final haystack = [
        document.number,
        document.partnerName,
        document.partnerTaxId,
        document.type.label,
        document.type.shortLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
    for (final document in documents.take(6)) {
      results.add(
        _GlobalSearchResult(
          kind: _GlobalSearchKind.document,
          id: document.id,
          title: document.number,
          subtitle:
              'Document · ${document.partnerName} · ${formatMoney(_documentDisplayNet(document))}',
          icon: Icons.description_outlined,
        ),
      );
    }

    return results.take(10).toList();
  }

  void _openGlobalSearchResult(_GlobalSearchResult result) {
    _updateState(() {
      switch (result.kind) {
        case _GlobalSearchKind.product:
          _section = Section.products;
          _selectedProductId = result.id;
          _productQuery = result.title;
          _productFilterController.text = result.title;
          break;
        case _GlobalSearchKind.client:
          _section = Section.customers;
          _selectedClientId = result.id;
          break;
        case _GlobalSearchKind.supplier:
          _section = Section.suppliers;
          _selectedSupplierId = result.id;
          break;
        case _GlobalSearchKind.document:
          _section = Section.documents;
          _selectedDocumentId = result.id;
          break;
      }
    });
  }

  String _stockEffectHintFor(DocumentType type) =>
      DocumentLifecycleService.stockEffectHintFor(type);

  String? _stockErrorFor(List<DocumentLine> lines, String warehouseId) {
    return StockService.stockAvailabilityErrorFor(
      lines: lines,
      warehouseId: warehouseId,
      productById: _productById,
      warehouseNameById: (warehouseId) => _warehouseById(warehouseId).name,
    );
  }

  String? _serialSelectionErrorFor(
    List<DocumentLine> lines,
    String warehouseId,
  ) {
    return StockService.serialSelectionErrorFor(
      lines: lines,
      warehouseId: warehouseId,
      productById: _productById,
    );
  }

  String? _inboundSerialErrorFor(List<DocumentLine> lines, String warehouseId) {
    return StockIntegrityService.inboundSerialErrorFor(
      lines: lines,
      warehouseId: warehouseId,
      productById: _productById,
    );
  }

  void _addDraftLine() {
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _setSalesFeedback(
        'Quantité invalide. Saisissez un nombre supérieur à zéro, puis appuyez sur Entrée.',
        isError: true,
      );
      _showMessage(
        'Quantité invalide. Saisissez un nombre supérieur à zéro.',
        isError: true,
      );
      return;
    }

    final product = _selectedProduct;
    final discountRate =
        double.tryParse(_discountController.text.trim().replaceAll(',', '.')) ??
        0;
    final newLine = DocumentLine(
      productId: product.id,
      label: product.name,
      sku: product.sku,
      quantity: quantity,
      unitHt: product.saleHt,
      tvaRate: product.tvaRate,
      discountRate: discountRate.clamp(0, 100).toDouble(),
    );

    final needsStockCheck = _salesDocumentNeedsStock(_newDocumentType);
    if (needsStockCheck) {
      final error = _stockErrorFor([
        ..._draftLines,
        newLine,
      ], _selectedWarehouseId);
      if (error != null) {
        _setSalesFeedback(error, isError: true);
        _showMessage(error, isError: true);
        return;
      }
    }

    final existingQuantity = _quantityForProductInLines(
      product.id,
      _draftLines,
    );
    final lineQuantityAfterAdd = existingQuantity + quantity;
    final remaining =
        product.stockIn(_selectedWarehouseId) - lineQuantityAfterAdd;
    _updateState(() {
      final existingIndex = _draftLines.indexWhere(
        (line) => line.productId == product.id,
      );
      if (existingIndex >= 0) {
        final existing = _draftLines[existingIndex];
        _draftLines[existingIndex] = DocumentLine(
          productId: existing.productId,
          label: existing.label,
          sku: existing.sku,
          quantity: existing.quantity + quantity,
          unitHt: existing.unitHt,
          tvaRate: existing.tvaRate,
          discountRate: existing.discountRate,
          serialNumbers: existing.serialNumbers,
        );
      } else {
        _draftLines.add(newLine);
      }
      _quantityController.text = '1';
      _discountController.text = '0';
      _productSearchController.clear();
      _activeProductSearchController?.clear();
      _lastSaleSuccessDocumentId = null;
      _salesFeedbackText =
          '$quantity x ${product.name} ajouté. Total sur cette ligne: $lineQuantityAfterAdd. ${product.stockTracked ? 'Stock estimé après vente: $remaining.' : 'Stock non suivi.'}';
      _salesFeedbackIsError = false;
    });
    _focusProductSearchSoon();
  }

  void _createDocument({bool validateNow = false}) {
    if (_draftLines.isEmpty) {
      _setSalesFeedback(
        'Ajoutez au moins un produit avant de valider la vente.',
        isError: true,
      );
      _showMessage('Ajoutez un produit avant de valider.', isError: true);
      return;
    }

    final needsStockCheck = _salesDocumentNeedsStock(_newDocumentType);
    if (needsStockCheck) {
      final error = _stockErrorFor(_draftLines, _selectedWarehouseId);
      if (error != null) {
        _setSalesFeedback(error, isError: true);
        _showMessage(error, isError: true);
        return;
      }
    }

    final client = _selectedClient;
    final editingIndex = _editingDocumentId == null
        ? -1
        : _documents.indexWhere(
            (document) => document.id == _editingDocumentId,
          );
    if (editingIndex >= 0 &&
        _documents[editingIndex].status != DocumentStatus.draft) {
      _showMessage(
        'Modification bloquée. Seuls les brouillons sont modifiables; les documents validés ou annulés restent verrouillés.',
        isError: true,
      );
      return;
    }
    final documentId =
        _editingDocumentId ?? DateTime.now().microsecondsSinceEpoch.toString();
    final documentNumber = editingIndex >= 0
        ? _documents[editingIndex].number
        : _salesCubit.nextNumber(_newDocumentType);
    _salesCubit.saveSaleDocument(
      id: documentId,
      type: _newDocumentType,
      number: documentNumber,
      date: DateTime.now(),
      client: client,
      lines: List<DocumentLine>.from(_draftLines),
      warehouseId: _selectedWarehouseId,
      company: _company,
      metadata: _newDocumentType == DocumentType.bonSortie
          ? {'targetWarehouseId': _selectedTargetWarehouseId}
          : const {},
      isUpdate: editingIndex >= 0,
    );
    final document = _appRepository.snapshot.documents.firstWhere(
      (document) => document.id == documentId,
    );

    _updateState(() {
      _applyRepositoryState(selectedDocumentId: document.id);
      _draftLines.clear();
      _editingDocumentId = null;
      _salesFeedbackText = null;
      _section = validateNow && editingIndex < 0
          ? Section.sales
          : Section.documents;
    });

    if (validateNow && editingIndex < 0) {
      final validated = _validateDocument(document);
      if (!validated) {
        _updateState(() {
          _lastSaleSuccessDocumentId = null;
          _section = Section.sales;
        });
        _showMessage(
          '${document.number} est enregistré en brouillon. Corrigez le blocage indiqué avant validation.',
          isError: true,
        );
      } else {
        _updateState(() {
          _lastSaleSuccessDocumentId = document.id;
          _section = Section.sales;
        });
        _showMessage('Vente validée. Vous pouvez encaisser ou envoyer le PDF.');
        _syncGuidedProgressAfterMutation();
      }
      return;
    }

    _showMessage(
      editingIndex >= 0
          ? '${document.number} mis à jour. Vous pouvez maintenant le valider depuis Documents.'
          : '${document.number} créé en brouillon. ${_stockEffectHintFor(document.type)}',
    );
  }

  void _editDocumentDraft(BusinessDocument document) {
    if (document.status != DocumentStatus.draft) {
      _showMessage(
        'Modification bloquée. Ce document n’est plus un brouillon; il est verrouillé pour éviter les erreurs de stock et de facturation.',
        isError: true,
      );
      return;
    }
    if (![
      DocumentType.devis,
      DocumentType.bl,
      DocumentType.facture,
    ].contains(document.type)) {
      _showMessage(
        'Ce document se modifie depuis son flux métier.',
        isError: true,
      );
      return;
    }
    _updateState(() {
      _editingDocumentId = document.id;
      _newDocumentType = document.type;
      _selectedClientId = document.partnerId;
      _selectedWarehouseId = document.warehouseId;
      _draftLines
        ..clear()
        ..addAll(document.lines);
      _section = Section.sales;
      _showAdvancedSaleOptions = true;
      _lastSaleSuccessDocumentId = null;
      _salesFeedbackText =
          'Modification de ${document.number}. Les changements restent en brouillon jusqu’à mise à jour.';
      _salesFeedbackIsError = false;
    });
    _focusProductSearchSoon();
  }

  Future<void> _chooseLineSerials(int lineIndex) async {
    final line = _draftLines[lineIndex];
    final product = _productById(line.productId);
    final available = product.serialsIn(_selectedWarehouseId);
    final selected = Set<String>.from(line.serialNumbers);
    if (available.isEmpty) {
      _showMessage(
        'Séries indisponibles pour ${product.name}. Aucune série n’est disponible dans ${_selectedWarehouse.name}; changez de magasin ou faites une entrée stock.',
        isError: true,
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('Séries - ${product.sku}'),
          content: SizedBox(
            width: 420,
            height: 360,
            child: ListView(
              children: [
                InlineNotice(
                  icon: Icons.confirmation_number_outlined,
                  title: 'Sélection série',
                  message:
                      'Choisissez ${line.quantity} numéro(s). La validation reste bloquée tant que la sélection ne correspond pas à la quantité.',
                  color: available.length < line.quantity
                      ? AppColors.warning
                      : AppColors.primary,
                ),
                const SizedBox(height: 10),
                for (final serial in available)
                  CheckboxListTile(
                    value: selected.contains(serial),
                    title: Text(serial),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          if (selected.length < line.quantity) {
                            selected.add(serial);
                          }
                        } else {
                          selected.remove(serial);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selected.length == line.quantity
                  ? () {
                      _updateState(() {
                        _draftLines[lineIndex] = line.copyWith(
                          serialNumbers: selected.toList(),
                        );
                      });
                      Navigator.of(dialogContext).pop();
                    }
                  : null,
              child: Text('Valider ${selected.length}/${line.quantity}'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateDraftLineQuantity(int lineIndex, int quantity) {
    if (quantity <= 0) {
      final removed = _draftLines[lineIndex];
      _updateState(() {
        _draftLines.removeAt(lineIndex);
        _salesFeedbackText = '${removed.label} retiré de la vente.';
        _salesFeedbackIsError = false;
      });
      return;
    }
    final line = _draftLines[lineIndex];
    final updated = line.copyWith(
      quantity: quantity,
      serialNumbers: line.serialNumbers.take(quantity).toList(),
    );
    final candidateLines = List<DocumentLine>.from(_draftLines)
      ..[lineIndex] = updated;
    final needsStockCheck = _salesDocumentNeedsStock(_newDocumentType);
    if (needsStockCheck) {
      final error = _stockErrorFor(candidateLines, _selectedWarehouseId);
      if (error != null) {
        _setSalesFeedback(error, isError: true);
        _showMessage(error, isError: true);
        return;
      }
    }
    final product = _productById(line.productId);
    final remaining =
        product.stockIn(_selectedWarehouseId) -
        _quantityForProductInLines(product.id, candidateLines);
    _updateState(() {
      _draftLines[lineIndex] = updated;
      _salesFeedbackText =
          'Quantité mise à jour: ${line.label} x $quantity. ${product.stockTracked ? 'Stock restant estimé: $remaining.' : 'Stock non suivi.'}';
      _salesFeedbackIsError = false;
    });
  }

  String _validationSuccessMessage(BusinessDocument document) {
    return DocumentLifecycleService.validationSuccessMessage(
      document,
      warehouseName: _warehouseById(document.warehouseId).name,
    );
  }

  String? _cancelBlockReason(BusinessDocument document) {
    return DocumentLifecycleService.cancelBlockReason(_documents, document);
  }

  bool _validateDocument(BusinessDocument document, {bool quiet = false}) {
    final blockReason = DocumentLifecycleService.validationBlockReason(
      document,
    );
    if (blockReason != null) {
      if (!quiet) {
        _showMessage(blockReason, isError: true);
      }
      return false;
    }
    if (document.status == DocumentStatus.validated) return true;

    List<DocumentLine> lines = document.lines;
    var stockApplied = document.stockApplied;
    StockMutationResult? stockMutation;
    if (DocumentLifecycleService.validationRequiresOutboundStock(document)) {
      final serialError = _serialSelectionErrorFor(
        document.lines,
        document.warehouseId,
      );
      if (serialError != null) {
        if (!quiet) _showMessage(serialError, isError: true);
        return false;
      }
      final error = _stockErrorFor(document.lines, document.warehouseId);
      if (error != null) {
        if (!quiet) _showMessage(error, isError: true);
        return false;
      }
      if (!document.stockApplied) {
        stockMutation = _stockCubit.decreaseStockForDocument(
          document: document,
          date: DateTime.now(),
        );
        lines = stockMutation.lines;
        stockApplied = true;
      }
    } else if (DocumentLifecycleService.validationRequiresTransferStock(
      document,
    )) {
      if (!document.stockApplied) {
        try {
          stockMutation = _stockCubit.transferStockForDocument(
            document: document,
            date: DateTime.now(),
          );
          lines = stockMutation.lines;
          stockApplied = true;
        } catch (e) {
          if (!quiet) _showMessage(e.toString(), isError: true);
          return false;
        }
      }
    } else if (DocumentLifecycleService.validationRequiresInboundStock(
      document,
    )) {
      final serialError = _inboundSerialErrorFor(
        document.lines,
        document.warehouseId,
      );
      if (serialError != null) {
        if (!quiet) _showMessage(serialError, isError: true);
        return false;
      }
      if (!document.stockApplied) {
        stockMutation = _stockCubit.increaseStockForDocument(
          document: document,
          date: DateTime.now(),
          serialGenerator: _generatedSerial,
        );
        lines = stockMutation.lines;
        stockApplied = true;
      }
    }

    _documentsCubit.validateDocument(
      document: document,
      lines: lines,
      stockApplied: stockApplied,
      formatMoney: formatMoney,
    );
    _updateState(() {
      _applyRepositoryState(selectedDocumentId: document.id);
    });

    if (!quiet) {
      _showMessage(_validationSuccessMessage(document));
    }
    return true;
  }

  void _convertToBl(BusinessDocument source) {
    if (source.type != DocumentType.devis) return;
    final existing = _activeChildOf(source, DocumentType.bl);
    if (existing != null) {
      _updateState(() {
        _selectedDocumentId = existing.id;
        _section = Section.documents;
      });
      _showMessage(
        DocumentLifecycleService.conversionBlockReason(
          _documents,
          source,
          DocumentType.bl,
        )!,
        isError: true,
      );
      return;
    }

    final documentId = DateTime.now().microsecondsSinceEpoch.toString();
    final number = _documentsCubit.nextNumber(DocumentType.bl);
    _documentsCubit.convertDevisToBl(
      source: source,
      id: documentId,
      number: number,
      date: DateTime.now(),
    );
    final document = _appRepository.snapshot.documents.firstWhere(
      (document) => document.id == documentId,
    );

    _updateState(() {
      _applyRepositoryState(selectedDocumentId: document.id);
    });

    _showMessage(
      '${source.number} converti en ${document.number}. Validez le BL pour sortir le stock.',
    );
  }

  void _convertToInvoice(BusinessDocument source) {
    if (source.type != DocumentType.bl) return;
    final existing = _activeChildOf(source, DocumentType.facture);
    if (existing != null) {
      _updateState(() {
        _selectedDocumentId = existing.id;
        _section = Section.documents;
      });
      _showMessage(
        DocumentLifecycleService.conversionBlockReason(
          _documents,
          source,
          DocumentType.facture,
        )!,
        isError: true,
      );
      return;
    }

    var currentSource = source;
    if (source.status == DocumentStatus.draft) {
      final validated = _validateDocument(source, quiet: true);
      if (!validated) {
        final serialError = _serialSelectionErrorFor(
          source.lines,
          source.warehouseId,
        );
        final stockError = _stockErrorFor(source.lines, source.warehouseId);
        _showMessage(
          serialError ??
              stockError ??
              'Facturation bloquée. Le BL doit être validable avant de créer la facture.',
          isError: true,
        );
        return;
      }
      currentSource = _documents.firstWhere(
        (document) => document.id == source.id,
      );
    }

    final invoiceId = DateTime.now().microsecondsSinceEpoch.toString();
    final invoiceNumber = _documentsCubit.nextNumber(DocumentType.facture);
    _documentsCubit.convertBlToFacture(
      source: currentSource,
      id: invoiceId,
      number: invoiceNumber,
      date: DateTime.now(),
      applyTimbreFiscal: _company.timbreFiscalEnabled,
      timbreFiscalAmount: _company.timbreFiscalAmount,
    );
    final invoice = _appRepository.snapshot.documents.firstWhere(
      (document) => document.id == invoiceId,
    );

    _updateState(() {
      _applyRepositoryState(selectedDocumentId: invoice.id);
    });

    _showMessage('${invoice.number} créée sans mouvement de stock.');
  }

  void _cancelDocument(BusinessDocument document) {
    final blockReason = _cancelBlockReason(document);
    if (blockReason != null) {
      _showMessage(blockReason, isError: true);
      return;
    }

    if (document.stockApplied) {
      final reversal = _reverseStock(document);
      if (reversal == null) return;
    }

    _documentsCubit.cancelDocument(document);
    _updateState(() {
      _applyRepositoryState(selectedDocumentId: document.id);
    });
    _showMessage('${document.number} annulé.');
  }

  StockMutationResult? _reverseStock(BusinessDocument document) {
    final outcome = _stockCubit.reverseDocumentStock(
      document: document,
      date: DateTime.now(),
      warehouseNameById: (warehouseId) => _warehouseById(warehouseId).name,
      serialGenerator: _generatedSerial,
    );
    if (!outcome.isSuccess) {
      _showMessage(outcome.errorMessage!, isError: true);
      return null;
    }
    return outcome.result!;
  }

  void _createPurchaseDocument({required bool receiveNow}) {
    final quantity = int.tryParse(_purchaseQuantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      _showMessage('Quantité achat invalide.', isError: true);
      return;
    }

    final product = _selectedPurchaseProduct;
    final supplier = _selectedSupplier;
    final type = receiveNow
        ? DocumentType.stockEntry
        : DocumentType.supplierOrder;
    final documentId = DateTime.now().microsecondsSinceEpoch.toString();
    final documentsCubit = _documentsCubit;
    final document = documentsCubit.buildSupplierPurchaseDocument(
      id: documentId,
      type: type,
      number: documentsCubit.nextNumber(type),
      date: DateTime.now(),
      supplier: supplier,
      warehouseId: _selectedWarehouseId,
      company: _company,
      line: DocumentLine(
        productId: product.id,
        label: product.name,
        sku: product.sku,
        quantity: quantity,
        unitHt: product.purchaseHt,
        tvaRate: product.tvaRate,
        serialNumbers: product.serialTracked
            ? _parseSerials(_purchaseSerialsController.text)
            : const [],
      ),
      note: receiveNow
          ? "Bon d'entrée fournisseur avec augmentation de stock."
          : 'Commande fournisseur sans mouvement de stock.',
    );

    _documentsCubit.createSupplierDocument(
      document: document,
      receiveNow: receiveNow,
    );
    _updateState(() {
      _applyRepositoryState(selectedDocumentId: document.id);
      _section = Section.documents;
    });
    _purchaseSerialsController.clear();

    if (receiveNow) {
      _validateDocument(document, quiet: true);
      _showMessage('${document.number} reçu: stock augmenté.');
    } else {
      _showMessage('${document.number} créé en brouillon.');
    }
  }

  void _receiveSupplierOrder(BusinessDocument source) {
    if (source.type != DocumentType.supplierOrder) return;
    final existing = _activeChildOf(source, DocumentType.stockEntry);
    if (existing != null) {
      _updateState(() {
        _selectedDocumentId = existing.id;
        _section = Section.documents;
      });
      _showMessage(
        DocumentLifecycleService.conversionBlockReason(
          _documents,
          source,
          DocumentType.stockEntry,
        )!,
        isError: true,
      );
      return;
    }

    final entryId = DateTime.now().microsecondsSinceEpoch.toString();
    final entryNumber = _documentsCubit.nextNumber(DocumentType.stockEntry);
    _documentsCubit.convertSupplierOrderToStockEntry(
      source: source,
      id: entryId,
      number: entryNumber,
      date: DateTime.now(),
    );
    final entry = _appRepository.snapshot.documents.firstWhere(
      (document) => document.id == entryId,
    );

    _updateState(() {
      _applyRepositoryState(selectedDocumentId: entry.id);
    });
    _validateDocument(entry);
  }

  Future<void> _createCreditNoteFromInvoice(BusinessDocument invoice) async {
    if (invoice.type != DocumentType.facture) return;
    final documentsCubit = _documentsCubit;
    final blockReason = ReturnService.creditNoteBlockReason(
      _documents,
      invoice,
    );
    if (blockReason != null) {
      _showMessage(blockReason, isError: true);
      return;
    }

    final returnableLines = ReturnService.returnableLines(_documents, invoice);
    final quantityControllers = {
      for (final line in returnableLines)
        _lineReturnKey(line): TextEditingController(
          text: _returnableQuantityForLine(invoice, line).toString(),
        ),
    };
    final noteController = TextEditingController(
      text: 'Retour client lié à ${invoice.number}.',
    );

    final selectedLines = await showDialog<List<DocumentLine>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Créer avoir depuis ${invoice.number}'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InlineNotice(
                  icon: Icons.info_outline,
                  title: 'Avoir partiel possible',
                  message:
                      'Indiquez uniquement les quantités retournées. Le montant restant de la facture sera réduit après validation de l’avoir.',
                  color: AppColors.primary,
                ),
                const SizedBox(height: 14),
                for (final line in returnableLines) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${line.label} · ${line.sku}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Disponible retour: ${_returnableQuantityForLine(invoice, line)}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(width: 12),
                      _dialogField(
                        width: 110,
                        controller: quantityControllers[_lineReturnKey(line)]!,
                        label: 'Qté',
                        number: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                TextField(
                  controller: noteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note avoir',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final lines = <DocumentLine>[];
              for (final line in returnableLines) {
                final raw = quantityControllers[_lineReturnKey(line)]!.text;
                final quantity = int.tryParse(raw.trim()) ?? 0;
                final max = _returnableQuantityForLine(invoice, line);
                if (quantity < 0 || quantity > max) {
                  _showMessage(
                    ReturnService.selectedLinesError(_documents, invoice, [
                      line.copyWith(quantity: quantity),
                    ])!,
                    isError: true,
                  );
                  return;
                }
                if (quantity > 0) {
                  lines.add(
                    line.copyWith(
                      quantity: quantity,
                      serialNumbers: line.serialNumbers.take(quantity).toList(),
                    ),
                  );
                }
              }
              if (lines.isEmpty) {
                _showMessage(
                  ReturnService.selectedLinesError(_documents, invoice, lines)!,
                  isError: true,
                );
                return;
              }
              Navigator.of(dialogContext).pop(lines);
            },
            icon: const Icon(Icons.undo_outlined),
            label: const Text('Créer avoir'),
          ),
        ],
      ),
    );

    for (final controller in quantityControllers.values) {
      controller.dispose();
    }
    final creditNoteText = noteController.text.trim();
    noteController.dispose();

    if (selectedLines == null || selectedLines.isEmpty) return;

    final creditNoteId = _newId('avoir');
    final creditNoteNumber = documentsCubit.nextNumber(DocumentType.creditNote);
    documentsCubit.createAvoir(
      documents: _documents,
      invoice: invoice,
      selectedLines: selectedLines,
      id: creditNoteId,
      number: creditNoteNumber,
      date: DateTime.now(),
      note: creditNoteText.isEmpty
          ? 'Retour client lié à ${invoice.number}.'
          : creditNoteText,
    );
    final creditNote = _appRepository.snapshot.documents.firstWhere(
      (document) => document.id == creditNoteId,
    );
    _updateState(() {
      _applyRepositoryState(selectedDocumentId: creditNote.id);
    });
    _showMessage(
      '${creditNote.number} créé en brouillon. Validez pour réintégrer le stock et réduire le reste à encaisser.',
    );
  }

  Future<void> _showSortieReturnDialog(BusinessDocument document) async {
    final returnedQuantities = <String, int>{};
    for (final line in document.lines) {
      returnedQuantities[line.productId] = 0;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('Retour produits - ${document.number}'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Saisissez les quantités qui réintègrent le dépôt d’origine.',
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                for (final line in document.lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Sorti: ${line.quantity} · Déjà retourné: ${document.returnedQuantities[line.productId] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: '0',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(isDense: true),
                            onChanged: (val) {
                              final qty = int.tryParse(val) ?? 0;
                              setDialogState(
                                () => returnedQuantities[line.productId] = qty,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final totalToReturn = returnedQuantities.values.fold(
                  0,
                  (sum, q) => sum + q,
                );
                if (totalToReturn <= 0) {
                  _showMessage(
                    'Saisissez au moins une quantité à retourner.',
                    isError: true,
                  );
                  return;
                }

                // Check limits
                for (final line in document.lines) {
                  final qty = returnedQuantities[line.productId] ?? 0;
                  final alreadyReturned =
                      document.returnedQuantities[line.productId] ?? 0;
                  if (qty > (line.quantity - alreadyReturned)) {
                    _showMessage(
                      'Retour invalide pour ${line.label}. Maximum possible: ${line.quantity - alreadyReturned}',
                      isError: true,
                    );
                    return;
                  }
                }

                _updateState(() {
                  _stockCubit.applySortieReturn(
                    products: _products,
                    document: document,
                    returnedQuantities: returnedQuantities,
                    date: DateTime.now(),
                  );
                  _documentsCubit.registerSortieReturn(
                    document: document,
                    returnedQuantities: returnedQuantities,
                    date: DateTime.now(),
                  );
                  _applyRepositoryState();
                });
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Valider le retour'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _closeSortieWorkflow(BusinessDocument document) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clôturer la sortie ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action est irréversible. Le stock restant dans le camion sera considéré comme vendu ou livré.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Récapitulatif:',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            for (final line in document.lines) ...[
              const SizedBox(height: 4),
              Text(
                '· ${line.label}: ${line.quantity - (document.returnedQuantities[line.productId] ?? 0)} vendu(s)',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Garder ouvert'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryContainer,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clôturer définitivement'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _updateState(() {
        _documentsCubit.closeSortie(document: document, date: DateTime.now());
        _applyRepositoryState();
      });
    }
  }
}
