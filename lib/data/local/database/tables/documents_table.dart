part of '../app_database.dart';

@DataClassName('DocumentRow')
@TableIndex(
  name: 'idx_documents_tenant_type_status_issue_date',
  columns: {#tenantId, #type, #status, #issueDate},
)
@TableIndex(name: 'idx_documents_tenant_number', columns: {#tenantId, #number})
class Documents extends Table {
  TextColumn get id => text()();
  TextColumn get tenantId =>
      text().withDefault(const Constant('local_legacy_tenant'))();
  TextColumn get type => text()();
  TextColumn get status => text()();
  TextColumn get number => text()();
  IntColumn get sequence => integer().withDefault(const Constant(0))();
  TextColumn get partnerId => text().withDefault(const Constant(''))();
  TextColumn get partnerName => text().withDefault(const Constant(''))();
  TextColumn get partnerTaxId => text().withDefault(const Constant(''))();
  TextColumn get partnerAddress => text().withDefault(const Constant(''))();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get warehouseId => text().withDefault(const Constant(''))();
  TextColumn get sourceDocumentId => text().nullable()();
  TextColumn get sourceNumber => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get stockApplied => boolean().withDefault(const Constant(false))();
  BoolColumn get applyTimbreFiscal =>
      boolean().withDefault(const Constant(false))();
  RealColumn get subtotalHt => real().withDefault(const Constant(0))();
  RealColumn get totalDiscount => real().withDefault(const Constant(0))();
  RealColumn get totalTva => real().withDefault(const Constant(0))();
  RealColumn get timbreFiscal => real().withDefault(const Constant(0))();
  RealColumn get totalTtc => real().withDefault(const Constant(0))();
  RealColumn get paidAmount => real().withDefault(const Constant(0))();
  RealColumn get remainingAmount => real().withDefault(const Constant(0))();
  TextColumn get companySnapshotJson => text().nullable()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
