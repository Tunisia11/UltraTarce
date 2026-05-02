import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/presentation/widgets/product_image.dart';

void main() {
  testWidgets('ProductImage shows placeholder for empty value', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProductImage(url: '')));

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('ProductImage renders valid data:image base64', (tester) async {
    // Small 1x1 transparent pixel in base64
    const base64Image =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
    const dataUrl = 'data:image/png;base64,$base64Image';

    await tester.pumpWidget(
      const MaterialApp(home: ProductImage(url: dataUrl)),
    );

    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.image, isA<MemoryImage>());
  });

  testWidgets('ProductImage renders http URL via Image.network', (
    tester,
  ) async {
    const url = 'https://example.com/image.png';

    await tester.pumpWidget(const MaterialApp(home: ProductImage(url: url)));

    expect(find.byType(Image), findsOneWidget);
    final imageWidget = tester.widget<Image>(find.byType(Image));
    expect(imageWidget.image, isA<NetworkImage>());
  });
}
