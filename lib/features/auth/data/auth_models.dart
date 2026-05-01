enum TenantRole { owner, manager, cashier, stockManager, accountant, readOnly }

extension TenantRoleDetails on TenantRole {
  String get value {
    switch (this) {
      case TenantRole.owner:
        return 'owner';
      case TenantRole.manager:
        return 'manager';
      case TenantRole.cashier:
        return 'cashier';
      case TenantRole.stockManager:
        return 'stock_manager';
      case TenantRole.accountant:
        return 'accountant';
      case TenantRole.readOnly:
        return 'read_only';
    }
  }

  String get label {
    switch (this) {
      case TenantRole.owner:
        return 'Propriétaire';
      case TenantRole.manager:
        return 'Manager';
      case TenantRole.cashier:
        return 'Caissier';
      case TenantRole.stockManager:
        return 'Responsable stock';
      case TenantRole.accountant:
        return 'Comptable';
      case TenantRole.readOnly:
        return 'Lecture seule';
    }
  }
}

TenantRole tenantRoleFromValue(Object? value) {
  final normalized = '$value'.trim();
  for (final role in TenantRole.values) {
    if (role.value == normalized) return role;
  }
  return TenantRole.readOnly;
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.isDevBypass = false,
  });

  final String id;
  final String email;
  final String displayName;
  final bool isDevBypass;
}

class TenantMembership {
  const TenantMembership({
    required this.tenantId,
    required this.tenantName,
    required this.role,
    this.legalName = '',
    this.status = 'active',
  });

  final String tenantId;
  final String tenantName;
  final TenantRole role;
  final String legalName;
  final String status;
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
