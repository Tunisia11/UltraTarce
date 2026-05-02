part of '../inventory_shell_page.dart';

extension _InventoryStockPage on _InventoryHomePageState {
  Future<void> _showStockAdjustmentDialog() async {
    var productId = _selectedProductId;
    var warehouseId = _selectedWarehouseId;
    var direction = StockDirection.inbound;
    final quantity = TextEditingController(text: '1');
    final note = TextEditingController();
    final serials = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Ajustement stock'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String>(
                      initialValue: productId,
                      decoration: const InputDecoration(labelText: 'Produit'),
                      items: [
                        for (final product in _products.where(
                          (product) => product.active && product.stockTracked,
                        ))
                          DropdownMenuItem(
                            value: product.id,
                            child: Text(product.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => productId = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: warehouseId,
                      decoration: const InputDecoration(labelText: 'Dépôt'),
                      items: [
                        for (final warehouse in _warehouses.where(
                          (warehouse) => warehouse.active,
                        ))
                          DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => warehouseId = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<StockDirection>(
                      initialValue: direction,
                      decoration: const InputDecoration(labelText: 'Sens'),
                      items: const [
                        DropdownMenuItem(
                          value: StockDirection.inbound,
                          child: Text('Entrée'),
                        ),
                        DropdownMenuItem(
                          value: StockDirection.outbound,
                          child: Text('Sortie'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => direction = value);
                        }
                      },
                    ),
                  ),
                  _dialogField(
                    width: 120,
                    controller: quantity,
                    label: 'Qté',
                    number: true,
                  ),
                  if (_productById(productId).serialTracked)
                    SizedBox(
                      width: 560,
                      child: TextField(
                        controller: serials,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'N° série (un par ligne)',
                          alignLabelWithHint: true,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: 560,
                    child: TextField(
                      controller: note,
                      decoration: const InputDecoration(labelText: 'Motif'),
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
                final qty = int.tryParse(quantity.text.trim()) ?? 0;
                if (qty <= 0) {
                  _showMessage('Quantité invalide.', isError: true);
                  return;
                }
                final ok = _applyStockAdjustment(
                  productId: productId,
                  warehouseId: warehouseId,
                  direction: direction,
                  quantity: qty,
                  note: note.text.trim(),
                  serialNumbers: _parseSerials(serials.text),
                );
                if (ok) Navigator.of(dialogContext).pop();
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }

  bool _applyStockAdjustment({
    required String productId,
    required String warehouseId,
    required StockDirection direction,
    required int quantity,
    required String note,
    required List<String> serialNumbers,
  }) {
    final product = _productById(productId);
    try {
      _stockCubit.adjustStock(
        productId: productId,
        warehouseId: warehouseId,
        direction: direction,
        quantity: quantity,
        serialNumbers: serialNumbers,
        movementNumber: _nextMovementNumber('AJU'),
        date: DateTime.now(),
        serialGenerator: _generatedSerial,
        auditTarget: product.sku,
        auditDetail: note.isEmpty ? '${direction.name} $quantity' : note,
      );
    } on StateError catch (error) {
      _showMessage(error.message, isError: true);
      return false;
    }

    _updateState(() {
      _applyRepositoryState();
    });
    _showMessage('Stock ajusté.');
    return true;
  }

  Future<void> _showStockTransferDialog() async {
    var productId = _selectedProductId;
    var fromWarehouseId = _selectedWarehouseId;
    var toWarehouseId = _warehouses
        .where((warehouse) => warehouse.id != fromWarehouseId)
        .firstOrNull
        ?.id;
    final quantity = TextEditingController(text: '1');
    final serials = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Transfert dépôt'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 300,
                    child: DropdownButtonFormField<String>(
                      initialValue: productId,
                      decoration: const InputDecoration(labelText: 'Produit'),
                      items: [
                        for (final product in _products.where(
                          (product) => product.active && product.stockTracked,
                        ))
                          DropdownMenuItem(
                            value: product.id,
                            child: Text(product.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => productId = value);
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: fromWarehouseId,
                      decoration: const InputDecoration(labelText: 'Depuis'),
                      items: [
                        for (final warehouse in _warehouses.where(
                          (warehouse) => warehouse.active,
                        ))
                          DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          fromWarehouseId = value;
                          if (toWarehouseId == value) {
                            toWarehouseId = _warehouses
                                .where((warehouse) => warehouse.id != value)
                                .firstOrNull
                                ?.id;
                          }
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: toWarehouseId,
                      decoration: const InputDecoration(labelText: 'Vers'),
                      items: [
                        for (final warehouse in _warehouses.where(
                          (warehouse) =>
                              warehouse.active &&
                              warehouse.id != fromWarehouseId,
                        ))
                          DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => toWarehouseId = value);
                        }
                      },
                    ),
                  ),
                  _dialogField(
                    width: 120,
                    controller: quantity,
                    label: 'Qté',
                    number: true,
                  ),
                  if (_productById(productId).serialTracked)
                    SizedBox(
                      width: 560,
                      child: TextField(
                        controller: serials,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'N° série à transférer (un par ligne)',
                          alignLabelWithHint: true,
                        ),
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
                final qty = int.tryParse(quantity.text.trim()) ?? 0;
                if (qty <= 0 || toWarehouseId == null) {
                  _showMessage('Transfert invalide.', isError: true);
                  return;
                }
                final ok = _applyStockTransfer(
                  productId: productId,
                  fromWarehouseId: fromWarehouseId,
                  toWarehouseId: toWarehouseId!,
                  quantity: qty,
                  serialNumbers: _parseSerials(serials.text),
                );
                if (ok) Navigator.of(dialogContext).pop();
              },
              child: const Text('Transférer'),
            ),
          ],
        ),
      ),
    );
  }

  bool _applyStockTransfer({
    required String productId,
    required String fromWarehouseId,
    required String toWarehouseId,
    required int quantity,
    required List<String> serialNumbers,
  }) {
    try {
      _stockCubit.transferStock(
        productId: productId,
        fromWarehouseId: fromWarehouseId,
        toWarehouseId: toWarehouseId,
        quantity: quantity,
        serialNumbers: serialNumbers,
        movementNumber: _nextMovementNumber('TRF'),
        date: DateTime.now(),
        detail:
            '${_warehouseById(fromWarehouseId).name} → ${_warehouseById(toWarehouseId).name}: $quantity',
      );
    } on StateError catch (error) {
      _showMessage(error.message, isError: true);
      return false;
    }

    _updateState(() {
      _applyRepositoryState();
    });
    _showMessage('Transfert stock terminé.');
    return true;
  }

  List<String> _parseSerials(String raw) => raw
      .split(RegExp(r'[\n,;]+'))
      .map((serial) => serial.trim())
      .where((serial) => serial.isNotEmpty)
      .toList();

  Widget _buildStock() {
    final lowByWarehouse = {
      for (final warehouse in _warehouses)
        warehouse.id: _products
            .where(
              (product) =>
                  product.active &&
                  product.stockTracked &&
                  product.stockIn(warehouse.id) <= product.minStock,
            )
            .toList(),
    };
    final lowProducts = lowByWarehouse.values.expand((items) => items).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Stock',
          subtitle:
              'Voir les alertes, corriger une quantité ou transférer entre dépôts.',
          actions: [
            ElevatedButton.icon(
              onPressed: _showStockAdjustmentDialog,
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Corriger stock'),
            ),
            OutlinedButton.icon(
              onPressed: () => _openBonSortieForm(),
              icon: const Icon(Icons.local_shipping_outlined),
              label: const Text('Sortie camion'),
            ),
            OutlinedButton.icon(
              onPressed: _showStockTransferDialog,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Transfert'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showWarehouseDialog(),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Nouveau dépôt'),
            ),
            OutlinedButton.icon(
              onPressed: _exportStockCsv,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Exporter CSV'),
            ),
          ],
        ),
        Panel(
          title: 'À surveiller',
          child: lowProducts.isEmpty
              ? const EmptyState(
                  text: 'Aucun stock faible pour le moment.',
                  icon: Icons.check_circle_outline,
                )
              : Column(
                  children: [
                    for (final warehouse in _warehouses)
                      for (final product in lowByWarehouse[warehouse.id]!)
                        ListRow(
                          leading: Icons.warning_amber_outlined,
                          title: product.name,
                          subtitle:
                              '${warehouse.name} · disponible ${product.stockIn(warehouse.id)} · minimum ${product.minStock}',
                          trailing: OutlinedButton(
                            onPressed: () {
                              _updateState(() {
                                _selectedProductId = product.id;
                                _selectedWarehouseId = warehouse.id;
                              });
                              _showStockAdjustmentDialog();
                            },
                            child: const Text('Corriger'),
                          ),
                        ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'Dépôts',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth >= 980
                  ? 3
                  : maxWidth >= 640
                  ? 2
                  : 1;
              final cardWidth = (maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final warehouse in _warehouses)
                    _buildWarehouseStockCard(
                      warehouse: warehouse,
                      lowProducts: lowByWarehouse[warehouse.id]!,
                      width: cardWidth,
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Panel(
          title: 'Historique stock',
          trailing: SmallChip(label: '${_movements.length} mouvement(s)'),
          child: _movements.isEmpty
              ? const EmptyState(
                  text: 'Aucun mouvement enregistré.',
                  icon: Icons.history,
                )
              : Column(
                  children: [
                    for (final movement in _movements.take(40))
                      _buildStockMovementCard(movement),
                    if (_movements.length > 40) ...[
                      const SizedBox(height: 8),
                      const EmptyState(
                        text:
                            'Historique long: exportez le CSV pour tout analyser.',
                        icon: Icons.table_view_outlined,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWarehouseStockCard({
    required Warehouse warehouse,
    required List<Product> lowProducts,
    required double width,
  }) {
    final totalStock = _products.fold(
      0,
      (total, product) => total + product.stockIn(warehouse.id),
    );
    final accent = !warehouse.active
        ? AppColors.muted
        : lowProducts.isNotEmpty
        ? AppColors.warning
        : AppColors.success;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: .20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    warehouse.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                SmallChip(
                  label: warehouse.active ? 'Actif' : 'Inactif',
                  color: warehouse.active ? AppColors.success : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (warehouse.code.isNotEmpty) warehouse.code,
                if (warehouse.city.isNotEmpty) warehouse.city,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TotalItem(
                    label: 'Quantité totale',
                    value: '$totalStock',
                    strong: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TotalItem(
                    label: 'Alertes',
                    value: '${lowProducts.length}',
                    strong: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SmallChip(
                  label: lowProducts.isEmpty ? 'Stock ok' : 'À traiter',
                  color: accent,
                ),
                if (warehouse.address.isNotEmpty)
                  const SmallChip(label: 'Adresse enregistrée', muted: true),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showWarehouseDialog(warehouse),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Modifier'),
                ),
                TextButton.icon(
                  onPressed: () => _deleteWarehouse(warehouse),
                  icon: Icon(
                    warehouse.active
                        ? Icons.block_outlined
                        : Icons.delete_outline,
                    size: 16,
                  ),
                  label: Text(warehouse.active ? 'Désactiver' : 'Supprimer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockMovementCard(StockMovement movement) {
    final inbound = movement.direction == StockDirection.inbound;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: .16)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (inbound ? AppColors.success : AppColors.danger)
                  .withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              inbound ? Icons.south_west : Icons.north_east,
              color: inbound ? AppColors.success : AppColors.danger,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(movement.date)} · ${movement.documentNumber} · ${_warehouseById(movement.warehouseId).name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (movement.serialNumbers.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Séries: ${movement.serialNumbers.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          SmallChip(
            label: '${inbound ? '+' : '-'}${movement.quantity}',
            color: inbound ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }
}
