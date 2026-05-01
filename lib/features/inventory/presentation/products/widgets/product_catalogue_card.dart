part of '../../inventory_shell_page.dart';

extension _InventoryProductCatalogueCard on _InventoryHomePageState {
  Widget _buildProductCatalogueCard(Product product, double width) {
    final low =
        product.stockTracked &&
        product.active &&
        product.totalStock <= product.minStock;
    final margin = product.saleHt - product.purchaseHt;
    final stockColor = !product.stockTracked
        ? AppColors.muted
        : low
        ? AppColors.warning
        : AppColors.success;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: low
              ? AppColors.warning.withValues(alpha: .06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: low
                ? AppColors.warning.withValues(alpha: .28)
                : AppColors.border.withValues(alpha: .18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductImage(url: product.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.sku} · ${product.category}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SmallChip(
                  label: product.active ? 'Actif' : 'Inactif',
                  color: product.active ? AppColors.success : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TotalItem(
                    label: 'Prix TTC',
                    value: formatMoney(product.saleTtc),
                    strong: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TotalItem(
                    label: product.stockTracked ? 'Stock' : 'Stock',
                    value: product.stockTracked
                        ? '${product.totalStock}'
                        : 'non suivi',
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
                  label: product.stockTracked
                      ? (low ? 'À réassortir' : 'Stock ok')
                      : 'Stock non suivi',
                  color: stockColor,
                ),
                SmallChip(label: 'TVA ${product.tvaRate.label}', muted: true),
                if (product.serialTracked)
                  const SmallChip(label: 'Séries', color: AppColors.cyan),
              ],
            ),
            const SizedBox(height: 8),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Détails',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  'Achat ${formatMoney(product.purchaseHt)} · marge ${formatMoney(margin)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SmallChip(label: 'HT ${formatMoney(product.saleHt)}'),
                        SmallChip(
                          label: 'Marge ${formatMoney(margin)}',
                          color: margin >= 0
                              ? AppColors.success
                              : AppColors.danger,
                        ),
                        SmallChip(
                          label: 'Min ${product.minStock}',
                          muted: true,
                        ),
                        if (product.barcode?.isNotEmpty ?? false)
                          SmallChip(label: 'Code-barres', muted: true),
                        if (product.brand.isNotEmpty)
                          SmallChip(label: product.brand, muted: true),
                      ],
                    ),
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        product.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showProductDialog(product),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Modifier'),
                        ),
                        TextButton.icon(
                          onPressed: () => _deleteProduct(product),
                          icon: Icon(
                            product.active
                                ? Icons.block_outlined
                                : Icons.delete_outline,
                            size: 16,
                          ),
                          label: Text(
                            product.active ? 'Désactiver' : 'Supprimer',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
