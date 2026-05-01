import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';

class CompanyMapper {
  static const id = 'default';

  static CompaniesCompanion toCompanion(
    CompanyProfile company, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    return CompaniesCompanion(
      id: Value(tenantId),
      tenantId: Value(tenantId),
      name: Value(company.name),
      taxId: Value(company.taxId),
      address: Value(company.address),
      city: Value(company.city),
      phone: Value(company.phone),
      email: Value(company.email),
      logoSource: Value(company.logoSource),
      logoPath: Value(company.logoSource.isEmpty ? null : company.logoSource),
      invoiceFooter: Value(company.invoiceFooter),
      legalInfo: Value(company.legalInfo),
      timbreFiscalEnabled: Value(company.timbreFiscalEnabled),
      timbreFiscalAmount: Value(company.timbreFiscalAmount),
      updatedAt: Value(now),
    );
  }

  static CompanyProfile fromRow(CompanyRow row) {
    return CompanyProfile(
      name: row.name,
      taxId: row.taxId,
      address: row.address,
      city: row.city,
      phone: row.phone,
      email: row.email,
      logoSource: row.logoSource,
      invoiceFooter: row.invoiceFooter,
      legalInfo: row.legalInfo,
      timbreFiscalEnabled: row.timbreFiscalEnabled,
      timbreFiscalAmount: row.timbreFiscalAmount,
    );
  }
}
