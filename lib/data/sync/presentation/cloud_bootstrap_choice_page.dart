import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import '../local_tenant_data_status.dart';

/// Page shown when local data exists and user must choose what to do.
class CloudBootstrapChoicePage extends StatelessWidget {
  const CloudBootstrapChoicePage({
    super.key,
    required this.localStatus,
    required this.pendingOutboxCount,
    required this.onContinueLocal,
    required this.onPullFromCloud,
  });

  final LocalTenantDataStatus localStatus;
  final int pendingOutboxCount;
  final VoidCallback onContinueLocal;
  final VoidCallback onPullFromCloud;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.devices,
                    size: 56,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Données locales détectées',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Des données existent déjà sur cet appareil. '
                    'Voulez-vous continuer avec ces données ou télécharger '
                    'les données cloud pour cette société ?',
                    style: TextStyle(color: AppColors.muted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildDataSummary(),
                  const SizedBox(height: 24),
                  if (pendingOutboxCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '$pendingOutboxCount modification(s) non synchronisée(s). '
                              'Synchronisez avant de remplacer les données.',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Primary action: Continue local (safe default)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Continuer avec les données locales'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: onContinueLocal,
                  ),
                  const SizedBox(height: 12),
                  // Secondary action: Pull from cloud
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cloud_download_outlined),
                    label: const Text('Télécharger depuis le cloud'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      minimumSize: const Size.fromHeight(48),
                      side: BorderSide(
                        color: AppColors.danger.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: pendingOutboxCount > 0
                        ? null
                        : () => _confirmPull(context),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Le téléchargement depuis le cloud peut remplacer les '
                    'données locales de cette société. '
                    'Faites une sauvegarde avant de continuer.',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    final items = <_DataRow>[
      if (localStatus.productCount > 0)
        _DataRow('Produits', localStatus.productCount),
      if (localStatus.partnerCount > 0)
        _DataRow('Clients/Fournisseurs', localStatus.partnerCount),
      if (localStatus.documentCount > 0)
        _DataRow('Documents', localStatus.documentCount),
      if (localStatus.stockMovementCount > 0)
        _DataRow('Mouvements de stock', localStatus.stockMovementCount),
      if (localStatus.warehouseCount > 0)
        _DataRow('Dépôts', localStatus.warehouseCount),
      if (localStatus.categoryCount > 0)
        _DataRow('Catégories', localStatus.categoryCount),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Données sur cet appareil :',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmPull(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer le téléchargement'),
        content: const Text(
          'Les données locales de cette société seront remplacées '
          'par les données du cloud.\n\n'
          'Cette action est irréversible. '
          'Assurez-vous d\'avoir une sauvegarde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              onPullFromCloud();
            },
            child: const Text('Remplacer les données'),
          ),
        ],
      ),
    );
  }
}

class _DataRow {
  const _DataRow(this.label, this.count);

  final String label;
  final int count;
}
