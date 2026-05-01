import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:ultra_trace/app/app_config.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/features/inventory/presentation/inventory_shell_page.dart';
import 'package:ultra_trace/features/onboarding/widgets/blinking_continue_button.dart';
import 'package:ultra_trace/main.dart';
import 'package:ultra_trace/storage/app_storage.dart';

void main() {
  late Directory storageDirectory;
  late AppDatabase database;

  setUp(() {
    storageDirectory = Directory.systemTemp.createTempSync('trace_ultra_test_');
    database = AppDatabase.forTesting(NativeDatabase.memory());
    setAppDatabaseForTesting(database);
    setPersistentStorageDirectoryForTesting(storageDirectory.path);
    deletePersistentValue(appStateStorageKey);
    deletePersistentValue(onboardingCompletedStorageKey);
    deletePersistentValue(onboardingStoreSetupStorageKey);
    writePersistentValue(onboardingCompletedStorageKey, 'true');
  });

  tearDown(() async {
    setAppDatabaseForTesting(null);
    setPersistentStorageDirectoryForTesting(null);
    try {
      await database.close();
    } catch (_) {}
    if (storageDirectory.existsSync()) {
      storageDirectory.deleteSync(recursive: true);
    }
  });

  testWidgets('shows the dashboard when onboarding is already complete', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_starterSnapshot().toJson()),
    );

    await _pumpWorkspace(tester);

    expect(find.text('Préparer votre magasin'), findsOneWidget);
    expect(find.text('Première réussite guidée'), findsOneWidget);
    expect(find.text('Démarrer avec Tarek'), findsOneWidget);
  });

  testWidgets('shows onboarding on first launch only when setup is needed', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    deletePersistentValue(onboardingCompletedStorageKey);

    await tester.pumpWidget(
      const MyApp(
        enableAuth: false,
        holdOnSplash: false,
        holdOnOnboarding: false,
        showOnboardingEveryLaunch: false,
        splashDuration: Duration(milliseconds: 1),
      ),
    );

    expect(find.text('Préparation de votre espace local'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BlinkingContinueButton), findsOneWidget);
    expect(find.text('Ignorer'), findsNothing);
    expect(find.text('Tableau de bord'), findsNothing);
  });

  testWidgets(
    'skips onboarding when operational data already exists even without completion flag',
    (tester) async {
      _setDesktopViewport(tester);
      deletePersistentValue(onboardingCompletedStorageKey);
      writePersistentValue(
        appStateStorageKey,
        jsonEncode(_snapshotWithProduct().toJson()),
      );

      await _pumpWorkspace(tester, completed: false);

      expect(find.text('Faire une vente'), findsWidgets);
      expect(find.byType(BlinkingContinueButton), findsNothing);
    },
  );

  testWidgets('recovers from backup when primary snapshot is corrupt', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    deletePersistentValue(onboardingCompletedStorageKey);
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_snapshotWithProduct().toJson()),
    );
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_starterSnapshot().toJson()),
    );

    final primary = File('${storageDirectory.path}/$appStateStorageKey.json');
    primary.writeAsStringSync('{broken', flush: true);

    await _pumpWorkspace(tester, completed: false);

    expect(find.text('Faire une vente'), findsWidgets);
    expect(find.byType(BlinkingContinueButton), findsNothing);
  });

  testWidgets('draft invoices block payment and avoir actions', (tester) async {
    _setDesktopViewport(tester);
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_snapshotWithDraftInvoice().toJson()),
    );

    await _pumpWorkspace(tester);

    await _openSecondarySection(tester, 'Documents');

    final paymentButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Paiement'),
    );
    final avoirButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Avoir'),
    );

    expect(paymentButton.onPressed, isNull);
    expect(avoirButton.onPressed, isNull);
  });

  testWidgets('validated avoirs reduce displayed invoice and report totals', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_snapshotWithPartialCreditNote().toJson()),
    );

    await _pumpWorkspace(tester);

    await _openSecondarySection(tester, 'Documents');

    expect(find.text('FAC-2026-0001'), findsWidgets);
    expect(find.text('1 190,000 DT'), findsWidgets);

    await _openSecondarySection(tester, 'Rapports');

    expect(find.text('Ventes nettes'), findsOneWidget);
    expect(find.text('Avoirs validés'), findsOneWidget);
    expect(find.text('-1 190,000 DT'), findsOneWidget);
  });

  testWidgets('cloud pilot label and backup reminder are visible', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_starterSnapshot().toJson()),
    );

    await _pumpInventoryShell(
      tester,
      const AppConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        authBypassEnabled: true,
        cloudPilotEnabled: true,
      ),
    );

    expect(find.text('Mode pilote cloud'), findsOneWidget);

    await tester.tap(find.byTooltip('Société'));
    await tester.pumpAndSettle();

    expect(find.text('Mode pilote cloud'), findsWidgets);
    expect(find.textContaining('Téléchargez une sauvegarde'), findsOneWidget);
    expect(find.text('Télécharger une sauvegarde'), findsOneWidget);
    expect(find.text('Restaurer une sauvegarde'), findsOneWidget);
  });

  testWidgets('manual sync shows pilot-safe local mode message', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_starterSnapshot().toJson()),
    );

    await _pumpInventoryShell(
      tester,
      const AppConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        authBypassEnabled: true,
        cloudPilotEnabled: true,
      ),
    );
    await tester.tap(find.byTooltip('Synchroniser maintenant'));
    await tester.pumpAndSettle();
    expect(
      find.text('Mode local: synchronisation cloud désactivée.'),
      findsOneWidget,
    );
  });

  testWidgets('manual sync shows pilot-safe missing config message', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    writePersistentValue(
      appStateStorageKey,
      jsonEncode(_starterSnapshot().toJson()),
    );
    deletePersistentValue(selectedTenantIdStorageKey);
    deletePersistentValue(selectedTenantNameStorageKey);
    deletePersistentValue(selectedUserIdStorageKey);

    await _pumpInventoryShell(
      tester,
      const AppConfig(
        supabaseUrl: '',
        supabaseAnonKey: '',
        authBypassEnabled: false,
        cloudPilotEnabled: true,
      ),
    );
    await tester.tap(find.byTooltip('Synchroniser maintenant'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion cloud non configurée.'), findsOneWidget);
  });
}

Future<void> _openSecondarySection(WidgetTester tester, String label) async {
  if (find.text(label).evaluate().isEmpty) {
    await tester.ensureVisible(find.text('Plus').first);
    await tester.tap(find.text('Plus').first);
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(find.text(label).first);
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  bool completed = true,
}) async {
  if (completed) {
    writePersistentValue(onboardingCompletedStorageKey, 'true');
  } else {
    deletePersistentValue(onboardingCompletedStorageKey);
  }

  await tester.pumpWidget(
    const MyApp(
      enableAuth: false,
      holdOnSplash: false,
      holdOnOnboarding: false,
      showOnboardingEveryLaunch: false,
      splashDuration: Duration(milliseconds: 1),
    ),
  );
  await tester.pump(const Duration(milliseconds: 2));
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 450));
}

Future<void> _pumpInventoryShell(WidgetTester tester, AppConfig config) async {
  await tester.pumpWidget(
    MaterialApp(home: InventoryShellPage(config: config)),
  );
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 450));
}

AppSnapshot _snapshotWithProduct() {
  return AppSnapshot(
    company: const CompanyProfile(
      name: 'Trace Ultra Store',
      taxId: '1234567/A/M/000',
      address: 'Avenue Habib Bourguiba',
      city: 'Tunis',
      phone: '+216 20 000 000',
      email: 'contact@trace.tn',
      logoSource: '',
      invoiceFooter: 'Merci.',
    ),
    warehouses: const [
      Warehouse(id: 'main', name: 'Dépôt principal', city: 'Tunis'),
    ],
    categories: const [Category(id: 'cat-default', name: 'Électronique')],
    products: const [
      Product(
        id: 'p1',
        name: 'TV Samsung',
        sku: 'TV-SAM',
        category: 'Électronique',
        purchaseHt: 800,
        saleHt: 1000,
        tvaRate: TvaRate.rate19,
        minStock: 2,
        serialTracked: false,
        stockByWarehouse: {'main': 3},
        serialsByWarehouse: {'main': []},
        imageUrl: '',
      ),
    ],
    partners: const [],
    documents: const [],
    movements: const [],
    sequences: {DocumentType.facture: 1},
    auditEvents: const [],
  );
}

AppSnapshot _starterSnapshot() {
  return AppSnapshot(
    company: const CompanyProfile(
      name: 'Trace Ultra Store',
      taxId: '1234567/A/M/000',
      address: 'Avenue Habib Bourguiba',
      city: 'Tunis',
      phone: '+216 20 000 000',
      email: 'contact@trace.tn',
      logoSource: '',
      invoiceFooter: 'Merci.',
    ),
    warehouses: const [
      Warehouse(id: 'main', name: 'Dépôt principal', city: 'Tunis'),
    ],
    categories: const [Category(id: 'cat-default', name: 'Électronique')],
    products: const [],
    partners: const [],
    documents: const [],
    movements: const [],
    sequences: const {DocumentType.facture: 1},
    auditEvents: const [],
  );
}

AppSnapshot _snapshotWithDraftInvoice() {
  return AppSnapshot(
    company: const CompanyProfile(
      name: 'Trace Ultra Store',
      taxId: '1234567/A/M/000',
      address: 'Avenue Habib Bourguiba',
      city: 'Tunis',
      phone: '+216 20 000 000',
      email: 'contact@trace.tn',
      logoSource: '',
      invoiceFooter: 'Merci.',
    ),
    warehouses: const [
      Warehouse(id: 'main', name: 'Dépôt principal', city: 'Tunis'),
    ],
    categories: const [Category(id: 'cat-default', name: 'Électronique')],
    products: const [
      Product(
        id: 'p1',
        name: 'TV Samsung',
        sku: 'TV-SAM',
        category: 'Électronique',
        purchaseHt: 800,
        saleHt: 1000,
        tvaRate: TvaRate.rate19,
        minStock: 2,
        serialTracked: false,
        stockByWarehouse: {'main': 3},
        serialsByWarehouse: {'main': []},
        imageUrl: '',
      ),
    ],
    partners: const [
      Partner(
        id: 'c1',
        type: PartnerType.client,
        name: 'Client Test',
        taxId: '',
        address: 'Tunis',
        phone: '+216 20 000 000',
        email: 'client@example.tn',
      ),
    ],
    documents: [
      BusinessDocument(
        id: 'doc1',
        type: DocumentType.facture,
        number: 'FAC-2026-0001',
        status: DocumentStatus.draft,
        partnerId: 'c1',
        partnerName: 'Client Test',
        partnerTaxId: '',
        partnerAddress: 'Tunis',
        date: DateTime(2026, 4, 21),
        lines: const [
          DocumentLine(
            productId: 'p1',
            label: 'TV Samsung',
            sku: 'TV-SAM',
            quantity: 1,
            unitHt: 1000,
            tvaRate: TvaRate.rate19,
          ),
        ],
        warehouseId: 'main',
      ),
    ],
    movements: const [],
    sequences: const {DocumentType.facture: 2},
    auditEvents: const [],
  );
}

AppSnapshot _snapshotWithPartialCreditNote() {
  return AppSnapshot(
    company: const CompanyProfile(
      name: 'Trace Ultra Store',
      taxId: '1234567/A/M/000',
      address: 'Avenue Habib Bourguiba',
      city: 'Tunis',
      phone: '+216 20 000 000',
      email: 'contact@trace.tn',
      logoSource: '',
      invoiceFooter: 'Merci.',
    ),
    warehouses: const [
      Warehouse(id: 'main', name: 'Dépôt principal', city: 'Tunis'),
    ],
    categories: const [Category(id: 'cat-default', name: 'Électronique')],
    products: const [
      Product(
        id: 'p1',
        name: 'TV Samsung',
        sku: 'TV-SAM',
        category: 'Électronique',
        purchaseHt: 800,
        saleHt: 1000,
        tvaRate: TvaRate.rate19,
        minStock: 2,
        serialTracked: false,
        stockByWarehouse: {'main': 2},
        serialsByWarehouse: {'main': []},
        imageUrl: '',
      ),
    ],
    partners: const [
      Partner(
        id: 'c1',
        type: PartnerType.client,
        name: 'Client Test',
        taxId: '',
        address: 'Tunis',
        phone: '+216 20 000 000',
        email: 'client@example.tn',
      ),
    ],
    documents: [
      BusinessDocument(
        id: 'doc1',
        type: DocumentType.facture,
        number: 'FAC-2026-0001',
        status: DocumentStatus.validated,
        partnerId: 'c1',
        partnerName: 'Client Test',
        partnerTaxId: '',
        partnerAddress: 'Tunis',
        date: DateTime(2026, 4, 21),
        lines: const [
          DocumentLine(
            productId: 'p1',
            label: 'TV Samsung',
            sku: 'TV-SAM',
            quantity: 2,
            unitHt: 1000,
            tvaRate: TvaRate.rate19,
          ),
        ],
        warehouseId: 'main',
        stockApplied: true,
      ),
      BusinessDocument(
        id: 'av1',
        type: DocumentType.creditNote,
        number: 'AVR-2026-0001',
        status: DocumentStatus.validated,
        partnerId: 'c1',
        partnerName: 'Client Test',
        partnerTaxId: '',
        partnerAddress: 'Tunis',
        date: DateTime(2026, 4, 22),
        lines: const [
          DocumentLine(
            productId: 'p1',
            label: 'TV Samsung',
            sku: 'TV-SAM',
            quantity: 1,
            unitHt: 1000,
            tvaRate: TvaRate.rate19,
          ),
        ],
        warehouseId: 'main',
        sourceNumber: 'FAC-2026-0001',
        stockApplied: true,
      ),
    ],
    movements: const [],
    sequences: const {DocumentType.facture: 2, DocumentType.creditNote: 2},
    auditEvents: const [],
  );
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
