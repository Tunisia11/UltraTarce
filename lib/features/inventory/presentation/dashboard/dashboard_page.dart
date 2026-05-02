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
              'Ce qui demande votre attention maintenant: vendre, encaisser, stock.',
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
          title: 'Prêt à travailler',
          subtitle:
              'Commencez par une action simple. Les chiffres apparaîtront après les premières ventes.',
        ),
        Panel(
          title: 'Que voulez-vous faire maintenant ?',
          child: LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final width = _responsiveTileWidth(
                maxWidth: constraints.maxWidth,
                minTileWidth: 210,
                spacing: spacing,
                maxColumns: 3,
              );
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  QuickActionButton(
                    width: width,
                    label: 'Faire une vente',
                    detail: 'Produit, quantité, validation',
                    icon: Icons.flash_on_outlined,
                    color: AppColors.primary,
                    onTap: _goToSales,
                  ),
                  QuickActionButton(
                    width: width,
                    label: 'Ajouter produit',
                    detail: 'Nom, prix, stock',
                    icon: Icons.add_box_outlined,
                    color: AppColors.cyan,
                    onTap: () => _openProductForm(),
                  ),
                  QuickActionButton(
                    width: width,
                    label: 'Ajouter client',
                    detail: 'Nom et téléphone',
                    icon: Icons.person_add_alt_1_outlined,
                    color: AppColors.success,
                    onTap: () => _showPartnerDialog(type: PartnerType.client),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        const InlineNotice(
          icon: Icons.insights_outlined,
          title: 'Pas encore de chiffres utiles',
          message:
              'Trace Ultra affichera le chiffre d’affaires, les alertes et l’activité dès qu’il y aura des ventes ou des stocks à suivre.',
          color: AppColors.primary,
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
          title: 'Préparer votre magasin',
          subtitle: 'Tarek vous accompagne vers une première vente réelle.',
          actions: [
            ElevatedButton.icon(
              key: _dashboardPrimaryActionKey,
              onPressed: _startFirstSuccessGuide,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Démarrer avec Tarek'),
            ),
          ],
        ),
        _buildGettingStartedPanel(),
        const SizedBox(height: 18),
        Panel(
          title: 'Pour l’instant, une seule priorité',
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
      return 'Ajoutez un produit réel: nom, code, prix, stock. Le reste peut attendre.';
    }
    if (!_hasFirstClient) {
      return 'Ajoutez un client, ou créez simplement un client comptoir.';
    }
    return 'Vous êtes prêt: client, produit, quantité, validation.';
  }

  Widget _buildLowStockPanel() {
    return Panel(
      title: 'Alertes stock',
      child: Column(
        children: [
          if (_lowStockProducts.isEmpty)
            const EmptyState(text: 'Aucune alerte pour le moment.')
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
          maxColumns: 4,
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
              label: 'CA du mois',
              value: formatMoney(_monthlySales),
              detail:
                  '${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
              accent: AppColors.cyan,
              icon: Icons.calendar_month_outlined,
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
              label: 'À terminer',
              value: '${_draftDocuments.length}',
              detail: 'Ventes ou suivis en attente',
              accent: AppColors.danger,
              icon: Icons.lock_clock_outlined,
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
                      'On crée un produit, un client, puis une vente réelle. Pas besoin de remplir tous les détails maintenant.',
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
                    key: _firstProductStepKey,
                    number: '1',
                    title: 'Premier produit',
                    subtitle: 'Nom, prix, stock',
                    done: _hasFirstProduct,
                    onTap: () => _openProductForm(),
                  ),
                  StepPill(
                    key: _firstClientStepKey,
                    number: '2',
                    title: 'Premier client',
                    subtitle: 'Nom, téléphone',
                    done: _hasFirstClient,
                    onTap: () => _showPartnerDialog(type: PartnerType.client),
                  ),
                  StepPill(
                    key: _firstSaleStepKey,
                    number: '3',
                    title: 'Première vente',
                    subtitle: 'Produit, total, valider',
                    done: _hasFirstSale,
                    onTap: () => _goToSales(),
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
                label: 'Sortie camion',
                detail: 'Charger produits dans un véhicule',
                icon: Icons.local_shipping_outlined,
                color: AppColors.cyan,
                onTap: () => _openBonSortieForm(),
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
                label: 'Stock faible',
                detail: '${_lowStockProducts.length} à traiter',
                icon: Icons.warning_amber_outlined,
                color: _lowStockProducts.isEmpty
                    ? AppColors.muted
                    : AppColors.warning,
                onTap: () => _updateState(() => _section = Section.stock),
              ),
              QuickActionButton(
                width: width,
                label: 'À terminer',
                detail: '${_draftDocuments.length} en attente',
                icon: Icons.lock_clock_outlined,
                color: _draftDocuments.isEmpty
                    ? AppColors.muted
                    : AppColors.danger,
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
            const EmptyState(text: 'Les ventes apparaîtront après facturation.')
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
            const EmptyState(text: 'Aucune activité récente pour le moment.')
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
}
