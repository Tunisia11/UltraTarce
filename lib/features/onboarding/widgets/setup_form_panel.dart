import 'package:flutter/material.dart';

import '../../../app/app_colors.dart';
import 'setup_commerce_type_buttons.dart';
import 'setup_done_button.dart';
import 'setup_fiscal_toggle.dart';
import 'setup_price_mode_radios.dart';
import 'setup_step_card.dart';
import 'setup_step_navigation.dart';

/// The 24 Tunisian governorates (wilayas) in standard French spelling,
/// ordered by official code (1 to 24).
const List<String> kTunisianGovernorates = [
  'Tunis',
  'Ariana',
  'Ben Arous',
  'Manouba',
  'Nabeul',
  'Zaghouan',
  'Bizerte',
  'Beja',
  'Jendouba',
  'Le Kef',
  'Siliana',
  'Sousse',
  'Monastir',
  'Mahdia',
  'Sfax',
  'Kairouan',
  'Kasserine',
  'Sidi Bouzid',
  'Gabes',
  'Medenine',
  'Tataouine',
  'Gafsa',
  'Tozeur',
  'Kebili',
];

/// The left-side form on onboarding page 2.
///
/// The parent decides which step is active. Edit labels/placeholders here if
/// you want to change the questions.
class SetupFormPanel extends StatefulWidget {
  const SetupFormPanel({
    super.key,
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
    required this.activeStep,
    required this.showTimbreFiscal,
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
  final int activeStep;
  final bool showTimbreFiscal;
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
  State<SetupFormPanel> createState() => _SetupFormPanelState();
}

class _SetupFormPanelState extends State<SetupFormPanel> {
  // Local state for the two city dropdowns so DropdownButtonFormField can
  // display the currently selected value without reading the controller.
  String? _cityValue;
  String? _depotCityValue;

  @override
  void initState() {
    super.initState();
    // Restore a previously saved value only when it matches a known governorate.
    final city = widget.cityController.text.trim();
    _cityValue = kTunisianGovernorates.contains(city) ? city : null;

    final depotCity = widget.depotCityController.text.trim();
    _depotCityValue = kTunisianGovernorates.contains(depotCity)
        ? depotCity
        : null;
  }

  void _onCityChanged(String? value) {
    if (value == null) return;
    setState(() => _cityValue = value);
    widget.cityController.text = value;
  }

  void _onDepotCityChanged(String? value) {
    if (value == null) return;
    setState(() => _depotCityValue = value);
    widget.depotCityController.text = value;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _activeStepContent(),
          SetupStepNavigation(
            canGoBack: widget.canGoStepBack,
            canGoNext: widget.canGoStepNext,
            onBack: widget.onStepBack,
            onNext: widget.onStepNext,
          ),
          if (!widget.showTimbreFiscal) ...[
            const SizedBox(height: 4),
            const Text(
              "Completez l'etape affichee pour debloquer la suivante.",
              style: TextStyle(
                color: AppColors.subtle,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _activeStepContent() {
    return switch (widget.activeStep) {
      2 => SetupStepCard(
        step: '02',
        title: 'Type de commerce',
        subtitle: "Choisissez l'activite principale, puis validez.",
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SetupCommerceTypeButtons(
              selectedType: widget.commerceType,
              onChanged: widget.onCommerceTypeChanged,
            ),
            const SizedBox(height: 6),
            SetupDoneButton(
              label: 'Valider',
              onPressed: widget.onCommerceTypeDone,
            ),
          ],
        ),
      ),
      3 => SetupStepCard(
        step: '03',
        title: 'Premier depot',
        subtitle:
            'Nom et ville sont requis. Code et adresse restent optionnels.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _setupField(
                  width: 260,
                  controller: widget.depotNameController,
                  label: 'Nom du depot',
                  icon: Icons.warehouse_outlined,
                ),
                _setupField(
                  width: 180,
                  controller: widget.depotCodeController,
                  label: 'Code depot',
                  icon: Icons.tag_outlined,
                ),
                _setupCityDropdown(
                  width: 220,
                  value: _depotCityValue,
                  label: 'Ville depot',
                  onChanged: _onDepotCityChanged,
                ),
                _setupField(
                  width: 380,
                  controller: widget.depotAddressController,
                  label: 'Adresse depot',
                  icon: Icons.pin_drop_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SetupDoneButton(
              label: 'Valider',
              enabled: widget.depotComplete,
              onPressed: widget.onDepotDone,
            ),
          ],
        ),
      ),
      4 => SetupStepCard(
        step: '04',
        title: 'Mode de prix',
        subtitle: 'Prix TTC est recommande. Touchez votre choix, puis validez.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SetupPriceModeRadios(
              selectedMode: widget.priceMode,
              onChanged: widget.onPriceModeChanged,
            ),
            const SizedBox(height: 6),
            SetupDoneButton(
              label: 'Valider',
              onPressed: widget.onPriceModeDone,
            ),
          ],
        ),
      ),
      5 => SetupStepCard(
        step: '05',
        title: 'Timbre fiscal',
        subtitle: 'Vous pourrez ajuster ce choix plus tard dans Fiscalite.',
        child: SetupFiscalToggle(
          value: widget.timbreFiscal,
          onChanged: widget.onTimbreFiscalChanged,
        ),
      ),
      _ => SetupStepCard(
        step: '01',
        title: 'Identite societe',
        subtitle: 'Ces informations serviront des vos premiers documents.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                _setupField(
                  width: 300,
                  controller: widget.storeNameController,
                  label: 'Nom societe / magasin',
                  icon: Icons.storefront_outlined,
                  autofocus: true,
                ),
                _setupField(
                  width: 260,
                  controller: widget.taxIdController,
                  label: 'Matricule fiscal',
                  icon: Icons.badge_outlined,
                ),
                _setupField(
                  width: 420,
                  controller: widget.addressController,
                  label: 'Adresse',
                  icon: Icons.place_outlined,
                ),
                _setupCityDropdown(
                  width: 220,
                  value: _cityValue,
                  label: 'Ville',
                  onChanged: _onCityChanged,
                ),
                _setupField(
                  width: 220,
                  controller: widget.phoneController,
                  label: 'Telephone',
                  icon: Icons.phone_outlined,
                ),
                _setupField(
                  width: 320,
                  controller: widget.emailController,
                  label: 'Email',
                  icon: Icons.alternate_email_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SetupDoneButton(
              label: 'Valider',
              enabled: widget.identityComplete,
              onPressed: widget.onIdentityDone,
            ),
          ],
        ),
      ),
    };
  }

  Widget _setupField({
    required double width,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool autofocus = false,
  }) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.muted),
        ),
      ),
    );
  }

  /// A dropdown that lists all 24 Tunisian governorates, styled to match
  /// [_setupField]. Updates the parent's [TextEditingController] on selection
  /// so fingerprint/completion logic in the parent works without any changes.
  Widget _setupCityDropdown({
    required double width,
    required String? value,
    required String label,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: value,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.muted,
        ),
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.location_city_outlined,
            color: AppColors.muted,
          ),
        ),
        menuMaxHeight: 320,
        items: kTunisianGovernorates
            .map(
              (gov) => DropdownMenuItem<String>(value: gov, child: Text(gov)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
