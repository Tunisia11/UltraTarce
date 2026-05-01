import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../storage/app_storage.dart';
import '../../../storage/app_storage_keys.dart';

class OnboardingState {
  const OnboardingState({
    required this.guidedSetupDismissed,
    required this.onboardingCompleted,
    this.completedStep = 0,
  });

  factory OnboardingState.initial() => const OnboardingState(
    guidedSetupDismissed: false,
    onboardingCompleted: false,
  );

  final bool guidedSetupDismissed;
  final bool onboardingCompleted;
  final int completedStep;

  OnboardingState copyWith({
    bool? guidedSetupDismissed,
    bool? onboardingCompleted,
    int? completedStep,
  }) {
    return OnboardingState(
      guidedSetupDismissed: guidedSetupDismissed ?? this.guidedSetupDismissed,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      completedStep: completedStep ?? this.completedStep,
    );
  }
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingState.initial());

  void loadProgress() {
    emit(
      OnboardingState(
        guidedSetupDismissed:
            readPersistentValue(guidedSetupDismissedStorageKey) == 'true',
        onboardingCompleted:
            readPersistentValue(onboardingCompletedStorageKey) == 'true',
      ),
    );
  }

  void completeStep(int step) {
    emit(
      state.copyWith(
        completedStep: step > state.completedStep ? step : state.completedStep,
      ),
    );
  }

  void completeFirstProductStep() => completeStep(1);

  void completeFirstClientStep() => completeStep(2);

  void completeFirstSaleStep() => completeStep(3);

  void skipGuidance() {
    writePersistentValue(guidedSetupDismissedStorageKey, 'true');
    emit(state.copyWith(guidedSetupDismissed: true));
  }

  void resetGuidanceForTesting() {
    deletePersistentValue(guidedSetupDismissedStorageKey);
    emit(state.copyWith(guidedSetupDismissed: false, completedStep: 0));
  }
}
