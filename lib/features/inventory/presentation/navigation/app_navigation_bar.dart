part of '../inventory_shell_page.dart';

extension _InventoryAppNavigationBar on _InventoryHomePageState {
  Widget _buildMobileNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: .18)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                _buildSystemLogoTile(width: 52, height: 36),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Trace Ultra',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                _systemStatusPill(),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                for (final section in const [
                  Section.dashboard,
                  Section.sales,
                  Section.stock,
                  Section.products,
                  Section.customers,
                  Section.documents,
                  Section.purchases,
                  Section.suppliers,
                  Section.reports,
                  Section.settings,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(section.label),
                      selected: _section == section,
                      onSelected: (_) => section == Section.sales
                          ? _goToSales()
                          : _updateState(() => _section = section),
                      selectedColor: AppColors.primaryContainer.withValues(
                        alpha: .12,
                      ),
                      backgroundColor: AppColors.surfaceLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
