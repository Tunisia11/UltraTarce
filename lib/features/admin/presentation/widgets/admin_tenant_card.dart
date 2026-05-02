import 'package:flutter/material.dart';
import '../../../../app/app_colors.dart';
import '../../data/admin_models.dart';

class AdminTenantCard extends StatelessWidget {
  const AdminTenantCard({super.key, required this.tenant, required this.onTap});

  final AdminTenantOverview tenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasErrors = tenant.syncErrorCount > 0;

    return Card(
      elevation: 0,
      color: AppColors.surfaceLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceHigh,
                child: Text(
                  tenant.tenantName.isNotEmpty
                      ? tenant.tenantName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant.tenantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tenant.ownerEmail ?? 'Aucun propriétaire',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      Icons.people,
                      tenant.userCount.toString(),
                      'Utilisateurs',
                    ),
                    _buildStat(
                      Icons.inventory_2,
                      tenant.productCount.toString(),
                      'Produits',
                    ),
                    _buildStat(
                      Icons.description,
                      tenant.documentCount.toString(),
                      'Documents',
                    ),
                    if (hasErrors)
                      _buildStat(
                        Icons.sync_problem,
                        tenant.syncErrorCount.toString(),
                        'Erreurs',
                        color: AppColors.danger,
                      )
                    else
                      _buildStat(
                        Icons.check_circle,
                        '0',
                        'Erreurs',
                        color: AppColors.emerald,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tenant.status == 'active'
                          ? AppColors.emerald.withValues(alpha: .1)
                          : AppColors.danger.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tenant.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: tenant.status == 'active'
                            ? AppColors.emerald
                            : AppColors.danger,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tenant.lastActivityDate != null
                        ? tenant.lastActivityDate!
                              .toLocal()
                              .toString()
                              .substring(0, 16)
                        : 'Jamais',
                    style: const TextStyle(
                      color: AppColors.subtle,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String value,
    String tooltip, {
    Color color = AppColors.muted,
  }) {
    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
