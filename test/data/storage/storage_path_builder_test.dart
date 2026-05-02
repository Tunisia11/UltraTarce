import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/data/storage/storage_path_builder.dart';

void main() {
  group('StoragePathBuilder', () {
    const tenantId = 'tenant-123';

    test('productImages returns correct path structure', () {
      final path = StoragePathBuilder.productImages(
        tenantId,
        'prod-456',
        'image.jpg',
      );
      expect(path, 'tenant-123/products/prod-456/image.jpg');
    });

    test('companyLogo returns correct path structure', () {
      final path = StoragePathBuilder.companyLogo(tenantId, 'logo.png');
      expect(path, 'tenant-123/logos/logo.png');
    });

    test('documentPdf returns correct path structure', () {
      final path = StoragePathBuilder.documentPdf(
        tenantId,
        'doc-789',
        'invoice.pdf',
      );
      expect(path, 'tenant-123/documents/doc-789/invoice.pdf');
    });

    test('attachment returns correct path structure', () {
      final path = StoragePathBuilder.attachment(
        tenantId,
        'tasks',
        'task-1',
        'file.txt',
      );
      expect(path, 'tenant-123/attachments/tasks/task-1/file.txt');
    });

    test('backup returns correct path structure', () {
      final path = StoragePathBuilder.backup(tenantId, 'backup.zip');
      expect(path, 'tenant-123/backups/backup.zip');
    });

    test('sanitizes file names', () {
      final path = StoragePathBuilder.productImages(
        tenantId,
        'p1',
        'my image @ 2! #.jpg',
      );
      expect(path, 'tenant-123/products/p1/my_image___2___.jpg');
    });
  });
}
