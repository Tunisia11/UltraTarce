part of '../inventory_shell_page.dart';

extension _InventoryGuidedFocusOverlayFlow on _InventoryHomePageState {
  int _firstIncompleteGuideIndex() {
    if (!_companyIdentityReady) return 0;
    if (!_hasFirstDepot) return 1;
    if (!_hasFirstProduct) return 2;
    if (!_hasFirstClient) return 3;
    if (!_hasFirstSale) return 4;
    if (!_hasBonSortie) return 5;
    return 6;
  }

  void _syncGuidedProgressAfterMutation() {
    _ensureSelections();
    if (_hasFirstProduct) _onboardingCubit.completeFirstProductStep();
    if (_hasFirstClient) _onboardingCubit.completeFirstClientStep();
    if (_hasFirstSale) _onboardingCubit.completeFirstSaleStep();
    if (_firstSuccessComplete && !_guidedFocusActive) {
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
        _updateState(() => _section = Section.settings);
        break;
      case 1:
        if (_hasFirstDepot) {
          _nextGuidedFocusStep();
        } else {
          _showWarehouseDialog();
        }
        break;
      case 2:
        if (_hasFirstProduct) {
          _nextGuidedFocusStep();
        } else {
          _openProductForm();
        }
        break;
      case 3:
        if (_hasFirstClient) {
          _nextGuidedFocusStep();
        } else {
          _showPartnerDialog(type: PartnerType.client);
        }
        break;
      case 4:
        if (_firstSuccessComplete) {
          _nextGuidedFocusStep();
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
      case 5:
        if (_hasBonSortie) {
          _nextGuidedFocusStep();
        } else if (_hasMobileWarehouse) {
          _openBonSortieForm();
        } else {
          _showWarehouseDialog(null, 'mobile');
        }
        break;
      case 6:
        _triggerManualPushSync();
        _completeGuidedSetup();
        break;
    }
  }

  List<GuidedFocusStep> _guidedFocusSteps() {
    return [
      GuidedFocusStep(
        title: 'Complétez le profil société',
        message:
            'Bienvenue dans Trace Ultra. Les informations société apparaissent sur les devis, factures, BL et bons de sortie.',
        progressLabel: 'Étape 1 sur 7',
        primaryLabel: 'Ouvrir Société',
        targetKey: _guideTargetForCompany(),
        isDone: _companyIdentityReady,
      ),
      GuidedFocusStep(
        title: 'Ajoutez votre premier dépôt',
        message:
            'Un dépôt représente votre magasin, votre réserve ou une unité mobile. Il permet de suivre le stock clairement.',
        progressLabel: 'Étape 2 sur 7',
        primaryLabel: _hasFirstDepot ? 'Continuer' : 'Créer le dépôt',
        targetKey: _guideTargetForDepot(),
        isDone: _hasFirstDepot,
      ),
      GuidedFocusStep(
        title: 'Ajoutez votre premier produit',
        message:
            'Commençons par ajouter votre premier produit avec son code, son prix, sa TVA et son stock initial.',
        progressLabel: 'Étape 3 sur 7',
        primaryLabel: _hasFirstProduct ? 'Continuer' : 'Créer le produit',
        targetKey: _guideTargetForProduct(),
        isDone: _hasFirstProduct,
      ),
      GuidedFocusStep(
        title: 'Ajoutez votre premier client',
        message:
            'Ajoutez un client ou utilisez Client comptoir pour vendre rapidement.',
        progressLabel: 'Étape 4 sur 7',
        primaryLabel: _hasFirstClient ? 'Continuer' : 'Créer le client',
        targetKey: _guideTargetForClient(),
        isDone: _hasFirstClient,
      ),
      GuidedFocusStep(
        title: _firstSuccessComplete
            ? 'Votre magasin est prêt'
            : 'Faites la première vente',
        message: _guidedSaleMessage(),
        progressLabel: 'Étape 5 sur 7',
        primaryLabel: _guidedSalePrimaryLabel(),
        targetKey: _guideTargetForSale(),
        isDone: _firstSuccessComplete,
      ),
      GuidedFocusStep(
        title: 'Préparez une sortie camion',
        message:
            'Pour les livraisons avec camion, utilisez Sortie camion afin de transférer les produits vers une unité mobile.',
        progressLabel: 'Étape 6 sur 7',
        primaryLabel: _hasMobileWarehouse
            ? 'Préparer Sortie camion'
            : 'Créer Camion 1',
        targetKey: _guideTargetForSortie(),
        isDone: _hasBonSortie,
      ),
      GuidedFocusStep(
        title: 'Synchronisez quand vous êtes prêt',
        message:
            'Vos données sont enregistrées localement. Cliquez sur Synchroniser pour les sauvegarder dans le cloud.',
        progressLabel: 'Étape 7 sur 7',
        primaryLabel: 'Synchroniser',
        targetKey: _guideTargetForSync(),
        isDone: false,
      ),
    ];
  }

  GlobalKey? _guideTargetForCompany() {
    return _companyProfileStepKey.currentContext == null
        ? null
        : _companyProfileStepKey;
  }

  GlobalKey? _guideTargetForDepot() {
    return _firstDepotStepKey.currentContext == null
        ? null
        : _firstDepotStepKey;
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

  GlobalKey? _guideTargetForSortie() {
    return _sortieCamionStepKey.currentContext == null
        ? null
        : _sortieCamionStepKey;
  }

  GlobalKey? _guideTargetForSync() {
    if (_syncActionKey.currentContext != null) return _syncActionKey;
    return _syncStepKey.currentContext == null ? null : _syncStepKey;
  }

  String _guidedSaleMessage() {
    if (_firstSuccessComplete) {
      return 'Bravo. Produit, client et première vente sont en place. Vous pouvez maintenant suivre les documents et le stock.';
    }
    if (_section != Section.sales) {
      return 'Parfait. Maintenant, vous pouvez faire votre première vente: client, produit, puis validation.';
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
