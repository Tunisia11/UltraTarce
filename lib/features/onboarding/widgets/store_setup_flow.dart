import 'package:flutter/material.dart';

import 'animated_typing_rich_text.dart';
import 'setup_form_panel.dart';
import 'setup_intro_question_text.dart';

/// Visual flow for onboarding page 2.
///
/// This file assembles the big typed question and current setup form. Keep copy
/// changes in `SetupIntroQuestionText`, field changes in `SetupFormPanel`, and
/// responsive placement in `StoreSetupLayout`.
class StoreSetupFlow extends StatelessWidget {
  const StoreSetupFlow({
    super.key,
    required this.active,
    required this.questionKey,
    required this.questionSegments,
    required this.formVisible,
    required this.activeStep,
    required this.storeNameController,
    required this.taxIdController,
    required this.addressController,
    required this.cityController,
    required this.phoneController,
    required this.emailController,
    required this.depotNameController,
    required this.depotCodeController,
    required this.depotCityController,
    required this.depotAddressController,
    required this.commerceType,
    required this.priceMode,
    required this.timbreFiscal,
    required this.identityComplete,
    required this.depotComplete,
    required this.showTimbreFiscal,
    required this.onIntroFinished,
    required this.onCommerceTypeChanged,
    required this.onPriceModeChanged,
    required this.onTimbreFiscalChanged,
    required this.onIdentityDone,
    required this.onCommerceTypeDone,
    required this.onDepotDone,
    required this.onPriceModeDone,
    required this.canGoStepBack,
    required this.canGoStepNext,
    required this.onStepBack,
    required this.onStepNext,
  });

  final bool active;
  final String questionKey;
  final List<TypingTextSegment> questionSegments;
  final bool formVisible;
  final int activeStep;
  final TextEditingController storeNameController;
  final TextEditingController taxIdController;
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController depotNameController;
  final TextEditingController depotCodeController;
  final TextEditingController depotCityController;
  final TextEditingController depotAddressController;
  final String commerceType;
  final String priceMode;
  final bool timbreFiscal;
  final bool identityComplete;
  final bool depotComplete;
  final bool showTimbreFiscal;
  final VoidCallback onIntroFinished;
  final ValueChanged<String> onCommerceTypeChanged;
  final ValueChanged<String> onPriceModeChanged;
  final ValueChanged<bool> onTimbreFiscalChanged;
  final VoidCallback onIdentityDone;
  final VoidCallback onCommerceTypeDone;
  final VoidCallback onDepotDone;
  final VoidCallback onPriceModeDone;
  final bool canGoStepBack;
  final bool canGoStepNext;
  final VoidCallback onStepBack;
  final VoidCallback onStepNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetupIntroQuestionText(
          key: const ValueKey('setup-intro-question'),
          active: active,
          questionKey: questionKey,
          segments: questionSegments,
          onFinished: onIntroFinished,
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: formVisible
              ? SetupFormPanel(
                  key: const ValueKey('setup-form'),
                  storeNameController: storeNameController,
                  taxIdController: taxIdController,
                  addressController: addressController,
                  cityController: cityController,
                  phoneController: phoneController,
                  emailController: emailController,
                  depotNameController: depotNameController,
                  depotCodeController: depotCodeController,
                  depotCityController: depotCityController,
                  depotAddressController: depotAddressController,
                  commerceType: commerceType,
                  priceMode: priceMode,
                  timbreFiscal: timbreFiscal,
                  identityComplete: identityComplete,
                  depotComplete: depotComplete,
                  activeStep: activeStep,
                  showTimbreFiscal: showTimbreFiscal,
                  onCommerceTypeChanged: onCommerceTypeChanged,
                  onPriceModeChanged: onPriceModeChanged,
                  onTimbreFiscalChanged: onTimbreFiscalChanged,
                  onIdentityDone: onIdentityDone,
                  onCommerceTypeDone: onCommerceTypeDone,
                  onDepotDone: onDepotDone,
                  onPriceModeDone: onPriceModeDone,
                  canGoStepBack: canGoStepBack,
                  canGoStepNext: canGoStepNext,
                  onStepBack: onStepBack,
                  onStepNext: onStepNext,
                )
              : const SizedBox.shrink(key: ValueKey('setup-form-hidden')),
        ),
      ],
    );
  }
}
