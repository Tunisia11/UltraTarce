import '../../core/result/app_result.dart';

class StorageResult {
  const StorageResult({
    required this.bucket,
    required this.path,
    required this.fullPath,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
  });

  final String bucket;
  final String path;
  final String fullPath;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;

  @override
  String toString() => 'StorageResult($bucket, $path)';
}

typedef StorageOperationResult = AppResult<StorageResult>;

class FileRow {
  const FileRow({
    required this.id,
    required this.tenantId,
    required this.bucket,
    required this.path,
    this.type,
    this.linkedEntityType,
    this.linkedEntityId,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.syncedAt,
    this.version = 1,
    this.syncOriginDeviceId,
  });

  final String id;
  final String tenantId;
  final String bucket;
  final String path;
  final String? type;
  final String? linkedEntityType;
  final String? linkedEntityId;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final String? createdBy;
  final String? updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final DateTime? syncedAt;
  final int version;
  final String? syncOriginDeviceId;

  factory FileRow.fromMap(Map<String, dynamic> map) {
    return FileRow(
      id: map['id'] as String,
      tenantId: map['tenant_id'] as String,
      bucket: map['bucket'] as String,
      path: map['path'] as String,
      type: map['type'] as String?,
      linkedEntityType: map['linked_entity_type'] as String?,
      linkedEntityId: map['linked_entity_id'] as String?,
      fileName: map['file_name'] as String?,
      mimeType: map['mime_type'] as String?,
      sizeBytes: map['size_bytes'] as int?,
      createdBy: map['created_by'] as String?,
      updatedBy: map['updated_by'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      deletedAt: map['deleted_at'] != null
          ? DateTime.tryParse(map['deleted_at'].toString())
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.tryParse(map['synced_at'].toString())
          : null,
      version: map['version'] as int? ?? 1,
      syncOriginDeviceId: map['sync_origin_device_id'] as String?,
    );
  }
}
