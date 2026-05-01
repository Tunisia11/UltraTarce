import 'package:flutter/material.dart';

import '../models/store_setup_data.dart';
import 'onboarding_completion_stage.dart';
import 'store_setup_page.dart';
import 'welcome_mascot_stage.dart';

/// Chooses which onboarding page body to show.
///
/// Page 1: welcome/mascot intro.
/// Page 2: store setup form.
/// Page 3: celebration with the final start message.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.index,
    required this.isActive,
    required this.initialSetupData,
    required this.onSetupCompletionChanged,
    required this.onSetupChanged,
    required this.onNext,
  });

  final int index;
  final bool isActive;
  final StoreSetupData initialSetupData;
  final ValueChanged<bool> onSetupCompletionChanged;
  final ValueChanged<StoreSetupData> onSetupChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    if (index == 1) {
      return StoreSetupPage(
        active: isActive,
        initialSetupData: initialSetupData,
        onCompletionChanged: onSetupCompletionChanged,
        onSetupChanged: onSetupChanged,
      );
    }

    if (index == 2) {
      return const OnboardingCompletionStage();
    }

    return WelcomeMascotStage(onNext: onNext);
  }
}
