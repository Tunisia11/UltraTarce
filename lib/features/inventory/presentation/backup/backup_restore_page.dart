part of '../inventory_shell_page.dart';

extension _InventoryBackupRestorePage on _InventoryHomePageState {
  Future<void> _showBackupExport() async {
    final export = _backupCubit.exportBackup();
    final message = await saveTextFile(
      fileName: 'trace-ultra-base-locale.json',
      contents: export,
      mimeType: 'application/json;charset=utf-8',
    );
    _showMessage(message);
  }

  void _showBackupImport() {
    _backupImportController.clear();
    var restoreConfirmed = false;
    var hasBackupText = false;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Restaurer une sauvegarde'),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const InlineNotice(
                    icon: Icons.warning_amber_outlined,
                    title: 'Action importante',
                    message:
                        'La restauration remplace la base locale actuelle par le contenu du fichier collé. Exportez une sauvegarde avant de continuer si vous avez un doute.',
                    color: AppColors.warning,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: restoreConfirmed,
                    onChanged: (value) =>
                        setDialogState(() => restoreConfirmed = value ?? false),
                    title: const Text(
                      'Je comprends que mes données locales seront remplacées',
                    ),
                    subtitle: const Text(
                      'Trace Ultra vérifiera le fichier avant de restaurer.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _backupImportController,
                    minLines: 8,
                    maxLines: 14,
                    onChanged: (value) => setDialogState(
                      () => hasBackupText = value.trim().isNotEmpty,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Coller ici le contenu JSON de sauvegarde',
                      helperText:
                          'Utilisez uniquement un export Trace Ultra de confiance.',
                      alignLabelWithHint: true,
                    ),
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
            ElevatedButton.icon(
              onPressed: restoreConfirmed && hasBackupText
                  ? () {
                      Navigator.of(dialogContext).pop();
                      _restoreBackup(_backupImportController.text);
                    }
                  : null,
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Remplacer avec cette sauvegarde'),
            ),
          ],
        ),
      ),
    );
  }

  void _restoreBackup(String raw) {
    try {
      final preview = _backupCubit.importBackupPreview(raw);
      final snapshot = preview.snapshot;
      if (snapshot.warehouses.isEmpty) {
        throw const FormatException('Base locale incomplète');
      }

      _updateState(() {
        _backupCubit.confirmRestore(preview);
        _applyRepositoryState();
        _syncCompanyControllers();
        _section = Section.audit;
      });
      _showMessage(
        'Sauvegarde restaurée. Vérifiez l’historique et la société.',
      );
    } catch (_) {
      _showMessage(
        'Restauration impossible: fichier invalide ou incomplet.',
        isError: true,
      );
    }
  }

  Widget _buildLocalDatabasePanel() {
    final savedAt = _lastSavedAt;
    final savedTitle = savedAt == null
        ? 'Sauvegarde locale prête'
        : 'Dernière sauvegarde ${formatTime(savedAt)}';
    final savedDetail = savedAt == null
        ? _storageStatus
        : '${formatDate(savedAt)} · ${persistentStoreLabel()}';
    final validatedDocuments = _documents
        .where((document) => document.status == DocumentStatus.validated)
        .length;
    return Panel(
      title: 'Sauvegarde locale',
      trailing: const SmallChip(
        label: 'Sur cet appareil',
        color: AppColors.cyan,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocalStatusBanner(title: savedTitle, detail: savedDetail),
          const SizedBox(height: 14),
          if (_appConfig.cloudPilotEnabled) ...[
            const InlineNotice(
              icon: Icons.cloud_done_outlined,
              title: SyncPilotMessages.modeLabel,
              message:
                  '${SyncPilotMessages.localThenCloud} ${SyncPilotMessages.oneDevicePilot}',
              color: AppColors.cyan,
            ),
            const SizedBox(height: 12),
          ],
          const InlineNotice(
            icon: Icons.download_for_offline_outlined,
            title: 'Conseil sauvegarde',
            message: SyncPilotMessages.backupReminder,
            color: AppColors.success,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildStorageStat(
                icon: Icons.inventory_2_outlined,
                label: 'Articles',
                value: '${_products.length}',
              ),
              _buildStorageStat(
                icon: Icons.verified_outlined,
                label: 'Validés',
                value: '$validatedDocuments',
              ),
              _buildStorageStat(
                icon: Icons.history_outlined,
                label: 'Audit',
                value: '${_auditEvents.length}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListRow(
            leading: Icons.storage_outlined,
            title: 'Données enregistrées localement',
            subtitle:
                'Vos informations restent sur cet appareil: ${persistentStoreLabel()}.',
            trailing: const SmallChip(label: 'Local'),
          ),
          ListRow(
            leading: Icons.security_outlined,
            title: 'Documents protégés',
            subtitle:
                'Les documents validés sont verrouillés et les actions importantes sont gardées dans l’historique.',
            trailing: const SmallChip(label: 'Actif', color: AppColors.success),
          ),
          ListRow(
            leading: Icons.restore_page_outlined,
            title: 'Copie de sécurité portable',
            subtitle:
                'Exportez un fichier JSON avant une manipulation importante ou un changement d’appareil.',
            trailing: const SmallChip(label: 'JSON'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: _showBackupExport,
                icon: const Icon(Icons.download_outlined),
                label: const Text('Télécharger une sauvegarde'),
              ),
              ElevatedButton.icon(
                onPressed: _showBackupImport,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Restaurer une sauvegarde'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _onboardingCubit.resetGuidanceForTesting();
                  _startFirstSuccessGuide();
                  _updateState(() => _section = Section.dashboard);
                },
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Relancer le guide'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocalStatusBanner({
    required String title,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .08),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.save_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 128,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.cyan, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
