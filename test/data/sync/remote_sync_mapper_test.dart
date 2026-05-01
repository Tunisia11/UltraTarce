import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/remote/remote_errors.dart';
import 'package:ultra_trace/data/remote/remote_tables.dart';
import 'package:ultra_trace/data/sync/remote_sync_mapper.dart';
import 'package:ultra_trace/data/sync/sync_outbox_repository.dart';

void main() {
  const mapper = RemoteSyncMapper();
  const tenantId = '11111111-1111-4111-8111-111111111111';

  test('product outbox maps to products payload', () {
    final result = mapper.map(
      _mutation(
        tenantId: tenantId,
        entityType: 'products',
        entityId: 'p1',
        payload: {
          'id': 'p1',
          'name': 'Scanner',
          'sku': 'SCN-1',
          'saleHt': 100,
          'purchaseHt': 60,
          'tvaRate': 'rate19',
          'minStock': 3,
          'active': true,
        },
      ),
    );

    expect(result.isSuccess, isTrue);
    final write = result.valueOrNull!;
    expect(write.table, RemoteTables.products);
    expect(write.payload['tenant_id'], tenantId);
    expect(write.payload['name'], 'Scanner');
    expect(write.payload['sale_price_ht'], 100);
    expect(write.payload['tva_rate'], 19);
    expect(write.payload['id'], matches(_uuidPattern));
  });

  test('partner maps to partners payload', () {
    final write = mapper
        .map(
          _mutation(
            tenantId: tenantId,
            entityType: 'partners',
            entityId: 'client-1',
            payload: {
              'id': 'client-1',
              'type': 'client',
              'name': 'Client Pro',
              'taxId': 'MF123',
              'active': true,
            },
          ),
        )
        .valueOrNull!;

    expect(write.table, RemoteTables.partners);
    expect(write.payload['type'], 'client');
    expect(write.payload['tax_id'], 'MF123');
  });

  test('document maps to documents payload with totals', () {
    final write = mapper
        .map(
          _mutation(
            tenantId: tenantId,
            entityType: 'documents',
            entityId: 'doc-1',
            payload: {
              'id': 'doc-1',
              'type': 'facture',
              'status': 'validated',
              'number': 'FAC-2026-0007',
              'partnerId': 'client-1',
              'date': '2026-05-01T10:00:00.000Z',
              'applyTimbreFiscal': true,
              'timbreFiscalAmount': 1,
              'lines': [
                {
                  'productId': 'p1',
                  'label': 'Scanner',
                  'quantity': 2,
                  'unitHt': 100,
                  'discountRate': 10,
                  'tvaRate': 'rate19',
                },
              ],
              'payments': [
                {'amount': 50},
              ],
            },
          ),
        )
        .valueOrNull!;

    expect(write.table, RemoteTables.documents);
    expect(write.payload['sequence'], 7);
    expect(write.payload['subtotal_ht'], 180);
    expect(write.payload['total_discount'], 20);
    expect(write.payload['total_tva'], closeTo(34.2, .001));
    expect(write.payload['timbre_fiscal'], 1);
    expect(write.payload['paid_amount'], 50);
    expect(write.payload['remaining_amount'], closeTo(165.2, .001));
  });

  test('payment maps to payments payload with document dependency', () {
    final write = mapper
        .map(
          _mutation(
            tenantId: tenantId,
            entityType: 'payments',
            entityId: 'pay-1',
            payload: {
              'id': 'pay-1',
              'documentId': 'doc-1',
              'amount': 25,
              'method': 'cash',
              'date': '2026-05-01T10:30:00.000Z',
            },
          ),
        )
        .valueOrNull!;

    expect(write.table, RemoteTables.payments);
    expect(write.payload['amount'], 25);
    expect(write.dependencies.single.table, RemoteTables.documents);
  });

  test('stock movement maps to stock_movements payload', () {
    final write = mapper
        .map(
          _mutation(
            tenantId: tenantId,
            entityType: 'stock_movements',
            entityId: 'movement-1',
            payload: {
              'productId': 'p1',
              'warehouseId': 'main',
              'direction': 'outbound',
              'quantity': 4,
              'documentNumber': 'FAC-1',
            },
          ),
        )
        .valueOrNull!;

    expect(write.table, RemoteTables.stockMovements);
    expect(write.payload['quantity_delta'], -4);
    expect(write.dependencies, hasLength(2));
  });

  test('missing tenant is rejected', () {
    final result = mapper.map(
      _mutation(
        tenantId: '',
        entityType: 'products',
        entityId: 'p1',
        payload: {'id': 'p1', 'name': 'Produit'},
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.code, RemoteErrorCodes.missingTenantId);
  });
}

SyncOutboxMutation _mutation({
  required String tenantId,
  required String entityType,
  required String entityId,
  required Map<String, dynamic> payload,
  String operation = 'upsert',
}) {
  final now = DateTime.utc(2026, 5);
  return SyncOutboxMutation(
    id: '$tenantId|$entityType|$entityId|$operation',
    tenantId: tenantId,
    entityType: entityType,
    entityId: entityId,
    operation: operation,
    payloadJson: jsonEncode({
      'tenantId': tenantId,
      'entityType': entityType,
      'entityId': entityId,
      'operation': operation,
      'deviceId': 'device-test',
      'payload': payload,
    }),
    createdAt: now,
    updatedAt: now,
    attempts: 0,
    status: 'pending',
    deviceId: 'device-test',
    idempotencyKey: '$tenantId|$entityType|$entityId|$operation',
  );
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
