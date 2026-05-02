import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_colors.dart';
import '../application/admin_dashboard_cubit.dart';
import '../application/admin_dashboard_state.dart';
import 'widgets/admin_stat_card.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading || state is AdminDashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminDashboardError) {
          return Center(
            child: Text(
              'Erreur: ${state.message}',
              style: const TextStyle(color: AppColors.danger),
            ),
          );
        }

        if (state is AdminDashboardLoaded) {
          final overview = state.overview;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Vue générale',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 800
                      ? 4
                      : (constraints.maxWidth > 500 ? 2 : 1);
                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.5,
                    children: [
                      AdminStatCard(
                        title: 'Sociétés actives',
                        value:
                            '${overview.activeTenants} / ${overview.totalTenants}',
                        icon: Icons.business,
                        color: AppColors.primaryContainer,
                      ),
                      AdminStatCard(
                        title: 'En essai',
                        value: overview.trialTenants.toString(),
                        icon: Icons.access_time,
                        color: Colors.blue,
                      ),
                      AdminStatCard(
                        title: 'En retard',
                        value: overview.overdueTenants.toString(),
                        icon: Icons.payment,
                        color: Colors.orange,
                      ),
                      AdminStatCard(
                        title: 'Suspendues',
                        value: overview.suspendedTenants.toString(),
                        icon: Icons.block,
                        color: Colors.red,
                      ),
                      AdminStatCard(
                        title: 'Annulées',
                        value: overview.cancelledTenants.toString(),
                        icon: Icons.cancel,
                        color: Colors.grey,
                      ),
                      AdminStatCard(
                        title: 'Utilisateurs',
                        value: overview.totalUsers.toString(),
                        icon: Icons.people,
                        color: AppColors.cyan,
                      ),
                      AdminStatCard(
                        title: 'Produits',
                        value: overview.totalProducts.toString(),
                        icon: Icons.inventory_2,
                        color: AppColors.emerald,
                      ),
                      AdminStatCard(
                        title: 'Documents',
                        value: overview.totalDocuments.toString(),
                        icon: Icons.description,
                        color: AppColors.primaryContainer,
                      ),
                      AdminStatCard(
                        title: 'Erreurs sync',
                        value: overview.totalSyncErrors.toString(),
                        icon: Icons.sync_problem,
                        color: overview.totalSyncErrors > 0
                            ? AppColors.danger
                            : AppColors.muted,
                      ),
                      AdminStatCard(
                        title: 'Conflits sync',
                        value: overview.totalSyncConflicts.toString(),
                        icon: Icons.warning,
                        color: overview.totalSyncConflicts > 0
                            ? AppColors.warning
                            : AppColors.muted,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Dernière activité',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.history, color: AppColors.muted),
                title: const Text('Dernier document créé ou mis à jour'),
                subtitle: Text(
                  overview.latestActivityTime?.toLocal().toString() ??
                      'Aucune activité',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.error_outline,
                  color: AppColors.danger,
                ),
                title: const Text('Dernière erreur de synchronisation'),
                subtitle: Text(
                  overview.latestSyncErrorTime?.toLocal().toString() ??
                      'Aucune erreur récente',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }
}
