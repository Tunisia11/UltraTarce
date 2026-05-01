part of '../inventory_shell_page.dart';

extension _InventoryClientsPage on _InventoryHomePageState {
  Widget _buildCustomers() {
    return _buildPartnerList(
      type: PartnerType.client,
      title: 'Clients',
      subtitle:
          'Contacts utiles pour vendre vite, avec client comptoir si besoin.',
      actionLabel: 'Nouveau client',
    );
  }

  Widget _buildPartnerList({
    required PartnerType type,
    required String title,
    required String subtitle,
    required String actionLabel,
  }) {
    final partners = _partners
        .where((partner) => partner.type == type)
        .toList();
    final activeCount = partners.where((partner) => partner.active).length;
    final walkInCount = type == PartnerType.client
        ? partners
              .where(
                (partner) =>
                    partner.name.toLowerCase().contains('comptoir') &&
                    partner.active,
              )
              .length
        : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: title,
          subtitle: subtitle,
          actions: [
            ElevatedButton.icon(
              key: type == PartnerType.client ? _clientCreateActionKey : null,
              onPressed: () => _showPartnerDialog(type: type),
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
            if (type == PartnerType.client)
              OutlinedButton.icon(
                onPressed: () => _showPartnerDialog(
                  type: PartnerType.client,
                  walkInClient: true,
                ),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Client comptoir'),
              ),
            OutlinedButton.icon(
              onPressed: () => _exportPartnersCsv(type),
              icon: const Icon(Icons.table_view_outlined),
              label: const Text('Exporter CSV'),
            ),
          ],
        ),
        Panel(
          title: title,
          trailing: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SmallChip(label: '$activeCount actif(s)'),
              if (type == PartnerType.client)
                SmallChip(
                  label: '$walkInCount comptoir',
                  color: walkInCount == 0 ? AppColors.muted : AppColors.cyan,
                ),
            ],
          ),
          child: partners.isEmpty
              ? EmptyState(
                  text: type == PartnerType.client
                      ? 'Aucun client. Ajoutez un client ou créez un client comptoir pour les ventes rapides.'
                      : 'Aucun fournisseur. Ajoutez un contact quand vous commencez à recevoir du stock.',
                  icon: type == PartnerType.client
                      ? Icons.groups_2_outlined
                      : Icons.handshake_outlined,
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final columns = maxWidth >= 1040
                        ? 3
                        : maxWidth >= 680
                        ? 2
                        : 1;
                    final cardWidth = (maxWidth - (columns - 1) * 12) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final partner in partners)
                          _buildPartnerCard(
                            type: type,
                            partner: partner,
                            width: cardWidth,
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPartnerCard({
    required PartnerType type,
    required Partner partner,
    required double width,
  }) {
    final isClient = type == PartnerType.client;
    final isWalkIn =
        isClient && partner.name.toLowerCase().contains('comptoir');
    final contactLine = [
      if (partner.phone.isNotEmpty) partner.phone,
      if (partner.email.isNotEmpty) partner.email,
    ].join(' · ');
    final contextLine = [
      if (isClient) partner.customerType.label,
      if (partner.city.isNotEmpty) partner.city,
      if (partner.companyName.isNotEmpty) partner.companyName,
    ].join(' · ');

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (isClient ? AppColors.primary : AppColors.cyan)
                        .withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isClient ? Icons.person_outline : Icons.handshake_outlined,
                    color: isClient ? AppColors.primary : AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contactLine.isEmpty
                            ? 'Contact à compléter'
                            : contactLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SmallChip(
                  label: partner.active ? 'Actif' : 'Inactif',
                  color: partner.active ? AppColors.success : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (contextLine.isNotEmpty)
                  SmallChip(label: contextLine, muted: true),
                if (isWalkIn)
                  const SmallChip(label: 'Comptoir', color: AppColors.cyan),
                if (partner.taxId.isNotEmpty)
                  const SmallChip(label: 'MF enregistré', muted: true),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _showPartnerDialog(type: type, partner: partner),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Modifier'),
                ),
              ],
            ),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text(
                  'Détails',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  _partnerDetailsSummary(partner, isClient: isClient),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (partner.taxId.isNotEmpty)
                          SmallChip(label: 'MF ${partner.taxId}', muted: true),
                        if (partner.address.isNotEmpty)
                          SmallChip(label: partner.address, muted: true),
                        if (partner.contactName.isNotEmpty)
                          SmallChip(
                            label: 'Contact ${partner.contactName}',
                            muted: true,
                          ),
                        if (partner.email.isNotEmpty)
                          SmallChip(label: partner.email, muted: true),
                      ],
                    ),
                  ),
                  if (partner.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        partner.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _deletePartner(partner),
                      icon: Icon(
                        partner.active
                            ? Icons.block_outlined
                            : Icons.delete_outline,
                        size: 16,
                      ),
                      label: Text(partner.active ? 'Désactiver' : 'Supprimer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _partnerDetailsSummary(Partner partner, {required bool isClient}) {
    final items = [
      if (partner.taxId.isNotEmpty) 'MF',
      if (partner.address.isNotEmpty) 'adresse',
      if (partner.notes.isNotEmpty) 'notes',
      if (!isClient && partner.contactName.isNotEmpty) 'contact',
    ];
    return items.isEmpty ? 'Aucun détail avancé' : items.join(' · ');
  }
}
