import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/app/app_config.dart';
import 'package:ultra_trace/core/result/app_result.dart';
import 'package:ultra_trace/data/remote/remote_errors.dart';
import 'package:ultra_trace/data/remote/remote_tables.dart';
import 'package:ultra_trace/data/remote/repositories/remote_product_repository.dart';
import 'package:ultra_trace/data/remote/supabase_client_provider.dart';

void main() {
  test(
    'SupabaseClientProvider reports missing config without network access',
    () {
      final provider = SupabaseClientProvider(config: AppConfig.devBypass());

      final result = provider.requireClient();

      expect(result, isA<AppFailure>());
      expect(
        (result as AppFailure).error.code,
        RemoteErrorCodes.missingSupabaseConfig,
      );
    },
  );

  test(
    'remote repositories fail gracefully when Supabase is not configured',
    () async {
      final repository = RemoteProductRepository(
        SupabaseClientProvider(config: AppConfig.devBypass()),
      );

      final result = await repository.fetchProductsUpdatedSince(
        tenantId: 'tenant-id',
      );

      expect(result, isA<AppFailure<List<Map<String, dynamic>>>>());
      expect(
        (result as AppFailure<List<Map<String, dynamic>>>).error.code,
        RemoteErrorCodes.missingSupabaseConfig,
      );
    },
  );

  test(
    'remote repositories reject empty tenant ids before network access',
    () async {
      final repository = RemoteProductRepository(
        SupabaseClientProvider(config: AppConfig.devBypass()),
      );

      final fetchResult = await repository.fetchProductsUpdatedSince(
        tenantId: '  ',
      );
      final emptyUpsertResult = await repository.upsertProducts(
        tenantId: '',
        rows: const [],
      );
      final deleteResult = await repository.softDeleteProduct(
        tenantId: '',
        id: 'product-id',
      );

      expect(fetchResult, isA<AppFailure<List<Map<String, dynamic>>>>());
      expect(fetchResult.errorOrNull?.code, RemoteErrorCodes.missingTenantId);
      expect(emptyUpsertResult, isA<AppFailure<void>>());
      expect(
        emptyUpsertResult.errorOrNull?.code,
        RemoteErrorCodes.missingTenantId,
      );
      expect(deleteResult, isA<AppFailure<void>>());
      expect(deleteResult.errorOrNull?.code, RemoteErrorCodes.missingTenantId);
    },
  );

  test('Flutter code does not reference service role credentials', () {
    final forbiddenHits = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final content = file.readAsStringSync();
      if (content.contains('SUPABASE_SERVICE_ROLE_KEY') ||
          content.contains('service_role')) {
        forbiddenHits.add(file.path);
      }
    }

    expect(forbiddenHits, isEmpty);
  });

  test('normal inventory workflows are not wired to remote repositories', () {
    final forbiddenHits = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      if (file.path.startsWith('lib/data/remote/') ||
          file.path.contains('/lib/data/remote/')) {
        continue;
      }
      final content = file.readAsStringSync();
      if (content.contains("data/remote/repositories") ||
          content.contains('RemoteProductRepository') ||
          content.contains('RemotePartnerRepository') ||
          content.contains('RemoteDocumentRepository') ||
          content.contains('RemoteStockRepository') ||
          content.contains('RemoteCompanyRepository') ||
          content.contains('RemoteAuditRepository')) {
        forbiddenHits.add(file.path);
      }
    }

    expect(forbiddenHits, isEmpty);
  });

  test('Phase 9B incremental pull sync follows security and safety rules', () {
    final serviceRoleHits = <String>[];
    final unsafeDeleteHits = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final path = file.path;
      final content = file.readAsStringSync();

      // 1. No SUPABASE_SERVICE_ROLE_KEY/service_role usage in lib/
      if (content.contains('SUPABASE_SERVICE_ROLE_KEY') ||
          content.contains('service_role')) {
        serviceRoleHits.add(path);
      }

      // 2. No remote pull code directly disables RLS
      if (content.contains('disable_rls') || content.contains('bypass_rls')) {
        serviceRoleHits.add('$path (potential RLS bypass)');
      }

      // 3. No destructive full local wipe is triggered automatically by incremental pull.
      if (path.endsWith('local_cloud_import_service.dart')) {
        // Look for customStatement('DELETE FROM ...') without WHERE
        // Using \b word boundary to ensure we match the full table name
        // and don't match sub-words that might trigger a false positive
        // with the negative lookahead.
        final deleteRegex = RegExp(
          r'DELETE\s+FROM\s+\w+\b(?!\s+WHERE)',
          caseSensitive: false,
          multiLine: true,
        );
        if (deleteRegex.hasMatch(content)) {
          unsafeDeleteHits.add(path);
        }

        if (content.contains('delete(') &&
            !content.contains('where(') &&
            content.contains('.go()')) {
          unsafeDeleteHits.add('$path (potential unfiltered delete)');
        }
      }
    }

    expect(
      serviceRoleHits,
      isEmpty,
      reason: 'Security violation: service_role or RLS bypass detected',
    );
    expect(
      unsafeDeleteHits,
      isEmpty,
      reason: 'Safety violation: Unfiltered local delete detected in sync code',
    );
  });

  test('remote table names match Phase 6 business schema', () {
    expect(RemoteTables.products, 'products');
    expect(RemoteTables.documents, 'documents');
    expect(RemoteTables.stockMovements, 'stock_movements');
    expect(RemoteTables.syncConflicts, 'sync_conflicts');
  });
}
