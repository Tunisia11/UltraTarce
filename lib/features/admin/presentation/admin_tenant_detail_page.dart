import 'package:flutter/material.dart';
import '../../../app/app_colors.dart';
import '../data/admin_models.dart';
import '../data/admin_repository.dart';

class AdminTenantDetailPage extends StatelessWidget {
  const AdminTenantDetailPage({
    super.key,
    required this.tenantId,
    required this.tenantName,
    required this.repository,
  });

  final String tenantId;
  final String tenantName;
  final AdminRepository repository;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceHighest,
        title: Text('Détails : $tenantName'),
      ),
      body: FutureBuilder<AdminTenantDetail>(
        future: repository.loadTenantDetail(tenantId),
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

          final detail = snapshot.data;
          if (detail == null) {
            return const Center(child: Text('Aucune donnée.'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildSectionTitle('Informations'),
              _buildInfoCard(detail),
              const SizedBox(height: 24),
              _buildSectionTitle('Abonnement'),
              _buildSubscriptionCard(detail),
              const SizedBox(height: 24),
              _buildSectionTitle('Statistiques'),
              _buildStatsGrid(detail),
              const SizedBox(height: 24),
              _buildSectionTitle('Utilisateurs (${detail.users.length})'),
              _buildUsersList(detail),
              const SizedBox(height: 24),
              _buildSectionTitle('Erreurs de synchronisation récentes'),
              _buildRecentErrors(detail),
              const SizedBox(height: 24),
              _buildSectionTitle('Documents récents'),
              _buildRecentDocuments(detail),
            ],
          );
        },
      ),
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

  Widget _buildInfoCard(AdminTenantDetail detail) {
    final t = detail.tenantInfo;
    final c = detail.companyInfo;

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
          children: [
            ListTile(
              title: const Text('ID Société'),
              subtitle: Text(t['id'] as String? ?? ''),
            ),
            ListTile(
              title: const Text('Nom de la société (Profil)'),
              subtitle: Text(c['name'] as String? ?? 'Non renseigné'),
            ),
            ListTile(
              title: const Text('Statut'),
              subtitle: Text(t['status'] as String? ?? ''),
            ),
            ListTile(
              title: const Text('Date de création'),
              subtitle: Text(
                t['created_at'] != null
                    ? DateTime.parse(
                        t['created_at'] as String,
                      ).toLocal().toString().substring(0, 16)
                    : '',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(AdminTenantDetail detail) {
    final sub = detail.subscriptionInfo;
    if (sub == null) {
      return const Text('Aucun abonnement configuré (Mode Pilot par défaut).');
    }

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
          children: [
            ListTile(
              title: const Text('Statut / Plan'),
              subtitle: Text(
                '${(sub['status'] as String?)?.toUpperCase() ?? ''} - ${(sub['plan'] as String?)?.toUpperCase() ?? ''}',
              ),
              trailing: const Text(
                'Allez dans l\'onglet Abonnements pour modifier',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
            ListTile(
              title: const Text('Cycle de facturation'),
              subtitle: Text(sub['billing_cycle'] as String? ?? ''),
            ),
            if (sub['current_period_ends_at'] != null)
              ListTile(
                title: const Text('Fin de période'),
                subtitle: Text(
                  DateTime.parse(
                    sub['current_period_ends_at'] as String,
                  ).toLocal().toString().substring(0, 10),
                ),
              ),
            if (sub['admin_notes'] != null)
              ListTile(
                title: const Text('Notes internes'),
                subtitle: Text(sub['admin_notes'] as String),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AdminTenantDetail detail) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      children: detail.counts.entries.map((e) {
        return Card(
          color: AppColors.surfaceHighest,
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  e.key.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  e.value.toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUsersList(AdminTenantDetail detail) {
    if (detail.users.isEmpty) return const Text('Aucun utilisateur.');
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
        itemCount: detail.users.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final u = detail.users[index];
          final profile = u['profiles'] as Map<String, dynamic>?;
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(profile?['email'] as String? ?? 'Email non disponible'),
            subtitle: Text('Rôle: ${u['role']}'),
          );
        },
      ),
    );
  }

  Widget _buildRecentErrors(AdminTenantDetail detail) {
    if (detail.recentErrors.isEmpty) {
      return const Text('Aucune erreur récente.');
    }
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
        itemCount: detail.recentErrors.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final e = detail.recentErrors[index];
          return ListTile(
            leading: const Icon(Icons.error, color: AppColors.danger),
            title: Text(e['entity_type'] as String? ?? 'Entité inconnue'),
            subtitle: Text('${e['error_code']} - ${e['error_message']}'),
            trailing: Text(
              e['created_at'] != null
                  ? DateTime.parse(
                      e['created_at'] as String,
                    ).toLocal().toString().substring(0, 16)
                  : '',
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentDocuments(AdminTenantDetail detail) {
    if (detail.recentDocuments.isEmpty) {
      return const Text('Aucun document récent.');
    }
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
        itemCount: detail.recentDocuments.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final d = detail.recentDocuments[index];
          return ListTile(
            leading: const Icon(
              Icons.description,
              color: AppColors.primaryContainer,
            ),
            title: Text('${d['type']} ${d['reference']}'),
            subtitle: Text('Statut: ${d['status']}'),
            trailing: Text(
              d['created_at'] != null
                  ? DateTime.parse(
                      d['created_at'] as String,
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
