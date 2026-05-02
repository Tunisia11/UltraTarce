part of '../inventory_shell_page.dart';

extension _InventoryAppSideMenu on _InventoryHomePageState {
  Widget _buildSidebar() {
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(
          right: BorderSide(color: AppColors.border.withValues(alpha: .20)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSystemLogoTile(width: 52, height: 38),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trace Ultra',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                      Text(
                        'Gestion locale PME',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goToSales(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Faire une vente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _primaryNavButton(
              section: Section.dashboard,
              label: 'Tableau',
              detail: 'Priorités du jour',
              icon: Icons.dashboard_outlined,
            ),
            _primaryNavButton(
              section: Section.sales,
              label: 'Vendre',
              detail: 'Action guidée',
              icon: Icons.flash_on_outlined,
            ),
            _primaryNavButton(
              section: Section.stock,
              label: 'Stock',
              detail: 'Entrées, transferts',
              icon: Icons.warehouse_outlined,
            ),
            _primaryNavButton(
              section: Section.products,
              label: 'Produits',
              detail: 'Prix, TVA, stock',
              icon: Icons.inventory_2_outlined,
            ),
            _primaryNavButton(
              section: Section.customers,
              label: 'Clients',
              detail: 'Contacts, MF',
              icon: Icons.groups_2_outlined,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _navGroupLabel('Secondaire'),
                    _secondaryNavGroup(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _localDataCard(),
          ],
        ),
      ),
    );
  }

  Widget _navGroupLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }

  Widget _secondaryNavGroup() {
    const sections = [
      Section.documents,
      Section.purchases,
      Section.suppliers,
      Section.reports,
      Section.settings,
      Section.tax,
      Section.audit,
      Section.team,
    ];
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: sections.contains(_section),
        tilePadding: const EdgeInsets.symmetric(horizontal: 6),
        childrenPadding: EdgeInsets.zero,
        leading: const Icon(Icons.more_horiz, color: AppColors.muted),
        title: const Text(
          'Plus',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: const Text(
          'Documents, achats, rapports, société',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [for (final section in sections) _navButton(section)],
      ),
    );
  }

  Widget _primaryNavButton({
    required Section section,
    required String label,
    required String detail,
    required IconData icon,
  }) {
    final selected = _section == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => section == Section.sales
              ? _goToSales()
              : _updateState(() => _section = section),
          child: Container(
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryContainer.withValues(alpha: .08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.emerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 9),
                Icon(
                  icon,
                  size: 21,
                  color: selected ? AppColors.primaryDark : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: selected
                              ? AppColors.primaryDark
                              : AppColors.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? AppColors.primary : AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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

  Widget _navButton(Section section) {
    final selected = _section == section;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _updateState(() => _section = section),
          child: Container(
            constraints: const BoxConstraints(minHeight: 46),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryContainer.withValues(alpha: .08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  width: 3,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.emerald : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 9),
                Icon(
                  section.icon,
                  size: 20,
                  color: selected ? AppColors.primaryDark : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    section.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.primaryDark : AppColors.ink,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _localDataCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow.withValues(alpha: .72),
        border: Border.all(color: AppColors.border.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.primaryContainer,
                child: Icon(Icons.storage_outlined, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sauvegarde locale',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _lastSavedAt == null
                          ? _storageStatus
                          : 'OK ${formatTime(_lastSavedAt!)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              SmallChip(label: '${_products.length} produits'),
              SmallChip(label: '${_documents.length} documents', muted: true),
            ],
          ),
        ],
      ),
    );
  }
}
