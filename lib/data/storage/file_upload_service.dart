import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/result/app_result.dart';
import 'file_metadata_repository.dart';
import 'storage_path_builder.dart';
import 'storage_result.dart';

class FileUploadService {
  FileUploadService({
    required SupabaseClient? supabase,
    required FileMetadataRepository metadataRepository,
  }) : _supabase = supabase,
       _metadataRepository = metadataRepository;

  final SupabaseClient? _supabase;
  final FileMetadataRepository _metadataRepository;

  bool get isOnline =>
      _supabase != null && _supabase.auth.currentSession != null;

  Future<StorageOperationResult> uploadProductImage({
    required String tenantId,
    required String productId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = StoragePathBuilder.productImages(
      tenantId,
      productId,
      fileName,
    );
    return _upload(
      bucket: 'product-images',
      path: path,
      bytes: bytes,
      tenantId: tenantId,
      entityType: 'products',
      entityId: productId,
      purpose: 'product_image',
    );
  }

  Future<StorageOperationResult> uploadCompanyLogo({
    required String tenantId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = StoragePathBuilder.companyLogo(tenantId, fileName);
    return _upload(
      bucket: 'company-logos',
      path: path,
      bytes: bytes,
      tenantId: tenantId,
      entityType: 'companies',
      entityId: tenantId,
      purpose: 'company_logo',
    );
  }

  Future<StorageOperationResult> uploadDocumentPdf({
    required String tenantId,
    required String documentId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = StoragePathBuilder.documentPdf(tenantId, documentId, fileName);
    return _upload(
      bucket: 'document-pdfs',
      path: path,
      bytes: bytes,
      tenantId: tenantId,
      entityType: 'documents',
      entityId: documentId,
      purpose: 'document_pdf',
    );
  }

  Future<StorageOperationResult> _upload({
    required String bucket,
    required String path,
    required Uint8List bytes,
    required String tenantId,
    String? entityType,
    String? entityId,
    String? purpose,
  }) async {
    final size = bytes.length;
    final mimeType = _resolveMimeType(path);

    final storageResult = StorageResult(
      bucket: bucket,
      path: path,
      fullPath: '$bucket/$path',
      fileName: path.split('/').last,
      mimeType: mimeType,
      sizeBytes: size,
    );

    // 1. Save local metadata always (offline first)
    await _metadataRepository.saveMetadata(
      tenantId: tenantId,
      storage: storageResult,
      entityType: entityType,
      entityId: entityId,
      purpose: purpose,
      userId: _supabase?.auth.currentUser?.id,
    );

    // 2. If online, upload to Supabase
    if (isOnline) {
      try {
        await _supabase!.storage
            .from(bucket)
            .uploadBinary(
              path,
              bytes,
              fileOptions: FileOptions(contentType: mimeType, upsert: true),
            );
        return AppSuccess(storageResult);
      } catch (e) {
        return AppFailure(
          AppError(
            code: 'upload_failed',
            message: 'Erreur lors de l\'envoi vers le cloud: $e',
            cause: e,
          ),
        );
      }
    }

    // 3. If offline, return success with local-only status
    // In a real production app, we would mark the metadata as 'pending_upload'
    return AppSuccess(storageResult);
  }

  String _resolveMimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
