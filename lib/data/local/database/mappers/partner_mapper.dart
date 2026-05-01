import 'package:drift/drift.dart';

import '../../../../app/tenant_context.dart';
import '../../../../domain/app_enums.dart';
import '../../../../domain/app_models.dart';
import '../app_database.dart';
import '../tenant_row_scope.dart';

class PartnerMapper {
  static PartnersCompanion toCompanion(
    Partner partner, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    final now = DateTime.now();
    return PartnersCompanion(
      id: Value(TenantRowScope.rowId(tenantId, partner.id)),
      tenantId: Value(tenantId),
      type: Value(partner.type.name),
      name: Value(partner.name),
      phone: Value(partner.phone),
      email: Value(partner.email),
      taxId: Value(partner.taxId),
      address: Value(partner.address),
      customerType: Value(partner.customerType.name),
      companyName: Value(partner.companyName),
      contactName: Value(partner.contactName),
      city: Value(partner.city),
      notes: Value(partner.notes),
      isActive: Value(partner.active),
      updatedAt: Value(now),
      deletedAt: Value(partner.active ? null : now),
    );
  }

  static Partner fromRow(
    PartnerRow row, {
    String tenantId = TenantContext.legacyTenantId,
  }) {
    return Partner(
      id: TenantRowScope.domainId(tenantId, row.id),
      type: enumFromName(PartnerType.values, row.type, PartnerType.client),
      name: row.name,
      taxId: row.taxId,
      address: row.address,
      phone: row.phone,
      email: row.email,
      customerType: enumFromName(
        CustomerType.values,
        row.customerType,
        CustomerType.entreprise,
      ),
      companyName: row.companyName,
      contactName: row.contactName,
      city: row.city,
      notes: row.notes,
      active: row.isActive,
    );
  }
}
