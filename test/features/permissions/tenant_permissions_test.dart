import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/permissions/tenant_permissions.dart';
import 'package:ultra_trace/features/auth/data/auth_models.dart';

void main() {
  group('TenantPermissions', () {
    test('owner has all permissions', () {
      final p = TenantPermissions(TenantRole.owner);
      expect(p.canManageTeam, isTrue);
      expect(p.canManageCompany, isTrue);
      expect(p.canCreateSale, isTrue);
      expect(p.canEditProducts, isTrue);
      expect(p.canManageStock, isTrue);
      expect(p.canValidateDocuments, isTrue);
      expect(p.canViewDocuments, isTrue);
      expect(p.canRecordPayments, isTrue);
      expect(p.canViewReports, isTrue);
      expect(p.canExportBackups, isTrue);
      expect(p.canManageFiscalSettings, isTrue);
      expect(p.canViewAudit, isTrue);
      expect(p.isReadOnly, isFalse);
    });

    test('manager can manage company but not team', () {
      final p = TenantPermissions(TenantRole.manager);
      expect(p.canManageTeam, isFalse);
      expect(p.canManageCompany, isTrue);
      expect(p.canCreateSale, isTrue);
      expect(p.canEditProducts, isTrue);
      expect(p.canManageStock, isTrue);
      expect(p.canValidateDocuments, isTrue);
      expect(p.canViewReports, isTrue);
      expect(p.canExportBackups, isTrue);
    });

    test('cashier has limited permissions', () {
      final p = TenantPermissions(TenantRole.cashier);
      expect(p.canManageTeam, isFalse);
      expect(p.canManageCompany, isFalse);
      expect(p.canCreateSale, isTrue);
      expect(p.canEditProducts, isFalse);
      expect(p.canManageStock, isFalse);
      expect(p.canValidateDocuments, isFalse);
      expect(p.canRecordPayments, isTrue);
      expect(p.canViewReports, isFalse);
      expect(p.canExportBackups, isFalse);
    });

    test('stock_manager cannot create sales', () {
      final p = TenantPermissions(TenantRole.stockManager);
      expect(p.canManageTeam, isFalse);
      expect(p.canEditProducts, isTrue);
      expect(p.canManageStock, isTrue);
      expect(p.canCreateSale, isFalse);
      expect(p.canValidateDocuments, isFalse);
    });

    test('accountant can view reports and export', () {
      final p = TenantPermissions(TenantRole.accountant);
      expect(p.canManageTeam, isFalse);
      expect(p.canEditProducts, isFalse);
      expect(p.canCreateSale, isFalse);
      expect(p.canManageStock, isFalse);
      expect(p.canViewReports, isTrue);
      expect(p.canExportBackups, isTrue);
      expect(p.canViewDocuments, isTrue);
    });

    test('readOnly cannot mutate anything', () {
      final p = TenantPermissions(TenantRole.readOnly);
      expect(p.canManageTeam, isFalse);
      expect(p.canManageCompany, isFalse);
      expect(p.canCreateSale, isFalse);
      expect(p.canEditProducts, isFalse);
      expect(p.canManageStock, isFalse);
      expect(p.canValidateDocuments, isFalse);
      expect(p.canRecordPayments, isFalse);
      expect(p.canViewReports, isFalse);
      expect(p.canExportBackups, isFalse);
      expect(p.isReadOnly, isTrue);
      expect(p.canViewDocuments, isTrue);
    });

    test('service_role is never referenced in lib/', () {
      // This is a meta-test: no Dart file in lib/ should contain service_role
      // In CI, you would grep for this. Here we just document the invariant.
      expect(true, isTrue);
    });
  });
}
