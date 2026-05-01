import 'dart:async';

import 'package:flutter/material.dart';

import '../models/store_setup_data.dart';
import 'animated_typing_rich_text.dart';
import 'setup_intro_question_text.dart';
import 'setup_step_map.dart';
import 'store_setup_flow.dart';
import 'store_setup_layout.dart';

/// Page 2 controller: owns setup state and step progression.
///
/// Phase 1 expands onboarding into a real company setup so the app can create
/// a trustworthy local business profile before the operator reaches the main UI.
class StoreSetupPage extends StatefulWidget {
  const StoreSetupPage({
    super.key,
    required this.active,
    required this.initialSetupData,
    required this.onCompletionChanged,
    required this.onSetupChanged,
  });

  final bool active;
  final StoreSetupData initialSetupData;
  final ValueChanged<bool> onCompletionChanged;
  final ValueChanged<StoreSetupData> onSetupChanged;

  @override
  State<StoreSetupPage> createState() => _StoreSetupPageState();
}

class _StoreSetupPageState extends State<StoreSetupPage> {
  late final TextEditingController _storeNameController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _depotNameController;
  late final TextEditingController _depotCodeController;
  late final TextEditingController _depotCityController;
  late final TextEditingController _depotAddressController;

  String _commerceType = 'Électronique';
  String _priceMode = 'Prix TTC';
  String _confirmedIdentityFingerprint = '';
  String _confirmedCommerceType = '';
  String _confirmedDepotFingerprint = '';
  String _confirmedPriceMode = '';
  bool _timbreFiscal = true;
  bool _formVisible = false;
  int _activeSetupStep = 1;
  Timer? _formRevealTimer;

  String get _identityFingerprint => [
    _storeNameController.text.trim(),
    _taxIdController.text.trim(),
    _addressController.text.trim(),
    _cityController.text.trim(),
    _phoneController.text.trim(),
    _emailController.text.trim().toLowerCase(),
  ].join('|');

  String get _depotFingerprint => [
    _depotNameController.text.trim(),
    _depotCodeController.text.trim().toUpperCase(),
    _depotCityController.text.trim(),
    _depotAddressController.text.trim(),
  ].join('|');

  bool get _identityComplete =>
      _storeNameController.text.trim().length >= 2 &&
      _taxIdController.text.trim().length >= 3 &&
      _addressController.text.trim().length >= 4 &&
      _cityController.text.trim().length >= 2 &&
      _phoneController.text.trim().length >= 6 &&
      _emailController.text.trim().contains('@');

  bool get _identityReady =>
      _identityComplete &&
      _confirmedIdentityFingerprint.isNotEmpty &&
      _confirmedIdentityFingerprint == _identityFingerprint;

  bool get _depotComplete =>
      _depotNameController.text.trim().length >= 2 &&
      _depotCityController.text.trim().length >= 2;

  bool get _depotReady =>
      _depotComplete &&
      _confirmedDepotFingerprint.isNotEmpty &&
      _confirmedDepotFingerprint == _depotFingerprint;

  bool get _commerceReady =>
      _confirmedCommerceType.isNotEmpty &&
      _confirmedCommerceType == _commerceType;

  bool get _priceReady =>
      _confirmedPriceMode.isNotEmpty && _confirmedPriceMode == _priceMode;

  bool get _showCommerce => _identityReady;
  bool get _showDepot => _showCommerce && _commerceReady;
  bool get _showPriceMode => _showDepot && _depotReady;
  bool get _showTimbreFiscal => _showPriceMode && _priceReady;

  int get _maxUnlockedStep {
    if (!_identityReady) return 1;
    if (!_commerceReady) return 2;
    if (!_depotReady) return 3;
    if (!_priceReady) return 4;
    return 5;
  }

  int get _currentSetupStep =>
      _activeSetupStep > _maxUnlockedStep ? _maxUnlockedStep : _activeSetupStep;

  Set<int> get _completedSteps => {
    if (_identityReady) 1,
    if (_commerceReady) 2,
    if (_depotReady) 3,
    if (_priceReady) 4,
    if (_showTimbreFiscal) 5,
  };

  bool get _canGoToNextSetupStep =>
      _currentSetupStep < _maxUnlockedStep &&
      _completedSteps.contains(_currentSetupStep);

  StoreSetupData get _setupData => StoreSetupData(
    storeName: _storeNameController.text.trim(),
    taxId: _taxIdController.text.trim(),
    address: _addressController.text.trim(),
    city: _cityController.text.trim(),
    phone: _phoneController.text.trim(),
    email: _emailController.text.trim(),
    commerceType: _commerceType,
    depotName: _depotNameController.text.trim(),
    depotCode: _depotCodeController.text.trim(),
    depotCity: _depotCityController.text.trim(),
    depotAddress: _depotAddressController.text.trim(),
    priceMode: _priceMode,
    timbreFiscal: _timbreFiscal,
  );

  String get _questionKey {
    if (!_formVisible) return 'company-identity';
    return switch (_currentSetupStep) {
      2 => 'commerce-type',
      3 => 'warehouse-setup',
      4 => 'price-mode',
      5 => 'timbre-fiscal',
      _ => 'company-identity',
    };
  }

  List<TypingTextSegment> get _questionSegments {
    return switch (_questionKey) {
      'commerce-type' => SetupIntroQuestionText.commerceTypeSegments,
      'warehouse-setup' => SetupIntroQuestionText.warehouseSegments,
      'price-mode' => SetupIntroQuestionText.priceModeSegments,
      'timbre-fiscal' => SetupIntroQuestionText.timbreFiscalSegments,
      _ => SetupIntroQuestionText.companyIdentitySegments,
    };
  }

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(
      text: widget.initialSetupData.storeName,
    );
    _taxIdController = TextEditingController(
      text: widget.initialSetupData.taxId,
    );
    _addressController = TextEditingController(
      text: widget.initialSetupData.address,
    );
    _cityController = TextEditingController(text: widget.initialSetupData.city);
    _phoneController = TextEditingController(
      text: widget.initialSetupData.phone,
    );
    _emailController = TextEditingController(
      text: widget.initialSetupData.email,
    );
    _depotNameController = TextEditingController(
      text: widget.initialSetupData.depotName,
    );
    _depotCodeController = TextEditingController(
      text: widget.initialSetupData.depotCode,
    );
    _depotCityController = TextEditingController(
      text: widget.initialSetupData.depotCity,
    );
    _depotAddressController = TextEditingController(
      text: widget.initialSetupData.depotAddress,
    );
    _commerceType = widget.initialSetupData.commerceType;
    _priceMode = widget.initialSetupData.priceMode;
    _timbreFiscal = widget.initialSetupData.timbreFiscal;

    for (final controller in _allControllers) {
      controller.addListener(_syncCompletion);
    }

    _bootstrapFromInitialSetup();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifySetupChanged());
  }

  List<TextEditingController> get _allControllers => [
    _storeNameController,
    _taxIdController,
    _addressController,
    _cityController,
    _phoneController,
    _emailController,
    _depotNameController,
    _depotCodeController,
    _depotCityController,
    _depotAddressController,
  ];

  void _bootstrapFromInitialSetup() {
    if (_identityComplete) {
      _confirmedIdentityFingerprint = _identityFingerprint;
    }
    if (_showCommerce) {
      _confirmedCommerceType = _commerceType;
    }
    if (_depotComplete && _confirmedCommerceType.isNotEmpty) {
      _confirmedDepotFingerprint = _depotFingerprint;
    }
    if (_showPriceMode && _priceMode.trim().isNotEmpty) {
      _confirmedPriceMode = _priceMode;
    }
    _activeSetupStep = switch (_maxUnlockedStep) {
      5 => 5,
      4 => 4,
      3 => 3,
      2 => 2,
      _ => 1,
    };
  }

  @override
  void dispose() {
    _formRevealTimer?.cancel();
    for (final controller in _allControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncCompletion() {
    setState(_clampActiveStepToUnlocked);
    _notifySetupChanged();
  }

  void _confirmIdentity() {
    if (!_identityComplete) return;
    setState(() {
      _confirmedIdentityFingerprint = _identityFingerprint;
      _activeSetupStep = 2;
    });
    _notifySetupChanged();
  }

  void _confirmCommerceType() {
    setState(() {
      _confirmedCommerceType = _commerceType;
      _activeSetupStep = 3;
    });
    _notifySetupChanged();
  }

  void _confirmDepot() {
    if (!_depotComplete) return;
    setState(() {
      _confirmedDepotFingerprint = _depotFingerprint;
      _activeSetupStep = 4;
    });
    _notifySetupChanged();
  }

  void _selectCommerceType(String value) {
    setState(() {
      _commerceType = value;
      _clampActiveStepToUnlocked();
    });
    _notifySetupChanged();
  }

  void _selectPriceMode(String value) {
    setState(() {
      _priceMode = value;
      _clampActiveStepToUnlocked();
    });
    _notifySetupChanged();
  }

  void _confirmPriceMode() {
    setState(() {
      _confirmedPriceMode = _priceMode;
      _activeSetupStep = 5;
    });
    _notifySetupChanged();
  }

  void _setTimbreFiscal(bool value) {
    setState(() => _timbreFiscal = value);
    _notifySetupChanged();
  }

  void _notifySetupChanged() {
    widget.onSetupChanged(_setupData);
    widget.onCompletionChanged(_showTimbreFiscal);
  }

  void _showFormAfterIntro() {
    if (_formVisible || _formRevealTimer != null) return;

    _formRevealTimer = Timer(const Duration(milliseconds: 500), () {
      _formRevealTimer = null;
      if (!mounted) return;
      setState(() => _formVisible = true);
    });
  }

  void _selectSetupStep(int step) {
    setState(() {
      _activeSetupStep = step.clamp(1, _maxUnlockedStep);
    });
  }

  void _goToPreviousSetupStep() {
    if (_currentSetupStep <= 1) return;
    _selectSetupStep(_currentSetupStep - 1);
  }

  void _goToNextSetupStep() {
    if (!_canGoToNextSetupStep) return;
    _selectSetupStep(_currentSetupStep + 1);
  }

  void _clampActiveStepToUnlocked() {
    if (_activeSetupStep > _maxUnlockedStep) {
      _activeSetupStep = _maxUnlockedStep;
    }
    if (_activeSetupStep < 1) {
      _activeSetupStep = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreSetupLayout(
      topRoadmap: _formVisible
          ? SetupStepMap(
              activeStep: _currentSetupStep,
              maxUnlockedStep: _maxUnlockedStep,
              completedSteps: _completedSteps,
              onStepSelected: _selectSetupStep,
            )
          : null,
      content: StoreSetupFlow(
        active: widget.active,
        questionKey: _questionKey,
        questionSegments: _questionSegments,
        formVisible: _formVisible,
        activeStep: _currentSetupStep,
        storeNameController: _storeNameController,
        taxIdController: _taxIdController,
        addressController: _addressController,
        cityController: _cityController,
        phoneController: _phoneController,
        emailController: _emailController,
        depotNameController: _depotNameController,
        depotCodeController: _depotCodeController,
        depotCityController: _depotCityController,
        depotAddressController: _depotAddressController,
        commerceType: _commerceType,
        priceMode: _priceMode,
        timbreFiscal: _timbreFiscal,
        identityComplete: _identityComplete,
        depotComplete: _depotComplete,
        showTimbreFiscal: _showTimbreFiscal,
        onIntroFinished: _showFormAfterIntro,
        onCommerceTypeChanged: _selectCommerceType,
        onPriceModeChanged: _selectPriceMode,
        onTimbreFiscalChanged: _setTimbreFiscal,
        onIdentityDone: _confirmIdentity,
        onCommerceTypeDone: _confirmCommerceType,
        onDepotDone: _confirmDepot,
        onPriceModeDone: _confirmPriceMode,
        canGoStepBack: _currentSetupStep > 1,
        canGoStepNext: _canGoToNextSetupStep,
        onStepBack: _goToPreviousSetupStep,
        onStepNext: _goToNextSetupStep,
      ),
    );
  }
}
