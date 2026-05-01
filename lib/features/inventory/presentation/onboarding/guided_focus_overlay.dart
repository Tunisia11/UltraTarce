part of '../inventory_shell_page.dart';

extension _InventoryGuidedFocusOverlayFlow on _InventoryHomePageState {
  int _firstIncompleteGuideIndex() {
    if (!_hasFirstProduct) return 0;
    if (!_hasFirstClient) return 1;
    if (!_hasFirstSale) return 2;
    return 2;
  }

  void _syncGuidedProgressAfterMutation() {
    _ensureSelections();
    if (_hasFirstProduct) _onboardingCubit.completeFirstProductStep();
    if (_hasFirstClient) _onboardingCubit.completeFirstClientStep();
    if (_hasFirstSale) _onboardingCubit.completeFirstSaleStep();
    if (_firstSuccessComplete) {
      _completeGuidedSetup();
      return;
    }
    if (_guidedFocusActive) {
      _updateState(() => _guidedFocusIndex = _firstIncompleteGuideIndex());
    }
  }

  void _completeGuidedSetup() {
    if (_guidedSetupDismissed && !_guidedFocusActive) return;
    _updateState(() {
      _guidedSetupDismissed = true;
      _guidedFocusActive = false;
      _guidedFocusIndex = _firstIncompleteGuideIndex();
    });
    _onboardingCubit.skipGuidance();
  }

  void _startFirstSuccessGuide() {
    _updateState(() {
      _guidedSetupDismissed = false;
      _guidedFocusActive = true;
      _guidedFocusIndex = _firstIncompleteGuideIndex();
    });
  }

  void _skipFirstSuccessGuide() {
    _updateState(() {
      _guidedSetupDismissed = true;
      _guidedFocusActive = false;
    });
    _onboardingCubit.skipGuidance();
    _showMessage(
      'Guide masqué. Vous pouvez le reprendre depuis les actions du tableau.',
    );
  }

  void _nextGuidedFocusStep() {
    final steps = _guidedFocusSteps();
    if (steps.isEmpty) return;
    _updateState(() {
      _guidedFocusIndex = (_guidedFocusIndex + 1)
          .clamp(0, steps.length - 1)
          .toInt();
    });
  }

  void _previousGuidedFocusStep() {
    final steps = _guidedFocusSteps();
    if (steps.isEmpty) return;
    _updateState(() {
      _guidedFocusIndex = (_guidedFocusIndex - 1)
          .clamp(0, steps.length - 1)
          .toInt();
    });
  }

  void _runGuidedPrimaryAction() {
    final steps = _guidedFocusSteps();
    if (steps.isEmpty) return;
    final index = _guidedFocusIndex.clamp(0, steps.length - 1).toInt();
    switch (index) {
      case 0:
        if (_hasFirstProduct) {
          _nextGuidedFocusStep();
        } else {
          _showProductDialog();
        }
        break;
      case 1:
        if (_hasFirstClient) {
          _nextGuidedFocusStep();
        } else {
          _showPartnerDialog(type: PartnerType.client);
        }
        break;
      case 2:
        if (_firstSuccessComplete) {
          _completeGuidedSetup();
        } else if (!_hasFirstProduct || !_hasFirstClient) {
          _updateState(() => _guidedFocusIndex = _firstIncompleteGuideIndex());
        } else if (_section != Section.sales) {
          _goToSales();
        } else if (_draftLines.isNotEmpty) {
          _createDocument(validateNow: _editingDocumentId == null);
        } else {
          _focusProductSearchSoon(ensureVisible: true);
        }
        break;
    }
  }

  List<GuidedFocusStep> _guidedFocusSteps() {
    return [
      GuidedFocusStep(
        title: 'Ajoutez votre premier produit',
        message:
            'Créez un article réel avec son code, son prix et sa quantité de départ.',
        progressLabel: 'Étape 1 sur 3',
        primaryLabel: _hasFirstProduct ? 'Continuer' : 'Créer le produit',
        targetKey: _guideTargetForProduct(),
        isDone: _hasFirstProduct,
      ),
      GuidedFocusStep(
        title: 'Ajoutez votre premier client',
        message:
            'Un nom suffit. Pour une vente comptoir, utilisez le raccourci prévu.',
        progressLabel: 'Étape 2 sur 3',
        primaryLabel: _hasFirstClient ? 'Continuer' : 'Créer le client',
        targetKey: _guideTargetForClient(),
        isDone: _hasFirstClient,
      ),
      GuidedFocusStep(
        title: _firstSuccessComplete
            ? 'Votre magasin est prêt'
            : 'Faites la première vente',
        message: _guidedSaleMessage(),
        progressLabel: 'Étape 3 sur 3',
        primaryLabel: _guidedSalePrimaryLabel(),
        targetKey: _guideTargetForSale(),
        isDone: _firstSuccessComplete,
      ),
    ];
  }

  GlobalKey? _guideTargetForProduct() {
    if (_section == Section.products) return _productCreateActionKey;
    return _firstProductStepKey.currentContext == null
        ? null
        : _firstProductStepKey;
  }

  GlobalKey? _guideTargetForClient() {
    if (_section == Section.customers) return _clientCreateActionKey;
    return _firstClientStepKey.currentContext == null
        ? null
        : _firstClientStepKey;
  }

  GlobalKey? _guideTargetForSale() {
    if (_lastSaleSuccessDocument != null) return _saleSuccessKey;
    if (_section == Section.sales) {
      return _draftLines.isEmpty ? _salesProductSearchKey : _salesValidateKey;
    }
    if (_firstSaleStepKey.currentContext != null) return _firstSaleStepKey;
    return _dashboardPrimaryActionKey.currentContext == null
        ? null
        : _dashboardPrimaryActionKey;
  }

  String _guidedSaleMessage() {
    if (_firstSuccessComplete) {
      return 'Bravo. Produit, client et première vente sont en place. Vous pouvez maintenant travailler depuis Vendre, Stock et Clients.';
    }
    if (_section != Section.sales) {
      return 'Passez à Vendre. Vous choisissez le client, le produit, puis vous validez.';
    }
    if (_draftLines.isEmpty) {
      return 'Cherchez le produit, choisissez la quantité et appuyez sur Entrée.';
    }
    return 'Vérifiez le total, puis validez. Stock et document seront traités automatiquement.';
  }

  String _guidedSalePrimaryLabel() {
    if (_firstSuccessComplete) return 'Terminer';
    if (_section != Section.sales) return 'Ouvrir Vendre';
    if (_draftLines.isEmpty) return 'Cliquez ici pour chercher un produit';
    return 'Valider la vente';
  }
}
