import 'package:flutter/material.dart';

class AdminSubscriptionStatusBadge extends StatelessWidget {
  const AdminSubscriptionStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'trial':
        color = Colors.blue;
        label = 'Essai';
        break;
      case 'active':
        color = Colors.green;
        label = 'Actif';
        break;
      case 'overdue':
        color = Colors.orange;
        label = 'En retard';
        break;
      case 'suspended':
        color = Colors.red;
        label = 'Suspendu';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Annulé';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
