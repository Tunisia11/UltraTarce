import 'package:flutter/material.dart';
import '../../data/admin_subscription_models.dart';

class AdminSubscriptionEditorDialog extends StatefulWidget {
  const AdminSubscriptionEditorDialog({
    super.key,
    required this.subscription,
    required this.onSave,
  });

  final AdminTenantSubscription subscription;
  final Future<void> Function({
    required String plan,
    required String status,
    required String billingCycle,
    double? priceTnd,
    int? seatsLimit,
    DateTime? currentPeriodEndsAt,
    String? adminNotes,
  })
  onSave;

  @override
  State<AdminSubscriptionEditorDialog> createState() =>
      _AdminSubscriptionEditorDialogState();
}

class _AdminSubscriptionEditorDialogState
    extends State<AdminSubscriptionEditorDialog> {
  late String _status;
  late String _plan;
  late String _billingCycle;
  late TextEditingController _priceController;
  late TextEditingController _seatsController;
  late TextEditingController _notesController;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.subscription.status;
    _plan = widget.subscription.plan;
    _billingCycle = widget.subscription.billingCycle;
    _priceController = TextEditingController(
      text: widget.subscription.priceTnd?.toString() ?? '',
    );
    _seatsController = TextEditingController(
      text: widget.subscription.seatsLimit?.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.subscription.adminNotes ?? '',
    );
    _endDate = widget.subscription.currentPeriodEndsAt;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _seatsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      await widget.onSave(
        plan: _plan,
        status: _status,
        billingCycle: _billingCycle,
        priceTnd: double.tryParse(_priceController.text),
        seatsLimit: int.tryParse(_seatsController.text),
        currentPeriodEndsAt: _endDate,
        adminNotes: _notesController.text.isNotEmpty
            ? _notesController.text
            : null,
      );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Modifier Abonnement - ${widget.subscription.tenantName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: const [
                DropdownMenuItem(value: 'trial', child: Text('Essai')),
                DropdownMenuItem(value: 'active', child: Text('Actif')),
                DropdownMenuItem(value: 'overdue', child: Text('En retard')),
                DropdownMenuItem(value: 'suspended', child: Text('Suspendu')),
                DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
              ],
              onChanged: (v) => setState(() => _status = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _plan,
              decoration: const InputDecoration(labelText: 'Plan'),
              items: const [
                DropdownMenuItem(value: 'pilot', child: Text('Pilot')),
                DropdownMenuItem(value: 'basic', child: Text('Basic')),
                DropdownMenuItem(value: 'pro', child: Text('Pro')),
                DropdownMenuItem(
                  value: 'enterprise',
                  child: Text('Enterprise'),
                ),
              ],
              onChanged: (v) => setState(() => _plan = v!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _billingCycle,
              decoration: const InputDecoration(labelText: 'Cycle'),
              items: const [
                DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
                DropdownMenuItem(value: 'yearly', child: Text('Annuel')),
                DropdownMenuItem(value: 'custom', child: Text('Personnalisé')),
              ],
              onChanged: (v) => setState(() => _billingCycle = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Prix TND'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _seatsController,
              decoration: const InputDecoration(
                labelText: 'Limite utilisateurs',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fin période: ${_endDate != null ? _endDate.toString().split(' ')[0] : '-'}',
                  ),
                ),
                TextButton(onPressed: _pickDate, child: const Text('Choisir')),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes internes'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
