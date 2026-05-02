import 'package:flutter/material.dart';
import '../../data/admin_subscription_models.dart';
import 'admin_subscription_status_badge.dart';

class AdminSubscriptionCard extends StatelessWidget {
  const AdminSubscriptionCard({
    super.key,
    required this.subscription,
    required this.onEdit,
  });

  final AdminTenantSubscription subscription;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    subscription.tenantName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                AdminSubscriptionStatusBadge(status: subscription.status),
              ],
            ),
            const SizedBox(height: 8),
            if (subscription.ownerEmail != null)
              Text(
                'Propriétaire: ${subscription.ownerEmail}',
                style: const TextStyle(color: Colors.grey),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol('Plan', subscription.plan.toUpperCase()),
                _buildInfoCol('Cycle', subscription.billingCycle),
                _buildInfoCol(
                  'Prix',
                  subscription.priceTnd != null
                      ? '${subscription.priceTnd} TND'
                      : '-',
                ),
                _buildInfoCol(
                  'Utilisateurs',
                  '${subscription.userCount} / ${subscription.seatsLimit ?? "∞"}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Modifier'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
