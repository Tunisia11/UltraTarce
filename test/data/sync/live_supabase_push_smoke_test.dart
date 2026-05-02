import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ultra_trace/app/app_config.dart';
import 'package:ultra_trace/app/tenant_context.dart';
import 'package:ultra_trace/data/local/database/app_database.dart';
import 'package:ultra_trace/data/remote/supabase_client_provider.dart';
import 'package:ultra_trace/data/sync/connectivity_service.dart';
import 'package:ultra_trace/data/sync/device_identity_service.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';
import 'package:ultra_trace/data/sync/sync_outbox_service.dart';
import 'package:ultra_trace/data/sync/sync_push_service.dart';
import 'package:ultra_trace/data/sync/sync_remote_writer.dart';
import 'package:ultra_trace/data/sync/sync_metadata_repository.dart';
import 'package:ultra_trace/domain/app_enums.dart';

void main() {
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  final hasLiveConfig =
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  test(
    'live local Supabase push smoke inserts pilot business rows',
    () async {
      final client = SupabaseClient(
        supabaseUrl,
        supabaseAnonKey,
        authOptions: const AuthClientOptions(
          authFlowType: AuthFlowType.implicit,
        ),
      );
      final unique = DateTime.now().microsecondsSinceEpoch;
      final email = 'pilot-$unique@trace-ultra.local';
      const password = 'TracePilot123!';
      await client.auth.signUp(email: email, password: password);
      await client.auth.signInWithPassword(email: email, password: password);
      final user = client.auth.currentUser;
      expect(user, isNotNull);
      expect(client.auth.currentSession, isNotNull);

      final tenant = await client
          .from('tenants')
          .insert({
            'name': 'Pilot Smoke $unique',
            'owner_user_id': user!.id,
            'status': 'active',
          })
          .select('id, name')
          .single();
      final tenantId = tenant['id'] as String;
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': 'Pilot Tester',
      });
      await client.from('tenant_users').insert({
        'tenant_id': tenantId,
        'user_id': user.id,
        'role': 'owner',
        'status': 'active',
      });

      final tenantContext = TenantContext(
        tenantIdOverride: tenantId,
        tenantNameOverride: tenant['name'] as String,
        userIdOverride: user.id,
      );
      final database = AppDatabase.forTesting(
        NativeDatabase.memory(),
        tenantContext: tenantContext,
      );
      final outboxRepository = SyncOutboxRepository(database);
      final connectivity = ConnectivityService();
      final outboxService = SyncOutboxService(
        repository: outboxRepository,
        deviceIdentityService: const DeviceIdentityService(),
        tenantContext: tenantContext,
      );
      final pushService = SyncPushService(
        outboxRepository: outboxRepository,
        connectivityService: connectivity,
        tenantContext: tenantContext,
        remoteWriter: SupabaseSyncRemoteWriter(
          provider: SupabaseClientProvider(
            config: const AppConfig(
              supabaseUrl: supabaseUrl,
              supabaseAnonKey: supabaseAnonKey,
              authBypassEnabled: false,
              cloudPilotEnabled: true,
              signupMode: SignupMode.public,
            ),
            clientOverride: client,
          ),
        ),
        metadataRepository: SyncMetadataRepository(database),
      );
      addTearDown(outboxRepository.close);
      addTearDown(connectivity.dispose);
      addTearDown(database.close);
      addTearDown(client.auth.signOut);

      await _enqueuePilotRows(outboxService, tenantId);

      final report = (await pushService.pushPending(limit: 50)).valueOrNull!;
      final summary = await outboxRepository.getSummary(tenantId: tenantId);
      expect(report.failed, 0);
      expect(summary.failedCount, 0);
      expect(summary.pendingCount, 0);

      final counts = <String, int>{};
      for (final table in [
        'companies',
        'warehouses',
        'categories',
        'products',
        'partners',
        'documents',
        'document_lines',
        'payments',
        'stock_movements',
      ]) {
        final rows = await client
            .from(table)
            .select('id')
            .eq('tenant_id', tenantId);
        counts[table] = (rows as List).length;
      }

      expect(counts['companies'], 1);
      expect(counts['warehouses'], 1);
      expect(counts['categories'], 1);
      expect(counts['products'], 1);
      expect(counts['partners'], 1);
      expect(counts['documents'], 1);
      expect(counts['document_lines'], 1);
      expect(counts['payments'], 1);
      expect(counts['stock_movements'], 1);
    },
    skip: hasLiveConfig
        ? null
        : 'Provide SUPABASE_URL and SUPABASE_ANON_KEY to run live push smoke.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _enqueuePilotRows(
  SyncOutboxService outboxService,
  String tenantId,
) async {
  final rows = [
    (
      'companies',
      tenantId,
      {
        'id': tenantId,
        'name': 'Trace Pilot',
        'taxId': '1234567/A/M/000',
        'address': 'Tunis',
        'city': 'Tunis',
      },
    ),
    (
      'warehouses',
      'main',
      {'id': 'main', 'name': 'Dépôt principal', 'city': 'Tunis'},
    ),
    ('categories', 'cat-main', {'id': 'cat-main', 'name': 'Général'}),
    (
      'products',
      'p1',
      {
        'id': 'p1',
        'name': 'Article pilote',
        'sku': 'PILOT-1',
        'category': 'Général',
        'purchaseHt': 10,
        'saleHt': 15,
        'tvaRate': 'rate19',
        'minStock': 1,
        'active': true,
      },
    ),
    (
      'partners',
      'c1',
      {
        'id': 'c1',
        'type': 'client',
        'name': 'Client pilote',
        'taxId': '',
        'address': 'Tunis',
        'active': true,
      },
    ),
    (
      'documents',
      'doc1',
      {
        'id': 'doc1',
        'type': 'facture',
        'status': 'validated',
        'number': 'FAC-2026-9001',
        'partnerId': 'c1',
        'partnerName': 'Client pilote',
        'date': '2026-05-01T10:00:00.000Z',
        'warehouseId': 'main',
        'applyTimbreFiscal': true,
        'timbreFiscalAmount': 1,
        'lines': [
          {
            'productId': 'p1',
            'label': 'Article pilote',
            'sku': 'PILOT-1',
            'quantity': 1,
            'unitHt': 15,
            'discountRate': 0,
            'tvaRate': 'rate19',
          },
        ],
        'payments': [
          {
            'id': 'pay1',
            'amount': 18.85,
            'method': 'cash',
            'date': '2026-05-01T10:05:00.000Z',
          },
        ],
      },
    ),
    (
      'document_lines',
      'doc1-0',
      {
        'id': 'doc1-0',
        'documentId': 'doc1',
        'productId': 'p1',
        'label': 'Article pilote',
        'sku': 'PILOT-1',
        'quantity': 1,
        'unitHt': 15,
        'discountRate': 0,
        'tvaRate': 'rate19',
      },
    ),
    (
      'payments',
      'pay1',
      {
        'id': 'pay1',
        'documentId': 'doc1',
        'amount': 18.85,
        'method': 'cash',
        'date': '2026-05-01T10:05:00.000Z',
      },
    ),
    (
      'stock_movements',
      'mov1',
      {
        'id': 'mov1',
        'productId': 'p1',
        'productName': 'Article pilote',
        'documentNumber': 'FAC-2026-9001',
        'direction': 'outbound',
        'quantity': 1,
        'warehouseId': 'main',
        'date': '2026-05-01T10:00:00.000Z',
      },
    ),
    (
      'audit_events',
      'audit1',
      {
        'id': 'audit1',
        'date': '2026-05-01T10:00:00.000Z',
        'actor': 'Pilot Tester',
        'action': 'sync_smoke',
        'target': 'pilot',
        'detail': 'Push smoke test',
      },
    ),
    (
      'settings',
      'document_sequences',
      {
        'key': 'document_sequences',
        'value': {'facture': 9002},
      },
    ),
  ];

  for (final row in rows) {
    await outboxService.enqueueMutation(
      entityType: row.$1,
      entityId: row.$2,
      operation: 'upsert',
      payload: row.$3,
    );
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
