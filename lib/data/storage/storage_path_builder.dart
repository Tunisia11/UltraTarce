class StoragePathBuilder {
  const StoragePathBuilder._();

  static String productImages(
    String tenantId,
    String productId,
    String fileName,
  ) {
    return '$tenantId/products/$productId/${_sanitize(fileName)}';
  }

  static String companyLogo(String tenantId, String fileName) {
    return '$tenantId/logos/${_sanitize(fileName)}';
  }

  static String documentPdf(
    String tenantId,
    String documentId,
    String fileName,
  ) {
    return '$tenantId/documents/$documentId/${_sanitize(fileName)}';
  }

  static String attachment(
    String tenantId,
    String entityType,
    String entityId,
    String fileName,
  ) {
    return '$tenantId/attachments/$entityType/$entityId/${_sanitize(fileName)}';
  }

  static String backup(String tenantId, String fileName) {
    return '$tenantId/backups/${_sanitize(fileName)}';
  }

  static String _sanitize(String fileName) {
    return fileName.replaceAll(RegExp(r'[^a-zA-Z0-9\.\-_]'), '_');
  }
}
