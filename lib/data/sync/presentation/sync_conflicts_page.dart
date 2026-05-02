import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../sync_conflict_models.dart';
import '../sync_conflict_repository.dart';
import '../sync_conflict_service.dart';

class SyncConflictsPage extends StatelessWidget {
  const SyncConflictsPage({
    super.key,
    required this.conflictRepository,
    required this.conflictService,
    required this.tenantId,
  });

  final SyncConflictRepository conflictRepository;
  final SyncConflictService conflictService;
  final String tenantId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conflits de synchronisation'),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: _SyncConflictsView(
        conflictRepository: conflictRepository,
        conflictService: conflictService,
        tenantId: tenantId,
      ),
    );
  }
}

class _SyncConflictsView extends StatefulWidget {
  const _SyncConflictsView({
    required this.conflictRepository,
    required this.conflictService,
    required this.tenantId,
  });

  final SyncConflictRepository conflictRepository;
  final SyncConflictService conflictService;
  final String tenantId;

  @override
  State<_SyncConflictsView> createState() => _SyncConflictsViewState();
}

class _SyncConflictsViewState extends State<_SyncConflictsView> {
  void _refresh() => setState(() {});

  Future<void> _handleResolution(
    BuildContext context,
    SyncConflict conflict,
    String type,
  ) async {
    final title = switch (type) {
      'keep_local' => 'Conserver la version locale ?',
      'keep_cloud' => 'Remplacer par la version cloud ?',
      'ignore' => 'Ignorer ce conflit ?',
      _ => 'Confirmer l\'action ?',
    };

    final message = switch (type) {
      'keep_local' =>
        'La version locale sera conservée et renvoyée vers le cloud lors de la prochaine synchronisation.',
      'keep_cloud' =>
        'La version locale sera remplacée par la version cloud. Les modifications locales non synchronisées seront perdues.',
      'ignore' =>
        'Le conflit sera masqué. Vous pourrez le retrouver plus tard.',
      _ => '',
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      try {
        switch (type) {
          case 'keep_local':
            await widget.conflictService.resolveKeepLocal(conflict.id);
            messenger.showSnackBar(
              const SnackBar(
                content: Text(
                  'Version locale conservée. Elle sera synchronisée au prochain envoi.',
                ),
              ),
            );
          case 'keep_cloud':
            await widget.conflictService.resolveKeepCloud(conflict.id);
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Version cloud appliquée localement.'),
              ),
            );
          case 'ignore':
            await widget.conflictService.ignoreConflict(conflict.id);
            messenger.showSnackBar(
              const SnackBar(content: Text('Conflit ignoré pour l\'instant.')),
            );
        }
        _refresh();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur lors de la résolution: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SyncConflict>>(
      future: widget.conflictRepository.getOpenConflicts(
        tenantId: widget.tenantId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 48,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 16),
                Text('À vérifier: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
        final conflicts = snapshot.data ?? [];
        if (conflicts.isEmpty) {
          return Center(
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.surfaceLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: .22),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: .04),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 56,
                    color: AppColors.success,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Aucun conflit. Vos données sont propres.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Les données locales sont conservées et prêtes à synchroniser.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: conflicts.length,
          itemBuilder: (context, index) {
            final conflict = conflicts[index];
            return Card(
              color: AppColors.surfaceLowest,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: AppColors.border.withValues(alpha: .22),
                ),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: _getReasonColor(
                    conflict.reason,
                  ).withValues(alpha: 0.1),
                  child: Icon(
                    _getReasonIcon(conflict.reason),
                    color: _getReasonColor(conflict.reason),
                  ),
                ),
                title: Text(
                  '${_getEntityLabel(conflict.entityType)} : ${conflict.entityId.length > 8 ? conflict.entityId.substring(0, 8) : conflict.entityId}...',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(conflict.reasonLabel),
                trailing: Text(
                  '${conflict.createdAt.day}/${conflict.createdAt.month} ${conflict.createdAt.hour}:${conflict.createdAt.minute}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PayloadSection(
                          title: 'Version locale',
                          json: conflict.localPayloadJson,
                          entityType: conflict.entityType,
                        ),
                        const SizedBox(height: 16),
                        _PayloadSection(
                          title: 'Version cloud',
                          json: conflict.remotePayloadJson,
                          entityType: conflict.entityType,
                        ),
                        const Divider(height: 32),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _handleResolution(
                                context,
                                conflict,
                                'ignore',
                              ),
                              icon: const Icon(
                                Icons.visibility_off_outlined,
                                size: 18,
                              ),
                              label: const Text('Ignorer'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _handleResolution(
                                context,
                                conflict,
                                'keep_cloud',
                              ),
                              icon: const Icon(
                                Icons.cloud_download_outlined,
                                size: 18,
                              ),
                              label: const Text('Garder cloud'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _handleResolution(
                                context,
                                conflict,
                                'keep_local',
                              ),
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Garder local'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getEntityLabel(String type) {
    return switch (type) {
      'products' => 'Produit',
      'partners' => 'Partenaire',
      'documents' => 'Document',
      'warehouses' => 'Dépôt',
      'categories' => 'Catégorie',
      _ => type.toUpperCase(),
    };
  }

  Color _getReasonColor(SyncConflictReason reason) {
    switch (reason) {
      case SyncConflictReason.versionMismatch:
        return Colors.orange;
      case SyncConflictReason.localPendingRemoteChanged:
        return Colors.deepOrange;
      default:
        return Colors.blue;
    }
  }

  IconData _getReasonIcon(SyncConflictReason reason) {
    switch (reason) {
      case SyncConflictReason.versionMismatch:
        return Icons.history;
      case SyncConflictReason.localPendingRemoteChanged:
        return Icons.warning_amber_rounded;
      default:
        return Icons.sync_problem;
    }
  }
}

class _PayloadSection extends StatelessWidget {
  const _PayloadSection({
    required this.title,
    required this.json,
    required this.entityType,
  });

  final String title;
  final String? json;
  final String entityType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: _buildSummary(context),
        ),
      ],
    );
  }

  Widget _buildSummary(BuildContext context) {
    if (json == null) return const Text('Aucune donnée');

    try {
      final data = jsonDecode(json!) as Map<String, dynamic>;

      switch (entityType) {
        case 'products':
          return _buildFieldList([
            _Field('Nom', data['name']),
            _Field('SKU', data['sku']),
            _Field('Prix HT', '${data['sale_price_ht']} DT'),
            _Field('Stock Min', data['stock_minimum']?.toString()),
            _Field('Catégorie', data['category_name']),
            _Field('Actif', data['is_active'] == true ? 'Oui' : 'Non'),
          ]);
        case 'partners':
          return _buildFieldList([
            _Field('Nom', data['name']),
            _Field('Téléphone', data['phone']),
            _Field('Email', data['email']),
            _Field('Type', data['type']),
          ]);
        case 'documents':
          return _buildFieldList([
            _Field('Numéro', data['document_number']),
            _Field('Type', data['type']),
            _Field('Statut', data['status']),
            _Field('Total TTC', '${data['total_ttc']} DT'),
          ]);
        default:
          return SelectableText(
            json!,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
          );
      }
    } catch (e) {
      return SelectableText(
        json!,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
      );
    }
  }

  Widget _buildFieldList(List<_Field> fields) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .where((f) => f.value != null)
          .map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${f.label} :',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      f.value!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Field {
  _Field(this.label, Object? val) : value = val?.toString();
  final String label;
  final String? value;
}
