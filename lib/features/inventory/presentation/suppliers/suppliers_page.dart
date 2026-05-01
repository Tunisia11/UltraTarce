part of '../inventory_shell_page.dart';

extension _InventorySuppliersPage on _InventoryHomePageState {
  Widget _buildSuppliers() {
    return _buildPartnerList(
      type: PartnerType.supplier,
      title: 'Fournisseurs',
      subtitle: 'Contacts fournisseurs lisibles, sans tableau lourd.',
      actionLabel: 'Nouveau fournisseur',
    );
  }
}
