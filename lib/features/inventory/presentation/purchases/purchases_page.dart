part of '../inventory_shell_page.dart';

extension _InventoryPurchasesPage on _InventoryHomePageState {
  Widget _buildPurchases({required bool isDesktop}) {
    final missingSupplier = _suppliers
        .where((supplier) => supplier.active)
        .isEmpty;
    final missingProduct = _products.where((product) => product.active).isEmpty;
    if (missingSupplier || missingProduct) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(
            title: 'Achats fournisseur',
            subtitle:
                "Créez d’abord un fournisseur et un produit pour préparer une entrée stock.",
          ),
          Panel(
            title: 'Réception rapide',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                StepPill(
                  number: '1',
                  title: 'Créer fournisseur',
                  subtitle: 'Coordonnées et MF',
                  done: !missingSupplier,
                  onTap: () => _showPartnerDialog(type: PartnerType.supplier),
                ),
                StepPill(
                  number: '2',
                  title: 'Créer produit',
                  subtitle: 'Prix achat, TVA, stock',
                  done: !missingProduct,
                  onTap: () => _showProductDialog(),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final preview = BusinessDocument(
      id: 'purchase-preview',
      type: DocumentType.stockEntry,
      number: 'BE-${DateTime.now().year}-000X',
      status: DocumentStatus.draft,
      partnerId: _selectedSupplier.id,
      partnerName: _selectedSupplier.name,
      partnerTaxId: _selectedSupplier.taxId,
      partnerAddress: _selectedSupplier.address,
      date: DateTime.now(),
      warehouseId: _selectedWarehouseId,
      companySnapshot: _company,
      lines: [
        DocumentLine(
          productId: _selectedPurchaseProduct.id,
          label: _selectedPurchaseProduct.name,
          sku: _selectedPurchaseProduct.sku,
          quantity: int.tryParse(_purchaseQuantityController.text) ?? 1,
          unitHt: _selectedPurchaseProduct.purchaseHt,
          tvaRate: _selectedPurchaseProduct.tvaRate,
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Achats fournisseur',
          subtitle:
              "Commande fournisseur ou bon d'entrée avec augmentation de stock.",
        ),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildPurchaseComposer()),
              const SizedBox(width: 18),
              Expanded(flex: 5, child: _buildDocumentPreview(preview)),
            ],
          )
        else ...[
          _buildPurchaseComposer(),
          const SizedBox(height: 18),
          _buildDocumentPreview(preview),
        ],
      ],
    );
  }

  Widget _buildPurchaseComposer() {
    return Panel(
      title: 'Réception rapide',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _fieldBox(
                width: 320,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_selectedSupplierId),
                  initialValue: _selectedSupplierId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Fournisseur'),
                  items: [
                    for (final supplier in _suppliers.where(
                      (supplier) =>
                          supplier.active || supplier.id == _selectedSupplierId,
                    ))
                      DropdownMenuItem(
                        value: supplier.id,
                        child: Text(
                          supplier.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _updateState(() => _selectedSupplierId = value);
                  },
                ),
              ),
              _fieldBox(
                width: 320,
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_selectedPurchaseProductId),
                  initialValue: _selectedPurchaseProductId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Produit'),
                  items: [
                    for (final product in _products.where(
                      (product) => product.active,
                    ))
                      DropdownMenuItem(
                        value: product.id,
                        child: Text(
                          product.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _updateState(() => _selectedPurchaseProductId = value);
                  },
                ),
              ),
              _fieldBox(
                width: 120,
                child: TextField(
                  controller: _purchaseQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qté'),
                  onChanged: (_) => _updateState(() {}),
                ),
              ),
              _fieldBox(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('purchase-$_selectedWarehouseId'),
                  initialValue: _selectedWarehouseId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Dépôt'),
                  items: [
                    for (final warehouse in _warehouses.where(
                      (warehouse) =>
                          warehouse.active ||
                          warehouse.id == _selectedWarehouseId,
                    ))
                      DropdownMenuItem(
                        value: warehouse.id,
                        child: Text(warehouse.name),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    _updateState(() => _selectedWarehouseId = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_selectedPurchaseProduct.serialTracked) ...[
            TextField(
              controller: _purchaseSerialsController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'N° série reçus (un par ligne, optionnel)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () => _createPurchaseDocument(receiveNow: true),
                icon: const Icon(Icons.call_received),
                label: const Text("Valider l'entrée"),
              ),
              OutlinedButton.icon(
                onPressed: () => _createPurchaseDocument(receiveNow: false),
                icon: const Icon(Icons.request_quote_outlined),
                label: const Text('Créer commande'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            "Règle stock: le bon d'entrée augmente le stock. La commande fournisseur ne touche pas au stock.",
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
