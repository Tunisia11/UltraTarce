import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/app_colors.dart';
import '../application/admin_dashboard_cubit.dart';
import '../application/admin_dashboard_state.dart';
import 'widgets/admin_tenant_card.dart';
import 'admin_tenant_detail_page.dart';

class AdminTenantsPage extends StatefulWidget {
  const AdminTenantsPage({super.key});

  @override
  State<AdminTenantsPage> createState() => _AdminTenantsPageState();
}

class _AdminTenantsPageState extends State<AdminTenantsPage> {
  String _searchQuery = '';
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoading || state is AdminDashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AdminDashboardLoaded) {
          final tenants = state.tenants.where((t) {
            final matchesSearch =
                t.tenantName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (t.ownerEmail != null &&
                    t.ownerEmail!.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ));
            final matchesStatus =
                _filterStatus == 'all' || t.status == _filterStatus;
            return matchesSearch && matchesStatus;
          }).toList();

          // Sort by last activity descending by default
          tenants.sort(
            (a, b) => (b.lastActivityDate ?? DateTime(2000)).compareTo(
              a.lastActivityDate ?? DateTime(2000),
            ),
          );

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clients / Sociétés',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Rechercher par nom ou email...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _filterStatus,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'all',
                            child: Text('Tous les statuts'),
                          ),
                          DropdownMenuItem(
                            value: 'active',
                            child: Text('Actifs'),
                          ),
                          DropdownMenuItem(
                            value: 'disabled',
                            child: Text('Désactivés'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _filterStatus = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: tenants.isEmpty
                      ? const Center(child: Text('Aucune société trouvée.'))
                      : ListView.builder(
                          itemCount: tenants.length,
                          itemBuilder: (context, index) {
                            return AdminTenantCard(
                              tenant: tenants[index],
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AdminTenantDetailPage(
                                      tenantId: tenants[index].tenantId,
                                      tenantName: tenants[index].tenantName,
                                      repository: context
                                          .read<AdminDashboardCubit>()
                                          .repository, // wait, repository is private in Cubit.
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        }

        return const SizedBox();
      },
    );
  }
}
