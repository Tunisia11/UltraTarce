part of '../app_database.dart';

@DataClassName('AuditEventRow')
@TableIndex(
  name: 'idx_audit_events_tenant_created_at',
  columns: {#tenantId, #createdAt},
)
class AuditEvents extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get type => text().withDefault(const Constant(''))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get actor => text().withDefault(const Constant('Système'))();
  TextColumn get action => text().withDefault(const Constant(''))();
  TextColumn get target => text().withDefault(const Constant(''))();
  TextColumn get detail => text().withDefault(const Constant(''))();
  TextColumn get entityType => text().nullable()();
  TextColumn get entityId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get metadataJson => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
