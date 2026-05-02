import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/app_colors.dart';
import '../data/admin_models.dart';
import '../application/admin_dashboard_cubit.dart';

class AdminSyncHealthPage extends StatelessWidget {
  const AdminSyncHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AdminDashboardCubit>().repository;

    return FutureBuilder<AdminSyncHealth>(
      future: repository.loadSyncHealth(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erreur : ${snapshot.error}',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }

        final health = snapshot.data;
        if (health == null) {
          return const Center(child: Text('Aucune donnée de synchronisation.'));
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Santé Sync',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Erreurs par code'),
            _buildErrorsByCode(health),
            const SizedBox(height: 24),
            _buildSectionTitle('Erreurs par société (Top 10)'),
            _buildErrorsByTenant(health),
            const SizedBox(height: 24),
            _buildSectionTitle('Dernières erreurs (50)'),
            _buildLatestErrorsList(health.latestErrors),
            const SizedBox(height: 24),
            _buildSectionTitle('Derniers conflits (50)'),
            _buildLatestConflictsList(health.latestConflicts),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _buildErrorsByCode(AdminSyncHealth health) {
    if (health.errorsByCode.isEmpty) return const Text('Aucune erreur.');
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: health.errorsByCode.entries.map((e) {
        return Card(
          elevation: 0,
          color: AppColors.surfaceLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${e.value} occurrences',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorsByTenant(AdminSyncHealth health) {
    if (health.errorsByTenant.isEmpty) return const Text('Aucune erreur.');

    final sortedTenants = health.errorsByTenant.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final topTenants = sortedTenants.take(10).toList();

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: topTenants.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final tenantId = topTenants[index].key;
          final errors = topTenants[index].value;
          final tenantName =
              (errors.first['tenants'] as Map<String, dynamic>?)?['name']
                  as String? ??
              tenantId;

          return ListTile(
            leading: const Icon(Icons.business, color: AppColors.muted),
            title: Text(tenantName),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${errors.length} erreurs',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLatestErrorsList(List<Map<String, dynamic>> errors) {
    if (errors.isEmpty) return const Text('Aucune erreur récente.');
    return _buildListFromRows(errors, isConflict: false);
  }

  Widget _buildLatestConflictsList(List<Map<String, dynamic>> conflicts) {
    if (conflicts.isEmpty) return const Text('Aucun conflit récent.');
    return _buildListFromRows(conflicts, isConflict: true);
  }

  Widget _buildListFromRows(
    List<Map<String, dynamic>> rows, {
    required bool isConflict,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final r = rows[index];
          final tenantName =
              (r['tenants'] as Map<String, dynamic>?)?['name'] as String? ??
              'Inconnu';
          final entityType = r['entity_type'] as String? ?? 'Inconnu';
          final code = isConflict
              ? 'CONFLIT'
              : (r['error_code'] as String? ?? 'Inconnu');
          final msg = isConflict
              ? 'Conflit de version / ID'
              : (r['error_message'] as String? ?? '');

          return ListTile(
            leading: Icon(
              isConflict ? Icons.warning : Icons.error,
              color: isConflict ? AppColors.warning : AppColors.danger,
            ),
            title: Text('$entityType ($tenantName)'),
            subtitle: Text('$code - $msg'),
            trailing: Text(
              r['created_at'] != null
                  ? DateTime.parse(
                      r['created_at'] as String,
                    ).toLocal().toString().substring(0, 16)
                  : '',
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }
}
