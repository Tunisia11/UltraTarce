part of '../inventory_shell_page.dart';

extension _InventoryDashboardPage on _InventoryHomePageState {
  Widget _buildDashboard({required bool isDesktop}) {
    if (_shouldShowFirstSuccessGuide) {
      return _buildFirstUseDashboard(isDesktop: isDesktop);
    }
    if (!_hasMeaningfulDashboardData) {
      return _buildQuietDashboard();
    }

    final bestSellers = _bestSellers();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Pilotage quotidien',
          subtitle:
              'Vendez, suivez le stock et préparez vos sorties camion en quelques clics.',
          actions: [
            ElevatedButton.icon(
              onPressed: () => _goToSales(),
              icon: const Icon(Icons.flash_on_outlined),
              label: const Text('Faire une vente'),
            ),
            OutlinedButton.icon(
              onPressed: () => _updateState(() => _section = Section.documents),
              icon: const Icon(Icons.description_outlined),
              label: const Text('Voir suivi avancé'),
            ),
          ],
        ),
        _buildActionPanel(),
        const SizedBox(height: 18),
        _buildDashboardMetrics(),
        const SizedBox(height: 22),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLowStockPanel()),
              const SizedBox(width: 18),
              Expanded(child: _buildBestSellersPanel(bestSellers)),
            ],
          )
        else ...[
          _buildLowStockPanel(),
          const SizedBox(height: 18),
          _buildBestSellersPanel(bestSellers),
        ],
        const SizedBox(height: 22),
        _buildRecentActivityPanel(),
        const SizedBox(height: 22),
        _buildBusinessHealthStrip(),
      ],
    );
  }

  Widget _buildQuietDashboard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Pilotage quotidien',
          subtitle:
              'Vendez, suivez le stock et préparez vos sorties camion en quelques clics.',
        ),
        _buildActionPanel(),
        const SizedBox(height: 18),
        _buildDashboardMetrics(),
        const SizedBox(height: 18),
        EmptyState(
          title: 'Commencez simplement',
          text: 'Commencez par ajouter un produit ou faire une première vente.',
          icon: Icons.insights_outlined,
          actionLabel: 'Ajouter produit',
          onAction: () => _openProductForm(),
        ),
        const SizedBox(height: 22),
        _buildBusinessHealthStrip(),
      ],
    );
  }

  Widget _buildFirstUseDashboard({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Pilotage quotidien',
          subtitle:
              'Vendez, suivez le stock et préparez vos sorties camion en quelques clics.',
          actions: [
            ElevatedButton.icon(
              key: _dashboardPrimaryActionKey,
              onPressed: _startFirstSuccessGuide,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Démarrer avec Tarek'),
            ),
          ],
        ),
        _buildActionPanel(),
        const SizedBox(height: 18),
        _buildDashboardMetrics(),
        const SizedBox(height: 18),
        _buildGettingStartedPanel(),
        const SizedBox(height: 18),
        Panel(
          title: 'Prochaine meilleure action',
          child: Text(
            _firstUseNextActionText(),
            style: const TextStyle(
              color: AppColors.muted,
              height: 1.45,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  String _firstUseNextActionText() {
    if (!_hasFirstProduct) {
      return 'Commençons par ajouter votre premier produit: nom, code, prix et stock.';
    }
    if (!_hasFirstClient) {
      return 'Ajoutez un client, ou utilisez Client comptoir pour vendre rapidement.';
    }
    if (!_hasFirstSale) {
      return 'Parfait. Maintenant, vous pouvez faire votre première vente.';
    }
    return 'Vos données sont enregistrées localement. Cliquez sur Synchroniser pour les sauvegarder dans le cloud.';
  }

  Widget _buildLowStockPanel() {
    return Panel(
      title: 'Alertes stock',
      child: Column(
        children: [
          if (_lowStockProducts.isEmpty)
            const EmptyState(
              text: 'Le stock apparaîtra après l’ajout de produits.',
              icon: Icons.check_circle_outline,
            )
          else
            for (final product in _lowStockProducts)
              ListRow(
                leading: Icons.inventory_2_outlined,
                title: product.name,
                subtitle:
                    '${product.sku} · minimum ${product.minStock} · disponible ${product.totalStock}',
                trailing: SmallChip(
                  label: product.totalStock <= 1 ? 'Urgent' : 'À suivre',
                  color: product.totalStock <= 1
                      ? AppColors.danger
                      : AppColors.warning,
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildDashboardMetrics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 14.0;
        final width = _responsiveTileWidth(
          maxWidth: constraints.maxWidth,
          minTileWidth: 220,
          spacing: spacing,
          maxColumns: 5,
        );
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            MetricCard(
              width: width,
              label: "CA aujourd'hui",
              value: formatMoney(_dailySales),
              detail: 'Ventes validées',
              accent: AppColors.primary,
              icon: Icons.today_outlined,
            ),
            MetricCard(
              width: width,
              label: 'Ventes',
              value: '${_todaySalesCount()}',
              detail: "Aujourd'hui",
              accent: AppColors.cyan,
              icon: Icons.point_of_sale_outlined,
            ),
            MetricCard(
              width: width,
              label: 'Stock faible',
              value: '${_lowStockProducts.length}',
              detail: 'Articles à commander',
              accent: AppColors.warning,
              icon: Icons.warning_amber_outlined,
            ),
            MetricCard(
              width: width,
              label: 'Sorties en cours',
              value: '${_openSortieCount()}',
              detail: 'Camions à suivre',
              accent: AppColors.primaryContainer,
              icon: Icons.local_shipping_outlined,
            ),
            MetricCard(
              width: width,
              label: 'Documents à suivre',
              value: '${_documentsToFollowCount()}',
              detail: 'Brouillons ou paiements',
              accent: AppColors.warning,
              icon: Icons.description_outlined,
            ),
          ],
        );
      },
    );
  }

  double _responsiveTileWidth({
    required double maxWidth,
    required double minTileWidth,
    required double spacing,
    required int maxColumns,
  }) {
    final possibleColumns = ((maxWidth + spacing) / (minTileWidth + spacing))
        .floor()
        .clamp(1, maxColumns);
    return (maxWidth - spacing * (possibleColumns - 1)) / possibleColumns;
  }

  Widget _buildGettingStartedPanel() {
    return Panel(
      title: 'Première réussite guidée',
      icon: Icons.auto_awesome_outlined,
      subtitle:
          'Bienvenue dans Trace Ultra. Tarek vous aide à préparer votre espace en quelques minutes.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final intro = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  AppAssets.welcomeMascot,
                  width: compact ? 62 : 82,
                  height: compact ? 62 : 82,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tarek vous guide, étape par étape.',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'On complète les bases, on ajoute un produit, puis on prépare la première vente et la sortie camion si nécessaire.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              intro,
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StepPill(
                    key: _companyProfileStepKey,
                    number: '1',
                    title: 'Profil société',
                    subtitle: 'Nom, MF, adresse',
                    done: _companyIdentityReady,
                    onTap: () =>
                        _updateState(() => _section = Section.settings),
                  ),
                  StepPill(
                    key: _firstDepotStepKey,
                    number: '2',
                    title: 'Premier dépôt',
                    subtitle: 'Magasin ou réserve',
                    done: _hasFirstDepot,
                    onTap: () => _showWarehouseDialog(),
                  ),
                  StepPill(
                    key: _firstProductStepKey,
                    number: '3',
                    title: 'Premier produit',
                    subtitle: 'Nom, prix, stock',
                    done: _hasFirstProduct,
                    onTap: () => _openProductForm(),
                  ),
                  StepPill(
                    key: _firstClientStepKey,
                    number: '4',
                    title: 'Premier client',
                    subtitle: 'Nom, téléphone',
                    done: _hasFirstClient,
                    onTap: () => _showPartnerDialog(type: PartnerType.client),
                  ),
                  StepPill(
                    key: _firstSaleStepKey,
                    number: '5',
                    title: 'Première vente',
                    subtitle: 'Produit, total, valider',
                    done: _hasFirstSale,
                    onTap: () => _goToSales(),
                  ),
                  StepPill(
                    key: _sortieCamionStepKey,
                    number: '6',
                    title: 'Sortie camion',
                    subtitle: 'Camion et chargement',
                    done: _hasBonSortie,
                    onTap: () => _hasMobileWarehouse
                        ? _openBonSortieForm()
                        : _showWarehouseDialog(null, 'mobile'),
                  ),
                  StepPill(
                    key: _syncStepKey,
                    number: '7',
                    title: 'Synchroniser',
                    subtitle: 'Sauvegarde cloud',
                    done: false,
                    onTap: _triggerManualPushSync,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: _startFirstSuccessGuide,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Continuer avec Tarek'),
                  ),
                  TextButton(
                    onPressed: _dismissGuidedSetup,
                    child: const Text('Masquer le guide'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _dismissGuidedSetup() {
    _updateState(() {
      _guidedSetupDismissed = true;
      _guidedFocusActive = false;
    });
    _onboardingCubit.skipGuidance();
    _showMessage(
      'Guide masqué. Vous pouvez continuer depuis les actions rapides.',
    );
  }

  Widget _buildActionPanel() {
    return Panel(
      title: 'Actions rapides',
      subtitle: 'Les raccourcis du quotidien pour vendre, stocker et livrer.',
      icon: Icons.bolt_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 12.0;
          final width = _responsiveTileWidth(
            maxWidth: constraints.maxWidth,
            minTileWidth: 210,
            spacing: spacing,
            maxColumns: 5,
          );
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              QuickActionButton(
                width: width,
                label: 'Faire une vente',
                detail: 'Client, produits, validation',
                icon: Icons.flash_on_outlined,
                color: AppColors.primary,
                onTap: () => _goToSales(),
              ),
              QuickActionButton(
                width: width,
                label: 'Ajouter produit',
                detail: 'Prix, TVA, stock',
                icon: Icons.inventory_2_outlined,
                color: AppColors.cyan,
                onTap: () => _openProductForm(),
              ),
              QuickActionButton(
                width: width,
                label: 'Ajouter client',
                detail: 'Nom, téléphone, MF',
                icon: Icons.person_add_alt_1_outlined,
                color: AppColors.success,
                onTap: () => _showPartnerDialog(type: PartnerType.client),
              ),
              QuickActionButton(
                width: width,
                label: 'Sortie camion',
                detail: 'Charger un camion',
                icon: Icons.local_shipping_outlined,
                color: AppColors.primaryContainer,
                onTap: () => _openBonSortieForm(),
              ),
              QuickActionButton(
                width: width,
                label: 'Voir documents',
                detail: 'PDF, paiements, suivis',
                icon: Icons.description_outlined,
                color: AppColors.success,
                onTap: () => _updateState(() => _section = Section.documents),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBestSellersPanel(List<MapEntry<Product, int>> bestSellers) {
    return Panel(
      title: 'Meilleures ventes',
      child: Column(
        children: [
          if (bestSellers.isEmpty)
            const EmptyState(
              text: 'Les ventes apparaîtront après facturation.',
              icon: Icons.trending_up,
            )
          else
            for (final entry in bestSellers)
              ListRow(
                leading: Icons.trending_up,
                title: entry.key.name,
                subtitle: '${entry.key.category} · ${entry.key.sku}',
                trailing: SmallChip(label: '${entry.value} vendu'),
              ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityPanel() {
    final entries = _recentActivityEntries();
    return Panel(
      title: 'Activité récente',
      child: Column(
        children: [
          if (entries.isEmpty)
            const EmptyState(
              text:
                  'Commencez par ajouter un produit ou faire une première vente.',
              icon: Icons.history,
            )
          else
            for (final entry in entries.take(6))
              ListRow(
                leading: entry.icon,
                title: entry.title,
                subtitle: '${entry.subtitle} · ${formatDate(entry.date)}',
                trailing: entry.trailing == null
                    ? const SizedBox.shrink()
                    : SmallChip(label: entry.trailing!),
              ),
        ],
      ),
    );
  }

  List<_ActivityEntry> _recentActivityEntries() {
    final entries = <_ActivityEntry>[];

    for (final document in _documents.take(10)) {
      entries.add(
        _ActivityEntry(
          icon: Icons.description_outlined,
          title: document.number,
          subtitle:
              '${document.type.label} · ${document.status.label} · ${document.partnerName}',
          trailing: formatMoney(_documentDisplayNet(document)),
          date: document.date,
        ),
      );
      for (final payment in document.payments) {
        entries.add(
          _ActivityEntry(
            icon: Icons.payments_outlined,
            title: 'Paiement ${document.number}',
            subtitle: payment.method.label,
            trailing: formatMoney(payment.amount),
            date: payment.date,
          ),
        );
      }
    }

    for (final movement in _movements.take(10)) {
      entries.add(
        _ActivityEntry(
          icon: movement.direction == StockDirection.inbound
              ? Icons.call_received
              : Icons.call_made,
          title: movement.productName,
          subtitle:
              '${movement.direction == StockDirection.inbound ? 'Entrée' : 'Sortie'} · ${_warehouseById(movement.warehouseId).name}',
          trailing: '${movement.quantity}',
          date: movement.date,
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Widget _buildBusinessHealthStrip() {
    final companyComplete =
        _company.name.trim().isNotEmpty &&
        _company.taxId.trim().isNotEmpty &&
        _company.address.trim().isNotEmpty &&
        _company.city.trim().isNotEmpty &&
        _company.phone.trim().isNotEmpty &&
        _company.email.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          SmallChip(
            label: companyComplete
                ? 'Profil société complet'
                : 'Profil à compléter',
            color: companyComplete ? AppColors.success : AppColors.warning,
          ),
          SmallChip(label: '${_warehouses.length} dépôt(s)'),
          SmallChip(label: '${_products.length} produit(s)'),
          SmallChip(label: '${_clients.length} client(s)'),
          SmallChip(label: '${_suppliers.length} fournisseur(s)'),
          SmallChip(label: '${_draftDocuments.length} brouillon(s)'),
          SmallChip(
            label: _lastSavedAt == null
                ? _storageStatus
                : 'Sauvegardé ${formatTime(_lastSavedAt!)}',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  List<MapEntry<Product, int>> _bestSellers() {
    return MetricsService.bestSellers(_documents, _products);
  }

  int _todaySalesCount() {
    final now = DateTime.now();
    return _documents.where((document) {
      final sameDay =
          document.date.year == now.year &&
          document.date.month == now.month &&
          document.date.day == now.day;
      final salesType =
          document.type == DocumentType.facture ||
          document.type == DocumentType.bl;
      return sameDay &&
          salesType &&
          document.status == DocumentStatus.validated;
    }).length;
  }

  int _openSortieCount() {
    return _documents
        .where(
          (document) =>
              document.type == DocumentType.bonSortie &&
              document.status != DocumentStatus.closed &&
              document.status != DocumentStatus.canceled,
        )
        .length;
  }

  int _documentsToFollowCount() {
    return _documents.where((document) {
      if (document.status == DocumentStatus.draft ||
          document.status == DocumentStatus.partialReturn) {
        return true;
      }
      return document.type == DocumentType.facture &&
          document.status == DocumentStatus.validated &&
          _invoiceRemainingDue(document) > .001;
    }).length;
  }
}
