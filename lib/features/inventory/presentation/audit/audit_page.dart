part of '../inventory_shell_page.dart';

extension _InventoryAuditPage on _InventoryHomePageState {
  Widget _buildAudit() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Historique',
          subtitle:
              'Actions importantes gardées localement: ventes, stock, réglages et restaurations.',
        ),
        Panel(
          title: 'Activité récente',
          trailing: SmallChip(label: '${_auditEvents.length} événement(s)'),
          child: _auditEvents.isEmpty
              ? const EmptyState(
                  text: 'Aucune action importante enregistrée pour le moment.',
                  icon: Icons.history_outlined,
                )
              : Column(
                  children: [
                    for (final event in _auditEvents.take(80))
                      _buildAuditEventCard(event),
                    if (_auditEvents.length > 80) ...[
                      const SizedBox(height: 8),
                      const EmptyState(
                        text:
                            'Historique long: les événements plus anciens restent conservés localement.',
                        icon: Icons.more_horiz,
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAuditEventCard(AuditEvent event) {
    final color = _auditEventColor(event);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: .16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_auditEventIcon(event), color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _auditEventTitle(event),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    SmallChip(label: event.action, color: color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.detail,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatDate(event.date)} à ${formatTime(event.date)} · ${event.actor}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _auditEventTitle(AuditEvent event) {
    final target = event.target.trim();
    return target.isEmpty ? event.action : target;
  }

  IconData _auditEventIcon(AuditEvent event) {
    final action = event.action.toLowerCase();
    if (action.contains('validation')) return Icons.check_circle_outline;
    if (action.contains('paiement')) return Icons.payments_outlined;
    if (action.contains('stock') || action.contains('réception')) {
      return Icons.inventory_2_outlined;
    }
    if (action.contains('restauration') || action.contains('sauvegarde')) {
      return Icons.restore_outlined;
    }
    if (action.contains('configuration')) return Icons.settings_outlined;
    if (action.contains('annulation')) return Icons.cancel_outlined;
    return Icons.history_outlined;
  }

  Color _auditEventColor(AuditEvent event) {
    final action = event.action.toLowerCase();
    if (action.contains('annulation')) return AppColors.danger;
    if (action.contains('stock') || action.contains('réception')) {
      return AppColors.cyan;
    }
    if (action.contains('configuration') || action.contains('restauration')) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}
