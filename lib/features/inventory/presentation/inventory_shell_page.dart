import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:url_launcher/url_launcher.dart';

import '../../../app/app_assets.dart';
import '../../../app/app_colors.dart';
import '../../../app/app_config.dart';
import '../../../app/tenant_context.dart';
import '../../../core/formatters.dart';
import '../../../core/iterable_extensions.dart';
import '../../../document_export.dart';
import '../../../data/local/app_snapshot_local_data_source.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/database/drift_snapshot_store.dart';
import '../../../data/local/migration/app_snapshot_to_drift_migration.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/backup_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/client_repository.dart';
import '../../../data/repositories/company_repository.dart';
import '../../../data/repositories/document_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../data/repositories/warehouse_repository.dart';
import '../../../data/remote/supabase_client_provider.dart';
import '../../../data/sync/connectivity_service.dart';
import '../../../data/sync/device_identity_service.dart';
import '../../../data/sync/sync_outbox_repository.dart';
import '../../../data/sync/sync_outbox_service.dart';
import '../../../data/sync/sync_pilot_messages.dart';
import '../../../data/sync/sync_push_service.dart';
import '../../../data/sync/sync_remote_writer.dart';
import '../../../data/sync/sync_status.dart';
import '../../../data/sync/sync_status_cubit.dart';
import '../../../domain/app_enums.dart';
import '../../../domain/app_models.dart';
import '../../../domain/services/document_lifecycle_service.dart';
import '../../../domain/services/invoice_accounting_service.dart';
import '../../../domain/services/metrics_service.dart';
import '../../../domain/services/payment_service.dart';
import '../../../domain/services/pricing_service.dart';
import '../../../domain/services/return_service.dart';
import '../../../domain/services/sequence_service.dart';
import '../../../domain/services/stock_integrity_service.dart';
import '../../../domain/services/stock_mutation_service.dart';
import '../../../domain/services/stock_service.dart';
import '../../../domain/services/tax_service.dart';
import '../../../logo_image.dart';
import '../../../logo_picker.dart';
import '../../../storage/app_snapshot_codec.dart';
import '../../../storage/app_storage.dart';
import '../application/backup_cubit.dart';
import '../application/category_cubit.dart';
import '../application/clients_cubit.dart';
import '../application/company_cubit.dart';
import '../application/dashboard_cubit.dart';
import '../application/documents_cubit.dart';
import '../application/inventory_cubit.dart';
import '../application/inventory_state.dart';
import '../application/onboarding_cubit.dart';
import '../application/products_cubit.dart';
import '../application/sales_cubit.dart';
import '../application/stock_cubit.dart';
import '../application/suppliers_cubit.dart';
import '../application/warehouse_cubit.dart';
import '../widgets/document_link_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/guided_focus_overlay.dart';
import '../widgets/inline_notice.dart';
import '../widgets/line_quantity_stepper.dart';
import '../widgets/list_row.dart';
import '../widgets/metric_card.dart';
import '../widgets/panel.dart';
import '../widgets/preview_info.dart';
import '../widgets/preview_lines.dart';
import '../widgets/preview_total_row.dart';
import '../widgets/price_insight.dart';
import '../widgets/product_image.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/small_chip.dart';
import '../widgets/square_icon_button.dart';
import '../widgets/step_pill.dart';
import '../widgets/total_item.dart';

part 'navigation/app_side_menu.dart';
part 'navigation/app_navigation_bar.dart';
part 'dashboard/dashboard_page.dart';
part 'sales/sales_page.dart';
part 'products/product_form_page.dart';
part 'products/products_page.dart';
part 'products/widgets/product_catalogue_card.dart';
part 'clients/client_form_page.dart';
part 'clients/clients_page.dart';
part 'suppliers/suppliers_page.dart';
part 'documents/documents_page.dart';
part 'documents/document_detail_page.dart';
part 'documents/widgets/document_export_actions.dart';
part 'stock/stock_page.dart';
part 'company/company_page.dart';
part 'company/widgets/tax_settings_panel.dart';
part 'backup/backup_restore_page.dart';
part 'reports/reports_page.dart';
part 'audit/audit_page.dart';
part 'purchases/purchases_page.dart';
part 'onboarding/guided_focus_overlay.dart';
part 'onboarding/tarek_guidance_card.dart';
part 'widgets/form_controls.dart';
part 'suppliers/supplier_form_page.dart';
part 'workflows/inventory_workflows.dart';
part 'inventory_shell_view.dart';

class InventoryShellPage extends StatefulWidget {
  const InventoryShellPage({super.key, this.config});

  final AppConfig? config;

  @override
  State<InventoryShellPage> createState() => _InventoryHomePageState();
}

class _InventoryHomePageState extends State<InventoryShellPage> {
  static const int _maxLogoBytes = AppSnapshotCodec.maxLogoBytes;

  late CompanyProfile _company;

  late List<Warehouse> _warehouses;
  late List<Category> _categories;
  late List<Product> _products;
  late List<Partner> _partners;
  late List<BusinessDocument> _documents;
  late List<StockMovement> _movements;
  late List<AuditEvent> _auditEvents;

  final Map<DocumentType, int> _sequences = {
    DocumentType.devis: 4,
    DocumentType.bl: 4,
    DocumentType.facture: 6,
    DocumentType.creditNote: 1,
    DocumentType.supplierOrder: 2,
    DocumentType.stockEntry: 3,
  };

  final _quantityController = TextEditingController(text: '1');
  final _discountController = TextEditingController(text: '0');
  final _purchaseQuantityController = TextEditingController(text: '2');
  final _purchaseSerialsController = TextEditingController();
  final _productSearchController = TextEditingController();
  final _productFilterController = TextEditingController();
  final _salesShortcutFocusNode = FocusNode(debugLabel: 'sales-shortcuts');
  final _quantityFocusNode = FocusNode(debugLabel: 'sales-quantity');
  final _discountFocusNode = FocusNode(debugLabel: 'sales-discount');
  FocusNode? _productSearchFocusNode;
  TextEditingController? _activeProductSearchController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _companyTaxIdController;
  late final TextEditingController _companyAddressController;
  late final TextEditingController _companyCityController;
  late final TextEditingController _companyPhoneController;
  late final TextEditingController _companyEmailController;
  late final TextEditingController _companyLogoController;
  late final TextEditingController _companyFooterController;
  late final TextEditingController _companyLegalController;
  late final TextEditingController _timbreAmountController;
  final _backupImportController = TextEditingController();

  Section _section = Section.dashboard;
  DocumentType _newDocumentType = DocumentType.facture;
  String _selectedClientId = 'c1';
  String _selectedSupplierId = 's1';
  String _selectedProductId = 'p1';
  String _selectedPurchaseProductId = 'p2';
  String _selectedWarehouseId = 'sfax';
  String? _selectedDocumentId;
  String? _editingDocumentId;
  String _productCategoryFilter = 'Tous';
  String _productQuery = '';
  final List<DocumentLine> _draftLines = [];
  bool _guidedSetupDismissed = false;
  bool _showAdvancedSaleOptions = false;
  bool _guidedFocusActive = false;
  int _guidedFocusIndex = 0;
  String? _salesFeedbackText;
  bool _salesFeedbackIsError = false;
  bool _pdfExportInProgress = false;
  String? _lastSaleSuccessDocumentId;
  DateTime? _lastSavedAt;
  String _storageStatus = 'Sauvegarde locale prête';

  late final AppRepository _appRepository;
  late final AppConfig _appConfig;
  late final TenantContext _tenantContext;
  late final ProductRepository _productRepository;
  late final WarehouseRepository _warehouseRepository;
  late final CategoryRepository _categoryRepository;
  late final ClientRepository _clientRepository;
  late final SupplierRepository _supplierRepository;
  late final DocumentRepository _documentRepository;
  late final StockRepository _stockRepository;
  late final CompanyRepository _companyRepository;
  late final AuditRepository _auditRepository;
  late final BackupRepository _backupRepository;
  late final AppDatabase _database;
  late final DriftSnapshotStore _driftStore;
  late final DeviceIdentityService _deviceIdentityService;
  late final ConnectivityService _connectivityService;
  late final SyncOutboxRepository _syncOutboxRepository;
  late final SyncOutboxService _syncOutboxService;
  late final SyncPushService _syncPushService;

  late final InventoryCubit _inventoryCubit;
  late final DashboardCubit _dashboardCubit;
  late final WarehouseCubit _warehouseCubit;
  late final CategoryCubit _categoryCubit;
  late final ProductsCubit _productsCubit;
  late final ClientsCubit _clientsCubit;
  late final SuppliersCubit _suppliersCubit;
  late final SalesCubit _salesCubit;
  late final StockCubit _stockCubit;
  late final DocumentsCubit _documentsCubit;
  late final CompanyCubit _companyCubit;
  late final BackupCubit _backupCubit;
  late final OnboardingCubit _onboardingCubit;
  late final SyncStatusCubit _syncStatusCubit;

  final _dashboardPrimaryActionKey = GlobalKey(debugLabel: 'guide-sale-cta');
  final _firstProductStepKey = GlobalKey(debugLabel: 'guide-first-product');
  final _firstClientStepKey = GlobalKey(debugLabel: 'guide-first-client');
  final _firstSaleStepKey = GlobalKey(debugLabel: 'guide-first-sale');
  final _productCreateActionKey = GlobalKey(debugLabel: 'guide-product-create');
  final _clientCreateActionKey = GlobalKey(debugLabel: 'guide-client-create');
  final _salesProductSearchKey = GlobalKey(debugLabel: 'guide-sales-search');
  final _salesValidateKey = GlobalKey(debugLabel: 'guide-sales-validate');
  final _saleSuccessKey = GlobalKey(debugLabel: 'guide-sale-success');

  @override
  void initState() {
    super.initState();
    _seedData();
    _configureApplicationLayer();
    _loadPersistedState();
    _onboardingCubit.loadProgress();
    _guidedSetupDismissed = _onboardingCubit.state.guidedSetupDismissed;
    _companyNameController = TextEditingController(text: _company.name);
    _companyTaxIdController = TextEditingController(text: _company.taxId);
    _companyAddressController = TextEditingController(text: _company.address);
    _companyCityController = TextEditingController(text: _company.city);
    _companyPhoneController = TextEditingController(text: _company.phone);
    _companyEmailController = TextEditingController(text: _company.email);
    _companyLogoController = TextEditingController(text: _company.logoSource);
    _companyFooterController = TextEditingController(
      text: _company.invoiceFooter,
    );
    _companyLegalController = TextEditingController(text: _company.legalInfo);
    _timbreAmountController = TextEditingController(
      text: _company.timbreFiscalAmount.toStringAsFixed(3),
    );
    _guidedFocusIndex = _firstIncompleteGuideIndex();
    if (_shouldShowFirstSuccessGuide) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_shouldShowFirstSuccessGuide) return;
        setState(() => _guidedFocusActive = true);
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _discountController.dispose();
    _purchaseQuantityController.dispose();
    _purchaseSerialsController.dispose();
    _productSearchController.dispose();
    _productFilterController.dispose();
    _salesShortcutFocusNode.dispose();
    _quantityFocusNode.dispose();
    _discountFocusNode.dispose();
    _companyNameController.dispose();
    _companyTaxIdController.dispose();
    _companyAddressController.dispose();
    _companyCityController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _companyLogoController.dispose();
    _companyFooterController.dispose();
    _companyLegalController.dispose();
    _timbreAmountController.dispose();
    _backupImportController.dispose();
    _inventoryCubit.close();
    _dashboardCubit.close();
    _productsCubit.close();
    _warehouseCubit.close();
    _categoryCubit.close();
    _clientsCubit.close();
    _suppliersCubit.close();
    _salesCubit.close();
    _stockCubit.close();
    _documentsCubit.close();
    _companyCubit.close();
    _backupCubit.close();
    _onboardingCubit.close();
    _syncStatusCubit.close();
    _connectivityService.dispose();
    _syncOutboxRepository.close();
    _database.close();
    super.dispose();
  }

  void _updateState(VoidCallback updates) => setState(updates);

  void _configureApplicationLayer() {
    _appConfig = widget.config ?? AppConfig.fromEnvironment();
    _tenantContext = TenantContext.current(config: _appConfig);
    _database = createAppDatabase(tenantContext: _tenantContext);
    _driftStore = DriftSnapshotStore(_database, tenantContext: _tenantContext);
    _deviceIdentityService = const DeviceIdentityService();
    _connectivityService = ConnectivityService();
    _syncOutboxRepository = SyncOutboxRepository(_database);
    _syncOutboxService = SyncOutboxService(
      repository: _syncOutboxRepository,
      deviceIdentityService: _deviceIdentityService,
      tenantContext: _tenantContext,
    );
    _syncPushService = SyncPushService(
      outboxRepository: _syncOutboxRepository,
      connectivityService: _connectivityService,
      tenantContext: _tenantContext,
      remoteWriter: SupabaseSyncRemoteWriter(
        provider: SupabaseClientProvider(config: _appConfig),
      ),
    );
    final localDataSource = AppSnapshotLocalDataSource(
      fallbackSnapshot: _snapshot(),
    );
    _appRepository = AppRepository(
      localDataSource,
      driftStore: _driftStore,
      tenantContext: _tenantContext,
      syncOutboxService: _syncOutboxService,
      driftMigration: AppSnapshotToDriftMigration(
        database: _database,
        legacyDataSource: localDataSource,
        driftStore: _driftStore,
      ),
    );
    _productRepository = ProductRepository(_appRepository);
    _warehouseRepository = WarehouseRepository(_appRepository);
    _categoryRepository = CategoryRepository(_appRepository);
    _clientRepository = ClientRepository(_appRepository);
    _supplierRepository = SupplierRepository(_appRepository);
    _documentRepository = DocumentRepository(_appRepository);
    _stockRepository = StockRepository(_appRepository);
    _companyRepository = CompanyRepository(_appRepository);
    _auditRepository = AuditRepository(_appRepository);
    _backupRepository = BackupRepository(_appRepository);

    _inventoryCubit = InventoryCubit(_appRepository);
    _dashboardCubit = DashboardCubit(_appRepository);
    _warehouseCubit = WarehouseCubit(_warehouseRepository, _auditRepository);
    _categoryCubit = CategoryCubit(_categoryRepository);
    _productsCubit = ProductsCubit(
      _productRepository,
      _stockRepository,
      _auditRepository,
    );
    _clientsCubit = ClientsCubit(_clientRepository, _auditRepository);
    _suppliersCubit = SuppliersCubit(_supplierRepository, _auditRepository);
    _salesCubit = SalesCubit(
      _documentRepository,
      _stockRepository,
      _auditRepository,
    );
    _stockCubit = StockCubit(_stockRepository, _auditRepository);
    _documentsCubit = DocumentsCubit(_documentRepository, _auditRepository);
    _companyCubit = CompanyCubit(_companyRepository, _auditRepository);
    _backupCubit = BackupCubit(_backupRepository, _auditRepository);
    _onboardingCubit = OnboardingCubit();
    _syncStatusCubit = SyncStatusCubit(
      outboxRepository: _syncOutboxRepository,
      connectivityService: _connectivityService,
      tenantContext: _tenantContext,
    )..start();
  }

  void _seedData() {
    _company = const CompanyProfile(
      name: 'Nouveau magasin',
      taxId: '',
      address: '',
      city: '',
      phone: '',
      email: '',
      logoSource: AppAssets.systemLogoSource,
      invoiceFooter: 'Merci pour votre confiance.',
      timbreFiscalEnabled: true,
      timbreFiscalAmount: 1,
    );
    _warehouses = const [
      Warehouse(id: 'main', name: 'Dépôt principal', city: '', code: 'MAIN'),
    ];
    _categories = const [Category(id: 'cat-default', name: 'Électronique')];
    _products = [];
    _partners = [];
    _documents = [];
    _movements = [];
    _auditEvents = [];
    _sequences
      ..clear()
      ..addAll(SequenceService.initialSequences());
    _selectedClientId = '';
    _selectedSupplierId = '';
    _selectedProductId = '';
    _selectedPurchaseProductId = '';
    _selectedWarehouseId = 'main';
    _selectedDocumentId = null;
  }

  AppSnapshot _snapshot() {
    return AppSnapshot(
      company: _company,
      warehouses: _warehouses,
      categories: _categories,
      products: _products,
      partners: _partners,
      documents: _documents,
      movements: _movements,
      sequences: Map<DocumentType, int>.from(_sequences),
      auditEvents: _auditEvents,
    );
  }

  void _loadPersistedState() {
    _inventoryCubit.loadInitialData().then((_) {
      if (!mounted) return;
      _hydrateFromInventoryState(syncControllers: true);
    });
  }

  void _hydrateFromInventoryState({bool syncControllers = false}) {
    final state = _inventoryCubit.state;
    if (state is InventoryLoaded) {
      setState(() {
        _applySnapshot(state.snapshot);
        _lastSavedAt = state.lastSavedAt;
        _storageStatus = state.storageStatus;
        if (syncControllers) {
          _syncCompanyControllers();
        }
      });
      _refreshApplicationCubits();
    } else if (state is InventoryFailure) {
      setState(() {
        _reconcileSequences();
        _storageStatus = state.message;
      });
    }
  }

  void _refreshApplicationCubits() {
    _dashboardCubit.refreshDashboard();
    _warehouseCubit.loadWarehouses();
    _categoryCubit.loadCategories();
    _productsCubit.loadProducts();
    _clientsCubit.loadClients();
    _suppliersCubit.loadSuppliers();
    _stockCubit.loadStockOverview();
    _documentsCubit.loadDocuments();
    _companyCubit.loadCompany();
  }

  void _applyRepositoryState({String? selectedDocumentId}) {
    _inventoryCubit.refresh();
    _applySnapshot(_appRepository.snapshot);
    _lastSavedAt = _appRepository.lastSavedAt;
    _storageStatus = _appRepository.storageStatus;
    if (selectedDocumentId != null) {
      _selectedDocumentId = selectedDocumentId;
    }
    _refreshApplicationCubits();
  }

  void _applySnapshot(AppSnapshot snapshot) {
    _company = AppSnapshotCodec.safeCompanyProfile(snapshot.company);
    _warehouses = snapshot.warehouses;
    _categories = snapshot.categories;
    _products = snapshot.products;
    _partners = snapshot.partners;
    _documents = snapshot.documents;
    _movements = snapshot.movements;
    _auditEvents = snapshot.auditEvents.isEmpty
        ? _auditEvents
        : snapshot.auditEvents;
    _sequences
      ..clear()
      ..addAll(snapshot.sequences);
    _normalizeLegacyStockFlags();
    _reconcileSequences();
    _ensureSelections();
  }

  String _companyDisplayAddress(CompanyProfile company) {
    final address = company.address.trim();
    final city = company.city.trim();
    if (address.isEmpty) return city;
    if (city.isEmpty) return address;
    return '$address, $city';
  }

  void _normalizeLegacyStockFlags() {
    for (var i = 0; i < _documents.length; i++) {
      final document = _documents[i];
      final hasMovement = _movements.any(
        (movement) => movement.documentNumber == document.number,
      );
      final shouldHaveStockFlag =
          document.status == DocumentStatus.validated &&
          hasMovement &&
          (document.type == DocumentType.bl ||
              document.type == DocumentType.stockEntry ||
              document.type == DocumentType.creditNote ||
              (document.type == DocumentType.facture &&
                  document.sourceNumber == null));
      if (shouldHaveStockFlag && !document.stockApplied) {
        _documents[i] = document.copyWith(stockApplied: true);
      }
    }
  }

  void _ensureSelections() {
    final activeClients = _clients.where((client) => client.active).toList();
    final selectableClients = activeClients.isEmpty ? _clients : activeClients;
    if (selectableClients.every((client) => client.id != _selectedClientId)) {
      _selectedClientId = selectableClients.firstOrNull?.id ?? '';
    }

    final activeSuppliers = _suppliers
        .where((supplier) => supplier.active)
        .toList();
    final selectableSuppliers = activeSuppliers.isEmpty
        ? _suppliers
        : activeSuppliers;
    if (selectableSuppliers.every(
      (supplier) => supplier.id != _selectedSupplierId,
    )) {
      _selectedSupplierId = selectableSuppliers.firstOrNull?.id ?? '';
    }

    final activeProducts = _products
        .where((product) => product.active)
        .toList();
    final selectableProducts = activeProducts.isEmpty
        ? _products
        : activeProducts;
    if (selectableProducts.every(
      (product) => product.id != _selectedProductId,
    )) {
      _selectedProductId = selectableProducts.firstOrNull?.id ?? '';
    }
    if (selectableProducts.every(
      (product) => product.id != _selectedPurchaseProductId,
    )) {
      _selectedPurchaseProductId = selectableProducts.firstOrNull?.id ?? '';
    }

    final activeWarehouses = _warehouses
        .where((warehouse) => warehouse.active)
        .toList();
    final selectableWarehouses = activeWarehouses.isEmpty
        ? _warehouses
        : activeWarehouses;
    if (selectableWarehouses.every(
      (warehouse) => warehouse.id != _selectedWarehouseId,
    )) {
      _selectedWarehouseId = selectableWarehouses.firstOrNull?.id ?? '';
    }
    if (_documents.every((document) => document.id != _selectedDocumentId)) {
      _selectedDocumentId = _documents.firstOrNull?.id;
    }
  }

  void _reconcileSequences() {
    _sequences
      ..clear()
      ..addAll(
        SequenceService.reconcile(sequences: _sequences, documents: _documents),
      );
  }

  List<Partner> get _clients =>
      _partners.where((partner) => partner.type == PartnerType.client).toList();

  List<Partner> get _suppliers => _partners
      .where((partner) => partner.type == PartnerType.supplier)
      .toList();

  Partner get _selectedClient =>
      _clients.firstWhere((partner) => partner.id == _selectedClientId);

  Partner get _selectedSupplier =>
      _suppliers.firstWhere((partner) => partner.id == _selectedSupplierId);

  Product get _selectedProduct =>
      _products.firstWhere((product) => product.id == _selectedProductId);

  Product get _selectedPurchaseProduct => _products.firstWhere(
    (product) => product.id == _selectedPurchaseProductId,
  );

  Warehouse get _selectedWarehouse => _warehouses.firstWhere(
    (warehouse) => warehouse.id == _selectedWarehouseId,
  );

  BusinessDocument? get _selectedDocument {
    if (_selectedDocumentId == null) return _documents.firstOrNull;
    return _documents
        .where((document) => document.id == _selectedDocumentId)
        .firstOrNull;
  }

  double get _dailySales => _dashboardCubit.state.dailySales;

  double get _monthlySales => _dashboardCubit.state.monthlySales;

  List<Product> get _lowStockProducts => _stockCubit.state.lowStockProducts;

  List<BusinessDocument> get _draftDocuments =>
      _dashboardCubit.state.draftDocuments;

  BusinessDocument? get _lastSaleSuccessDocument => _documents
      .where((document) => document.id == _lastSaleSuccessDocumentId)
      .firstOrNull;

  bool get _hasFirstProduct => _products.any((product) => product.active);

  bool get _hasFirstClient => _clients.any((client) => client.active);

  bool get _hasFirstSale => _documents.any(
    (document) =>
        (document.type == DocumentType.bl ||
            document.type == DocumentType.facture) &&
        document.status == DocumentStatus.validated,
  );

  bool get _firstSuccessComplete =>
      _hasFirstProduct && _hasFirstClient && _hasFirstSale;

  bool get _shouldShowFirstSuccessGuide =>
      !_guidedSetupDismissed && !_firstSuccessComplete;

  bool get _hasMeaningfulDashboardData =>
      _hasFirstSale ||
      _draftDocuments.isNotEmpty ||
      _lowStockProducts.isNotEmpty;

  String _newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  void _showMessage(String message, {bool isError = false}) {
    final color = isError ? AppColors.danger : AppColors.primaryDark;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _triggerManualPushSync() async {
    final unavailableMessage = SyncPilotMessages.unavailableMessage(
      authBypassEnabled: _appConfig.authBypassEnabled,
      devBypassTenantActive: _tenantContext.isDevBypassTenantActive,
      hasSupabaseConfig: _appConfig.hasSupabaseConfig,
    );
    if (unavailableMessage != null) {
      _showMessage(unavailableMessage, isError: true);
      return;
    }
    final pendingReport = await _syncPushService.pushPending(limit: 100);
    final retryReport = await _syncPushService.retryFailed(limit: 100);

    await _syncStatusCubit.refresh();
    if (!mounted) return;

    final hasFailure =
        pendingReport.errorOrNull != null ||
        retryReport.errorOrNull != null ||
        pendingReport.valueOrNull?.hasFailures == true ||
        retryReport.valueOrNull?.hasFailures == true;

    if (hasFailure) {
      final lastError =
          pendingReport.errorOrNull ??
          retryReport.errorOrNull ??
          pendingReport.valueOrNull?.lastError ??
          retryReport.valueOrNull?.lastError;

      _showMessage(
        'Synchronisation échouée: ${lastError?.message ?? "Erreur inconnue"}. Les données locales sont conservées.',
        isError: true,
      );

      if (kDebugMode) {
        final failedRows = await _syncOutboxRepository.listFailed(
          tenantId: _tenantContext.selectedTenantId,
        );
        for (final row in failedRows) {
          debugPrint(
            '[sync_debug] failed row: ${row.entityType}/${row.entityId} (op: ${row.operation}) error: ${row.lastError}',
          );
        }
      }
      return;
    }

    _showMessage('Synchronisation terminée.');
  }

  Future<void> _triggerRepairSync() async {
    final unavailableMessage = SyncPilotMessages.unavailableMessage(
      authBypassEnabled: _appConfig.authBypassEnabled,
      devBypassTenantActive: _tenantContext.isDevBypassTenantActive,
      hasSupabaseConfig: _appConfig.hasSupabaseConfig,
    );
    if (unavailableMessage != null) {
      _showMessage(unavailableMessage, isError: true);
      return;
    }

    await _appRepository.repairSync();
    _showMessage(SyncPilotMessages.repairSyncSuccessMessage);

    // Attempt push immediately after repair
    await _triggerManualPushSync();
  }

  void _goToSales({DocumentType? type}) {
    setState(() {
      _ensureSelections();
      if (_editingDocumentId == null) {
        _newDocumentType = type ?? DocumentType.facture;
        _showAdvancedSaleOptions = type != null && type != DocumentType.facture;
        _lastSaleSuccessDocumentId = null;
      }
      _section = Section.sales;
    });
    _focusProductSearchSoon();
  }

  void _focusProductSearchSoon({bool ensureVisible = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = ensureVisible
          ? _salesProductSearchKey.currentContext
          : null;
      if (targetContext == null) {
        _requestProductSearchFocus();
        return;
      }
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: .34,
      ).whenComplete(_requestProductSearchFocus);
    });
  }

  void _requestProductSearchFocus() {
    void applyFocus() {
      if (!mounted) return;
      final focusNode = _productSearchFocusNode;
      if (focusNode == null) return;
      FocusScope.of(context).requestFocus(focusNode);
      focusNode.requestFocus();
      final controller = _activeProductSearchController;
      if (controller == null) return;
      controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: controller.text.length,
      );
    }

    applyFocus();
    Future<void>.delayed(const Duration(milliseconds: 90), applyFocus);
  }

  void _focusQuantitySoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _quantityFocusNode.requestFocus();
      _quantityController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _quantityController.text.length,
      );
    });
  }

  void _setSalesFeedback(String message, {bool isError = false}) {
    setState(() {
      _salesFeedbackText = message;
      _salesFeedbackIsError = isError;
    });
  }

  void _bumpQuantity(int delta) {
    final current = int.tryParse(_quantityController.text.trim()) ?? 1;
    final next = (current + delta).clamp(1, 999);
    setState(() => _quantityController.text = '$next');
  }

  KeyEventResult _handleSalesKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _addDraftLine();
      _focusProductSearchSoon();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd ||
        key == LogicalKeyboardKey.equal) {
      _bumpQuantity(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      _bumpQuantity(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _exportProductsCsv() async {
    final rows = [
      [
        'SKU',
        'Produit',
        'Catégorie',
        'Marque',
        'Prix achat HT',
        'Prix vente HT',
        'TVA',
        'Prix TTC',
        'Stock total',
        'Stock min',
        'Actif',
      ],
      for (final product in _products)
        [
          product.sku,
          product.name,
          product.category,
          product.brand,
          product.purchaseHt.toStringAsFixed(3),
          product.saleHt.toStringAsFixed(3),
          product.tvaRate.label,
          product.saleTtc.toStringAsFixed(3),
          '${product.totalStock}',
          '${product.minStock}',
          product.active ? 'oui' : 'non',
        ],
    ];
    final message = await saveTextFile(
      fileName: 'trace-ultra-produits.csv',
      contents: _csv(rows),
      mimeType: 'text/csv;charset=utf-8',
    );
    _showMessage(message);
  }

  Future<void> _exportPartnersCsv(PartnerType type) async {
    final partners = _partners.where((partner) => partner.type == type);
    final rows = [
      [
        'Type',
        'Nom',
        'Société',
        'Contact',
        'Matricule fiscal',
        'Téléphone',
        'Email',
        'Adresse',
        'Ville',
        'Actif',
      ],
      for (final partner in partners)
        [
          partner.type.label,
          partner.name,
          partner.companyName,
          partner.contactName,
          partner.taxId,
          partner.phone,
          partner.email,
          partner.address,
          partner.city,
          partner.active ? 'oui' : 'non',
        ],
    ];
    final message = await saveTextFile(
      fileName: type == PartnerType.client
          ? 'trace-ultra-clients.csv'
          : 'trace-ultra-fournisseurs.csv',
      contents: _csv(rows),
      mimeType: 'text/csv;charset=utf-8',
    );
    _showMessage(message);
  }

  Future<void> _exportDocumentsCsv() async {
    final rows = [
      [
        'Numéro',
        'Type',
        'Statut',
        'Date',
        'Tiers',
        'Source',
        'Total HT',
        'TVA',
        'Timbre',
        'Net à payer',
        'Paiement',
      ],
      for (final document in _documents)
        [
          document.number,
          document.type.label,
          document.status.label,
          formatDate(document.date),
          document.partnerName,
          document.sourceNumber ?? '',
          _documentTotalHt(document).toStringAsFixed(3),
          _documentTotalTva(document).toStringAsFixed(3),
          TaxService.timbreFiscalAmount(
            enabled: document.applyTimbreFiscal,
            configuredAmount: document.timbreFiscalAmount,
          ).toStringAsFixed(3),
          _documentDisplayNet(document).toStringAsFixed(3),
          document.type == DocumentType.facture
              ? _effectivePaymentStatus(document).label
              : '',
        ],
    ];
    final message = await saveTextFile(
      fileName: 'trace-ultra-documents.csv',
      contents: _csv(rows),
      mimeType: 'text/csv;charset=utf-8',
    );
    _showMessage(message);
  }

  Future<void> _exportStockCsv() async {
    final rows = [
      ['Date', 'Document', 'Produit', 'Dépôt', 'Sens', 'Qté', 'N° série'],
      for (final movement in _movements)
        [
          formatDate(movement.date),
          movement.documentNumber,
          movement.productName,
          _warehouseById(movement.warehouseId).name,
          movement.direction == StockDirection.inbound ? 'Entrée' : 'Sortie',
          '${movement.quantity}',
          movement.serialNumbers.join(', '),
        ],
    ];
    final message = await saveTextFile(
      fileName: 'trace-ultra-stock.csv',
      contents: _csv(rows),
      mimeType: 'text/csv;charset=utf-8',
    );
    _showMessage(message);
  }

  pw.Widget _pdfTotalRow(String label, String value, {bool strong = false}) {
    final style = pw.TextStyle(
      fontWeight: strong ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  String _csv(List<List<String>> rows) {
    return rows.map((row) => row.map(_csvCell).join(';')).join('\n');
  }

  String _csvCell(String cell) {
    final withoutLineBreaks = cell.replaceAll(RegExp(r'[\r\n]+'), ' ');
    final trimmedLeft = withoutLineBreaks.trimLeft();
    final startsLikeFormula =
        trimmedLeft.isNotEmpty && '=+-@'.contains(trimmedLeft[0]);
    final startsWithControl =
        withoutLineBreaks.startsWith('\t') ||
        withoutLineBreaks.startsWith('\r');
    final safeCell = startsLikeFormula || startsWithControl
        ? "'$withoutLineBreaks"
        : withoutLineBreaks;
    return '"${safeCell.replaceAll('"', '""')}"';
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<InventoryCubit>.value(value: _inventoryCubit),
      BlocProvider<DashboardCubit>.value(value: _dashboardCubit),
      BlocProvider<WarehouseCubit>.value(value: _warehouseCubit),
      BlocProvider<CategoryCubit>.value(value: _categoryCubit),
      BlocProvider<ProductsCubit>.value(value: _productsCubit),
      BlocProvider<ClientsCubit>.value(value: _clientsCubit),
      BlocProvider<SuppliersCubit>.value(value: _suppliersCubit),
      BlocProvider<SalesCubit>.value(value: _salesCubit),
      BlocProvider<StockCubit>.value(value: _stockCubit),
      BlocProvider<DocumentsCubit>.value(value: _documentsCubit),
      BlocProvider<CompanyCubit>.value(value: _companyCubit),
      BlocProvider<BackupCubit>.value(value: _backupCubit),
      BlocProvider<OnboardingCubit>.value(value: _onboardingCubit),
      BlocProvider<SyncStatusCubit>.value(value: _syncStatusCubit),
    ],
    child: _buildInventoryShell(),
  );
}
