import '../auth/data/auth_models.dart';

/// Defines all permission scopes available in the tenant workspace.
/// Each permission maps to a set of roles that are allowed to use it.
class TenantPermissions {
  TenantPermissions(this.role);

  final TenantRole role;

  // ── Team & company ──
  bool get canManageTeam => role == TenantRole.owner;

  bool get canViewTeam =>
      role == TenantRole.owner || role == TenantRole.manager;

  bool get canManageCompany =>
      role == TenantRole.owner || role == TenantRole.manager;

  // ── Products ──
  bool get canEditProducts =>
      role == TenantRole.owner ||
      role == TenantRole.manager ||
      role == TenantRole.stockManager;

  // ── Sales ──
  bool get canCreateSale =>
      role == TenantRole.owner ||
      role == TenantRole.manager ||
      role == TenantRole.cashier;

  // ── Stock ──
  bool get canManageStock =>
      role == TenantRole.owner ||
      role == TenantRole.manager ||
      role == TenantRole.stockManager;

  // ── Documents ──
  bool get canValidateDocuments =>
      role == TenantRole.owner || role == TenantRole.manager;

  bool get canViewDocuments => true; // all roles can view

  // ── Payments ──
  bool get canRecordPayments =>
      role == TenantRole.owner ||
      role == TenantRole.manager ||
      role == TenantRole.cashier;

  // ── Reports ──
  bool get canViewReports =>
      role == TenantRole.owner ||
      role == TenantRole.manager ||
      role == TenantRole.accountant;

  // ── Backup/export ──
  bool get canExportBackups =>
      role == TenantRole.owner ||
      role == TenantRole.manager ||
      role == TenantRole.accountant;

  // ── Fiscal/tax settings ──
  bool get canManageFiscalSettings =>
      role == TenantRole.owner || role == TenantRole.manager;

  // ── Audit ──
  bool get canViewAudit =>
      role == TenantRole.owner || role == TenantRole.manager;

  /// True when the role should not be able to mutate any business data.
  bool get isReadOnly => role == TenantRole.readOnly;

  /// Human-readable label for the permission level.
  String get summaryLabel {
    if (canManageTeam) return 'Accès complet';
    if (canManageCompany) return 'Gestion avancée';
    if (canCreateSale) return 'Ventes & clients';
    if (canManageStock) return 'Gestion stock';
    if (canViewReports) return 'Consultation';
    return 'Lecture seule';
  }
}
