part of '../inventory_shell_page.dart';

extension _InventoryFormControls on _InventoryHomePageState {
  Widget _dialogField({
    required double width,
    required TextEditingController controller,
    required String label,
    bool number = false,
    ValueChanged<String>? onChanged,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _priceTtcPreview({required double saleHt, required TvaRate tvaRate}) {
    return SizedBox(
      width: 170,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.emerald.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.emerald.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prix TTC',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 3),
            Text(
              formatMoney(
                TaxService.totalTtc(taxableHt: saleHt, rate: tvaRate),
              ),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SizedBox(
      width: 180,
      child: SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _fieldBox({required Widget child, double width = 220}) {
    return SizedBox(width: width, child: child);
  }
}
