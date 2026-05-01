import 'package:flutter_test/flutter_test.dart';
import 'package:ultra_trace/features/inventory/application/onboarding_cubit.dart';

import 'inventory_application_test_helpers.dart';

void main() {
  configureInventoryApplicationTestStorage();

  test('OnboardingCubit completes guided steps', () {
    final cubit = OnboardingCubit();
    addTearDown(cubit.close);

    cubit.completeFirstProductStep();
    cubit.completeFirstClientStep();
    cubit.completeFirstSaleStep();

    expect(cubit.state.completedStep, 3);
  });

  test('OnboardingCubit skips guidance', () {
    final cubit = OnboardingCubit();
    addTearDown(cubit.close);

    cubit.skipGuidance();
    cubit.loadProgress();

    expect(cubit.state.guidedSetupDismissed, isTrue);
  });
}
