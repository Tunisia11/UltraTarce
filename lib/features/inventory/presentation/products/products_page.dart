part of '../inventory_shell_page.dart';

extension _InventoryProductsPage on _InventoryHomePageState {
  Widget _buildProducts() {
    final filteredProducts = _products.where((product) {
      final query = _productQuery.toLowerCase().trim();
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          (product.barcode?.contains(query) ?? false);
      final matchesCategory =
          _productCategoryFilter == 'Tous' ||
          product.category == _productCategoryFilter;
      return matchesQuery && matchesCategory;
    }).toList();
    final activeCount = filteredProducts
        .where((product) => product.active)
        .length;
    final lowCount = filteredProducts
        .where(
          (product) =>
              product.active &&
              product.stockTracked &&
              product.totalStock <= product.minStock,
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Produits',
          subtitle: 'Catalogue simple: prix, stock et articles à surveiller.',
          actions: [
            ElevatedButton.icon(
              key: _productCreateActionKey,
              onPressed: () => _openProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau produit'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.category_outlined),
              label: const Text('Nouvelle catégorie'),
            ),
            OutlinedButton.icon(
              onPressed: _exportProductsCsv,
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Exporter CSV'),
            ),
          ],
        ),
        Panel(
          title: 'Catalogue',
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SmallChip(label: '$activeCount actif(s)'),
              SmallChip(
                label: '$lowCount stock faible',
                color: lowCount == 0 ? AppColors.success : AppColors.warning,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _productFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Chercher un produit',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) =>
                          _updateState(() => _productQuery = value),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<String>(
                      initialValue: _productCategoryFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      items: [
                        const DropdownMenuItem(
                          value: 'Tous',
                          child: Text('Toutes'),
                        ),
                        for (final category in _categories)
                          DropdownMenuItem(
                            value: category.name,
                            child: Text(
                              category.active
                                  ? category.name
                                  : '${category.name} (inactive)',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _updateState(() => _productCategoryFilter = value);
                        }
                      },
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _updateState(() {
                      _productQuery = '';
                      _productFilterController.clear();
                      _productCategoryFilter = 'Tous';
                    }),
                    icon: const Icon(Icons.clear),
                    label: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(top: 8),
                  leading: const Icon(Icons.category_outlined),
                  title: const Text(
                    'Gérer les catégories',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  subtitle: const Text(
                    'Optionnel, utile quand le catalogue grandit.',
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final category in _categories)
                            InputChip(
                              label: Text(
                                category.active
                                    ? category.name
                                    : '${category.name} inactive',
                              ),
                              onPressed: () => _showCategoryDialog(category),
                              onDeleted: () => _deleteCategory(category),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filteredProducts.isEmpty)
                EmptyState(
                  text: _products.isEmpty
                      ? 'Aucun produit. Ajoutez votre premier article pour commencer à vendre.'
                      : 'Aucun produit ne correspond à cette recherche.',
                  icon: Icons.inventory_2_outlined,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final columns = maxWidth >= 1180
                        ? 3
                        : maxWidth >= 760
                        ? 2
                        : 1;
                    final cardWidth = (maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final product in filteredProducts)
                          _buildProductCatalogueCard(product, cardWidth),
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
