import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/widgets/guided_focus_overlay.dart';

void main() {
  testWidgets('Tarek overlay target missing does not crash', (tester) async {
    final missingTargetKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              const SizedBox.expand(),
              GuidedFocusOverlay(
                visible: true,
                currentIndex: 0,
                steps: [
                  GuidedFocusStep(
                    title: 'Commençons par ajouter votre premier produit',
                    message:
                        'Le widget ciblé est absent, mais le guide reste utilisable.',
                    progressLabel: 'Étape 1 sur 1',
                    primaryLabel: 'Faire maintenant',
                    targetKey: missingTargetKey,
                  ),
                ],
                onNext: () {},
                onPrevious: () {},
                onSkip: () {},
                onPrimaryAction: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Passer'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Faire maintenant'), findsOneWidget);
  });
}
