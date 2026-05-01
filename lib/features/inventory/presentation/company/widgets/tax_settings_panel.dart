part of '../../inventory_shell_page.dart';

extension _InventoryTaxSettingsPanel on _InventoryHomePageState {
  Widget _buildTaxSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Fiscalité',
          subtitle: 'Réglages qui apparaissent sur les nouveaux documents.',
          actions: [
            ElevatedButton.icon(
              onPressed: _saveCompanyProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Sauvegarder'),
            ),
          ],
        ),
        Panel(
          title: 'Factures et taxes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InlineNotice(
                icon: Icons.info_outline,
                title: 'Ce que ces réglages changent',
                message:
                    'Ils s’appliquent aux nouveaux documents. Les factures déjà validées gardent leurs informations sauvegardées.',
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'TVA disponible',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  SmallChip(label: 'TVA 19%'),
                  SmallChip(label: 'TVA 13%'),
                  SmallChip(label: 'TVA 7%'),
                  SmallChip(label: 'TVA 0%'),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'La TVA utilisée dépend du produit choisi dans la vente.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Timbre fiscal',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Timbre fiscal par défaut'),
                      subtitle: const Text(
                        'Ajouté automatiquement aux nouvelles factures.',
                      ),
                      value: _company.timbreFiscalEnabled,
                      onChanged: _setDefaultTimbreFiscal,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: _timbreAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Montant',
                        suffixText: 'DT',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'Mention de bas de page',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: 520,
                    child: TextField(
                      controller: _companyFooterController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Texte ajouté aux factures',
                        helperText:
                            'Restez simple: conditions de paiement ou mention commerciale.',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListRow(
                leading: Icons.verified_outlined,
                title: 'E-facturation',
                subtitle:
                    'Non activée. Trace Ultra ne transmet aucun document à une plateforme officielle pour le moment.',
                trailing: const SmallChip(label: 'À venir', muted: true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
