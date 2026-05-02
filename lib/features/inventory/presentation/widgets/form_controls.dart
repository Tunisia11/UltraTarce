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
