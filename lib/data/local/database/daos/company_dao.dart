part of '../app_database.dart';

@DriftAccessor(tables: [Companies])
class CompanyDao extends DatabaseAccessor<AppDatabase> with _$CompanyDaoMixin {
  CompanyDao(super.db);

  Future<CompanyRow?> getCompany({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(companies)
          ..where((table) => table.tenantId.equals(tenantId))
          ..limit(1))
        .getSingleOrNull();
  }

  Stream<CompanyRow?> watchCompany({
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return (select(companies)
          ..where((table) => table.tenantId.equals(tenantId))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> upsertCompany(CompaniesCompanion company) {
    return into(companies).insertOnConflictUpdate(company);
  }
}
