part of '../inventory_shell_page.dart';

extension _InventoryProductFormPage on _InventoryHomePageState {
  Future<void> _showProductDialog([Product? product]) async {
    final isNewProduct = product == null;
    final activeWarehouses = _warehouses
        .where((warehouse) => warehouse.active)
        .toList();
    final name = TextEditingController(text: product?.name ?? '');
    final sku = TextEditingController(text: product?.sku ?? '');
    final barcode = TextEditingController(text: product?.barcode ?? '');
    final brand = TextEditingController(text: product?.brand ?? '');
    final description = TextEditingController(text: product?.description ?? '');
    final purchase = TextEditingController(
      text: product?.purchaseHt.toStringAsFixed(3) ?? '0.000',
    );
    final sale = TextEditingController(
      text: product?.saleHt.toStringAsFixed(3) ?? '',
    );
    final minStock = TextEditingController(text: '${product?.minStock ?? 0}');
    final initialStock = TextEditingController(text: '0');
    final image = TextEditingController(text: product?.imageUrl ?? '');
    var category =
        product?.category ??
        (_categories.isEmpty ? 'Général' : _categories.first.name);
    var tvaRate = product?.tvaRate ?? TvaRate.rate19;
    var stockTracked = product?.stockTracked ?? true;
    var serialTracked = product?.serialTracked ?? false;
    var active = product?.active ?? true;
    var initialWarehouseId =
        activeWarehouses
            .where((warehouse) => warehouse.id == _selectedWarehouseId)
            .firstOrNull
            ?.id ??
        activeWarehouses.firstOrNull?.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(isNewProduct ? 'Ajouter un produit' : 'Modifier produit'),
          content: SizedBox(
            width: isNewProduct ? 680 : 760,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isNewProduct && !_hasFirstProduct) ...[
                    _guidedDialogHint(
                      title: 'Tarek: juste le nécessaire',
                      message:
                          'Nom, code, prix et quantité de départ suffisent. Les détails peuvent attendre.',
                    ),
                    const SizedBox(height: 14),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _dialogField(
                        width: 340,
                        controller: name,
                        label: 'Nom produit',
                      ),
                      _dialogField(
                        width: 180,
                        controller: sku,
                        label: 'Code / SKU',
                      ),
                      _dialogField(
                        width: 170,
                        controller: sale,
                        label: 'Prix vente HT',
                        number: true,
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      SizedBox(
                        width: 140,
                        child: DropdownButtonFormField<TvaRate>(
                          initialValue: tvaRate,
                          decoration: const InputDecoration(labelText: 'TVA'),
                          items: [
                            for (final rate in TvaRate.values)
                              DropdownMenuItem(
                                value: rate,
                                child: Text(rate.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => tvaRate = value);
                            }
                          },
                        ),
                      ),
                      if (isNewProduct) ...[
                        _dialogField(
                          width: 150,
                          controller: initialStock,
                          label: 'Stock initial',
                          number: true,
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: initialWarehouseId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Dépôt',
                            ),
                            items: [
                              for (final warehouse in activeWarehouses)
                                DropdownMenuItem(
                                  value: warehouse.id,
                                  child: Text(warehouse.name),
                                ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  initialWarehouseId = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                      _priceTtcPreview(
                        saleHt: _parseAmount(sale.text),
                        tvaRate: tvaRate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: !isNewProduct,
                      tilePadding: EdgeInsets.zero,
                      childrenPadding: const EdgeInsets.only(top: 8),
                      leading: const Icon(Icons.tune_outlined),
                      title: const Text(
                        'Options avancées',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        isNewProduct
                            ? 'Catégorie, achat, image, stock minimum et séries.'
                            : 'Détails complets du produit.',
                      ),
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 220,
                              child: DropdownButtonFormField<String>(
                                initialValue: category,
                                decoration: const InputDecoration(
                                  labelText: 'Catégorie',
                                ),
                                items: [
                                  for (final item in _categories.where(
                                    (item) =>
                                        item.active || item.name == category,
                                  ))
                                    DropdownMenuItem(
                                      value: item.name,
                                      child: Text(item.name),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() => category = value);
                                  }
                                },
                              ),
                            ),
                            _dialogField(
                              width: 180,
                              controller: barcode,
                              label: 'Code-barres',
                            ),
                            _dialogField(
                              width: 180,
                              controller: brand,
                              label: 'Marque',
                            ),
                            _dialogField(
                              width: 160,
                              controller: purchase,
                              label: 'Achat HT',
                              number: true,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                            _dialogField(
                              width: 140,
                              controller: minStock,
                              label: 'Stock min',
                              number: true,
                            ),
                            SizedBox(
                              width: 260,
                              child: PriceInsight(
                                saleHt: _parseAmount(sale.text),
                                purchaseHt: _parseAmount(purchase.text),
                                tvaRate: tvaRate,
                              ),
                            ),
                            _dialogField(
                              width: 520,
                              controller: image,
                              label: 'Image URL',
                            ),
                            SizedBox(
                              width: 650,
                              child: TextField(
                                controller: description,
                                minLines: 2,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  alignLabelWithHint: true,
                                ),
                              ),
                            ),
                            _switchTile(
                              label: 'Stock suivi',
                              value: stockTracked,
                              onChanged: (value) =>
                                  setDialogState(() => stockTracked = value),
                            ),
                            _switchTile(
                              label: 'N° série',
                              value: serialTracked,
                              onChanged: (value) =>
                                  setDialogState(() => serialTracked = value),
                            ),
                            _switchTile(
                              label: 'Actif',
                              value: active,
                              onChanged: (value) =>
                                  setDialogState(() => active = value),
                            ),
                          ],
                        ),
                      ],
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
            ElevatedButton(
              onPressed: () {
                final parsedPurchase = _parseAmount(
                  purchase.text,
                  fallback: -1,
                );
                final parsedSale = _parseAmount(sale.text, fallback: -1);
                final parsedMin = int.tryParse(minStock.text.trim()) ?? -1;
                final parsedInitialStock = isNewProduct
                    ? int.tryParse(initialStock.text.trim()) ?? -1
                    : 0;
                final cleanSku = sku.text.trim();
                if (name.text.trim().isEmpty ||
                    cleanSku.isEmpty ||
                    parsedPurchase < 0 ||
                    parsedSale < 0 ||
                    parsedMin < 0 ||
                    parsedInitialStock < 0) {
                  _showMessage(
                    'Produit invalide: vérifiez les champs.',
                    isError: true,
                  );
                  return;
                }
                if (parsedInitialStock > 0 && !stockTracked) {
                  _showMessage(
                    'Le stock initial nécessite un produit suivi en stock.',
                    isError: true,
                  );
                  return;
                }
                if (parsedInitialStock > 0 && initialWarehouseId == null) {
                  _showMessage('Choisissez le dépôt de départ.', isError: true);
                  return;
                }
                final duplicateSku = _products.any(
                  (item) =>
                      item.id != product?.id &&
                      item.sku.toLowerCase() == cleanSku.toLowerCase(),
                );
                if (duplicateSku) {
                  _showMessage('SKU déjà utilisé.', isError: true);
                  return;
                }
                final imageUrl = _safeRemoteImageUrl(image.text);
                if (image.text.trim().isNotEmpty && imageUrl.isEmpty) {
                  _showMessage(
                    'Image refusée: utilisez une URL HTTPS valide.',
                    isError: true,
                  );
                  return;
                }

                final productId = product?.id ?? _newId('prod');
                final baseStock =
                    product?.stockByWarehouse ??
                    {for (final warehouse in _warehouses) warehouse.id: 0};
                final updated = Product(
                  id: productId,
                  name: name.text.trim(),
                  sku: cleanSku,
                  category: category,
                  purchaseHt: parsedPurchase,
                  saleHt: parsedSale,
                  tvaRate: tvaRate,
                  minStock: parsedMin,
                  serialTracked: serialTracked,
                  stockTracked: stockTracked,
                  active: active,
                  stockByWarehouse: baseStock,
                  serialsByWarehouse: product?.serialsByWarehouse ?? const {},
                  imageUrl: imageUrl,
                  barcode: barcode.text.trim().isEmpty
                      ? null
                      : barcode.text.trim(),
                  brand: brand.text.trim(),
                  description: description.text.trim(),
                );
                try {
                  final productsCubit = _productsCubit;
                  if (isNewProduct) {
                    productsCubit.createProduct(
                      updated,
                      initialWarehouseId: initialWarehouseId,
                      initialStockQuantity: parsedInitialStock,
                      movementNumber: parsedInitialStock > 0
                          ? _nextMovementNumber('INI')
                          : null,
                      date: DateTime.now(),
                      serialGenerator: _generatedSerial,
                    );
                  } else {
                    productsCubit.updateProduct(updated);
                  }
                  _updateState(() {
                    _applyRepositoryState();
                    _ensureSelections();
                  });
                } on StateError catch (error) {
                  _showMessage(error.message, isError: true);
                  return;
                }
                Navigator.of(dialogContext).pop();
                _syncGuidedProgressAfterMutation();
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProduct(Product product) {
    _updateState(() {
      _productsCubit.deleteOrArchiveProduct(product);
      _applyRepositoryState();
    });
  }
}
