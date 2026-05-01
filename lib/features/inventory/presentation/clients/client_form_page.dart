part of '../inventory_shell_page.dart';

extension _InventoryClientFormPage on _InventoryHomePageState {
  Future<void> _showPartnerDialog({
    required PartnerType type,
    Partner? partner,
    bool walkInClient = false,
  }) async {
    final name = TextEditingController(
      text: partner?.name ?? (walkInClient ? 'Client comptoir' : ''),
    );
    final company = TextEditingController(text: partner?.companyName ?? '');
    final contact = TextEditingController(text: partner?.contactName ?? '');
    final taxId = TextEditingController(text: partner?.taxId ?? '');
    final phone = TextEditingController(text: partner?.phone ?? '');
    final email = TextEditingController(text: partner?.email ?? '');
    final address = TextEditingController(text: partner?.address ?? '');
    final city = TextEditingController(text: partner?.city ?? '');
    final notes = TextEditingController(text: partner?.notes ?? '');
    final isNewClient = type == PartnerType.client && partner == null;
    var customerType =
        partner?.customerType ??
        (type == PartnerType.client
            ? CustomerType.particulier
            : CustomerType.entreprise);
    var active = partner?.active ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text(
            partner == null
                ? (type == PartnerType.client
                      ? 'Nouveau client'
                      : 'Nouveau fournisseur')
                : (type == PartnerType.client
                      ? 'Modifier client'
                      : 'Modifier fournisseur'),
          ),
          content: SizedBox(
            width: isNewClient ? 640 : 720,
            child: SingleChildScrollView(
              child: isNewClient
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_hasFirstClient) ...[
                          _guidedDialogHint(
                            title: 'Tarek: un contact suffit',
                            message:
                                'Mettez le nom du client. Pour une vente comptoir, utilisez le raccourci ci-dessous.',
                          ),
                          const SizedBox(height: 14),
                        ],
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _dialogField(
                              width: 320,
                              controller: name,
                              label: 'Nom client',
                            ),
                            _dialogField(
                              width: 190,
                              controller: phone,
                              label: 'Téléphone (optionnel)',
                            ),
                            SizedBox(
                              width: 190,
                              child: DropdownButtonFormField<CustomerType>(
                                initialValue: customerType,
                                decoration: const InputDecoration(
                                  labelText: 'Type',
                                ),
                                items: [
                                  for (final item in CustomerType.values)
                                    DropdownMenuItem(
                                      value: item,
                                      child: Text(item.label),
                                    ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      customerType = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  name.text = 'Client comptoir';
                                  phone.clear();
                                  taxId.clear();
                                  address.clear();
                                  email.clear();
                                  company.clear();
                                  contact.clear();
                                  city.clear();
                                  customerType = CustomerType.particulier;
                                });
                              },
                              icon: const Icon(Icons.storefront_outlined),
                              label: const Text('Client comptoir'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            initiallyExpanded: false,
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(top: 8),
                            leading: const Icon(Icons.tune_outlined),
                            title: const Text(
                              'Informations avancées',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                            subtitle: const Text(
                              'Matricule fiscal, adresse, email et notes.',
                            ),
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _dialogField(
                                    width: 260,
                                    controller: company,
                                    label: 'Raison sociale',
                                  ),
                                  _dialogField(
                                    width: 220,
                                    controller: taxId,
                                    label: 'Matricule fiscal',
                                  ),
                                  _dialogField(
                                    width: 260,
                                    controller: email,
                                    label: 'Email',
                                  ),
                                  _dialogField(
                                    width: 420,
                                    controller: address,
                                    label: 'Adresse',
                                  ),
                                  _dialogField(
                                    width: 180,
                                    controller: city,
                                    label: 'Ville',
                                  ),
                                  SizedBox(
                                    width: 600,
                                    child: TextField(
                                      controller: notes,
                                      minLines: 2,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        labelText: 'Notes',
                                        alignLabelWithHint: true,
                                      ),
                                    ),
                                  ),
                                  _switchTile(
                                    label: 'Actif',
                                    value: active,
                                    onChanged: (value) =>
                                        setDialogState(() => active = value),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (type == PartnerType.client &&
                            partner == null &&
                            !_hasFirstClient)
                          _guidedDialogHint(
                            title: 'Tarek: un client comptoir suffit',
                            message:
                                'Un nom clair est le minimum. Ajoutez le téléphone ou le matricule fiscal si vous les avez, sinon vous pourrez revenir plus tard.',
                          ),
                        if (type == PartnerType.client)
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<CustomerType>(
                              initialValue: customerType,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                              ),
                              items: [
                                for (final item in CustomerType.values)
                                  DropdownMenuItem(
                                    value: item,
                                    child: Text(item.label),
                                  ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setDialogState(() => customerType = value);
                                }
                              },
                            ),
                          ),
                        _dialogField(
                          width: 300,
                          controller: name,
                          label: type == PartnerType.client
                              ? 'Nom affiché'
                              : 'Société',
                        ),
                        _dialogField(
                          width: 260,
                          controller: company,
                          label: 'Raison sociale',
                        ),
                        _dialogField(
                          width: 240,
                          controller: contact,
                          label: 'Contact',
                        ),
                        _dialogField(
                          width: 220,
                          controller: taxId,
                          label: 'Matricule fiscal',
                        ),
                        _dialogField(
                          width: 190,
                          controller: phone,
                          label: 'Téléphone',
                        ),
                        _dialogField(
                          width: 260,
                          controller: email,
                          label: 'Email',
                        ),
                        _dialogField(
                          width: 420,
                          controller: address,
                          label: 'Adresse',
                        ),
                        _dialogField(
                          width: 180,
                          controller: city,
                          label: 'Ville',
                        ),
                        SizedBox(
                          width: 650,
                          child: TextField(
                            controller: notes,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Notes',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ),
                        _switchTile(
                          label: 'Actif',
                          value: active,
                          onChanged: (value) =>
                              setDialogState(() => active = value),
                        ),
                      ],
                    ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (name.text.trim().isEmpty) {
                  _showMessage('Nom obligatoire.', isError: true);
                  return;
                }
                final updated = Partner(
                  id:
                      partner?.id ??
                      _newId(type == PartnerType.client ? 'cli' : 'four'),
                  type: type,
                  name: name.text.trim(),
                  taxId: taxId.text.trim(),
                  address: address.text.trim(),
                  phone: phone.text.trim(),
                  email: email.text.trim(),
                  customerType: customerType,
                  companyName: company.text.trim(),
                  contactName: contact.text.trim(),
                  city: city.text.trim(),
                  notes: notes.text.trim(),
                  active: active,
                );
                _updateState(() {
                  if (updated.type == PartnerType.client) {
                    final cubit = _clientsCubit;
                    if (partner == null) {
                      cubit.createClient(updated);
                    } else {
                      cubit.updateClient(updated);
                    }
                  } else {
                    final cubit = _suppliersCubit;
                    if (partner == null) {
                      cubit.createSupplier(updated);
                    } else {
                      cubit.updateSupplier(updated);
                    }
                  }
                  _applyRepositoryState();
                  _ensureSelections();
                });
                Navigator.of(dialogContext).pop();
                _syncGuidedProgressAfterMutation();
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _deletePartner(Partner partner) {
    _updateState(() {
      if (partner.type == PartnerType.client) {
        _clientsCubit.deleteOrArchiveClient(partner);
      } else {
        _suppliersCubit.deleteOrArchiveSupplier(partner);
      }
      _applyRepositoryState();
    });
  }
}
