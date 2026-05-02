part of '../inventory_shell_page.dart';

extension _InventoryCompanyPage on _InventoryHomePageState {
  Future<void> _pickCompanyLogo() async {
    if (!supportsLogoImagePicker) {
      _showMessage(
        'Import image disponible dans la version web.',
        isError: true,
      );
      return;
    }

    final logo = await pickLogoImage();
    if (logo == null) return;

    if (logo.size > _InventoryHomePageState._maxLogoBytes) {
      _showMessage(
        'Logo trop lourd. Choisissez une image de moins de 1,6 Mo.',
        isError: true,
      );
      return;
    }
    if (!_isSafeDataLogoSource(logo.dataUrl)) {
      _showMessage(
        'Logo refusé: utilisez un PNG, JPG ou WebP valide.',
        isError: true,
      );
      return;
    }

    _updateState(() => _isUploadingLogo = true);
    final result = await _fileUploadService.uploadCompanyLogo(
      tenantId: _tenantContext.selectedTenantId,
      bytes: logo.bytes,
      fileName: logo.name,
    );
    _updateState(() => _isUploadingLogo = false);

    result.fold(
      (storage) {
        _updateState(() {
          _companyLogoController.text = storage.path;
        });
        _showMessage('Logo synchronisé avec le cloud.');
      },
      (error) {
        // Fallback to data URL for local-first if upload fails
        _updateState(() {
          _companyLogoController.text = logo.dataUrl;
        });
        _showMessage(
          'Envoi cloud échoué, logo gardé localement: ${error.message}',
          isError: true,
        );
      },
    );
  }

  void _clearCompanyLogo() {
    _updateState(() {
      _companyLogoController.text = AppAssets.systemLogoSource;
    });
    _showMessage(
      'Logo personnalisé retiré. Sauvegardez pour garder le logo système.',
    );
  }

  String _logoSourceLabel(String source) {
    final value = source.trim();
    if (value.isEmpty) return 'Aucun logo';
    if (_isSystemLogoSource(value)) return 'Logo système';
    if (_logoAssetPath(value) != null) return 'Image intégrée';
    if (value.startsWith('data:image/')) return 'Image importée';
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'https' && uri.hasAuthority) {
      return 'Lien HTTPS';
    }
    if (value.startsWith('http://') ||
        value.startsWith('file://') ||
        value.startsWith('/')) {
      return 'Source refusée';
    }
    return 'Source personnalisée';
  }

  String _normalizedLogoSource(String source) {
    final value = source.trim();
    return value.isEmpty ? AppAssets.systemLogoSource : value;
  }

  bool _isSystemLogoSource(String source) {
    return _logoAssetPath(source) == AppAssets.systemLogo;
  }

  String? _logoAssetPath(String source) {
    return AppSnapshotCodec.logoAssetPath(source);
  }

  String _safeLogoSource(String source) {
    return AppSnapshotCodec.safeLogoSource(source);
  }

  bool _isSafeDataLogoSource(String source) {
    return AppSnapshotCodec.isSafeDataLogoSource(source);
  }

  Future<Uint8List?> _loadLogoBytes(String source) async {
    final value = source.trim();
    if (value.isEmpty) return null;

    final assetPath = _logoAssetPath(value);
    if (assetPath != null) {
      try {
        final data = await rootBundle.load(assetPath);
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      } catch (_) {
        return null;
      }
    }

    if (value.startsWith('data:image/')) {
      return AppSnapshotCodec.dataLogoBytes(value);
    }

    // Try storage download if looks like a path
    if (value.contains('/') && !value.startsWith('/')) {
      try {
        final supabase = Supabase.instance.client;
        if (supabase.auth.currentSession != null) {
          return await supabase.storage.from('company-logos').download(value);
        }
      } catch (e) {
        debugPrint('Error loading logo from storage: $e');
      }
    }

    return null;
  }

  void _syncCompanyControllers() {
    _companyNameController.text = _company.name;
    _companyTaxIdController.text = _company.taxId;
    _companyAddressController.text = _company.address;
    _companyCityController.text = _company.city;
    _companyPhoneController.text = _company.phone;
    _companyEmailController.text = _company.email;
    _companyLogoController.text = _company.logoSource;
    _companyFooterController.text = _company.invoiceFooter;
    _companyLegalController.text = _company.legalInfo;
    _timbreAmountController.text = _company.timbreFiscalAmount.toStringAsFixed(
      3,
    );
  }

  void _saveCompanyProfile() {
    final name = _companyNameController.text.trim();
    final taxId = _companyTaxIdController.text.trim();
    final timbre = _parseAmount(_timbreAmountController.text, fallback: -1);
    final rawLogoSource = _companyLogoController.text.trim();
    final logoSource = _safeLogoSource(rawLogoSource);
    if (name.isEmpty || taxId.isEmpty) {
      _showMessage(
        'Nom société et matricule fiscal obligatoires.',
        isError: true,
      );
      return;
    }
    if (timbre < 0) {
      _showMessage('Montant timbre fiscal invalide.', isError: true);
      return;
    }
    if (rawLogoSource.isNotEmpty &&
        logoSource == AppAssets.systemLogoSource &&
        !_isSystemLogoSource(rawLogoSource)) {
      _showMessage(
        'Logo refusé: utilisez une URL HTTPS ou une image importée.',
        isError: true,
      );
      return;
    }

    final updated = _company.copyWith(
      name: name,
      taxId: taxId,
      address: _companyAddressController.text.trim(),
      city: _companyCityController.text.trim(),
      phone: _companyPhoneController.text.trim(),
      email: _companyEmailController.text.trim(),
      logoSource: logoSource,
      invoiceFooter: _companyFooterController.text.trim(),
      legalInfo: _companyLegalController.text.trim(),
      timbreFiscalAmount: timbre,
    );
    _updateState(() {
      _companyCubit.updateCompanyProfile(updated);
      _applyRepositoryState();
    });

    _showMessage('Profil société sauvegardé.');
  }

  void _setDefaultTimbreFiscal(bool enabled) {
    _updateState(() {
      _companyCubit.updateFiscalSettings(
        timbreFiscalEnabled: enabled,
        timbreFiscalAmount: _company.timbreFiscalAmount,
      );
      _applyRepositoryState();
    });
  }

  Widget _buildSettings({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Société',
          subtitle:
              'Identité de votre entreprise, documents et sauvegarde locale.',
          actions: [
            ElevatedButton.icon(
              onPressed: _saveCompanyProfile,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Sauvegarder'),
            ),
          ],
        ),
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildCompanySettingsPanel()),
              const SizedBox(width: 18),
              Expanded(flex: 5, child: _buildLocalDatabasePanel()),
            ],
          )
        else ...[
          _buildCompanySettingsPanel(),
          const SizedBox(height: 18),
          _buildLocalDatabasePanel(),
        ],
      ],
    );
  }

  List<String> _missingCompanyIdentityItems() {
    final missing = <String>[];
    if (_companyNameController.text.trim().isEmpty) missing.add('nom');
    if (_companyTaxIdController.text.trim().isEmpty) {
      missing.add('matricule fiscal');
    }
    if (_companyAddressController.text.trim().isEmpty) missing.add('adresse');
    if (_companyCityController.text.trim().isEmpty) missing.add('ville');
    if (_companyPhoneController.text.trim().isEmpty) missing.add('téléphone');
    if (_companyEmailController.text.trim().isEmpty) missing.add('email');
    return missing;
  }

  Widget _buildCompanySettingsPanel() {
    final missing = _missingCompanyIdentityItems();
    return Panel(
      title: 'Identité société',
      trailing: SmallChip(
        label: missing.isEmpty ? 'Complet' : '${missing.length} à compléter',
        color: missing.isEmpty ? AppColors.success : AppColors.warning,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InlineNotice(
            icon: missing.isEmpty
                ? Icons.verified_outlined
                : Icons.info_outline,
            title: missing.isEmpty
                ? 'Identité prête pour les documents'
                : 'Informations à compléter',
            message: missing.isEmpty
                ? 'Ces informations seront utilisées sur les nouveaux documents et dans les PDF.'
                : 'Ajoutez: ${missing.join(', ')}. Les documents déjà validés gardent leur identité sauvegardée.',
            color: missing.isEmpty ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final logoUpload = SizedBox(
                width: compact ? double.infinity : 218,
                child: _buildLogoUploadSurface(),
              );
              final form = _buildCompanyIdentityFields();

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [logoUpload, const SizedBox(height: 18), form],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  logoUpload,
                  const SizedBox(width: 18),
                  Expanded(child: form),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoUploadSurface() {
    final source = _normalizedLogoSource(_companyLogoController.text);
    final isSystemLogo = _isSystemLogoSource(source);
    final hasLogo = source.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          LogoImage(
            key: ValueKey('${source}_$_logoVersion'),
            source: source,
            fallbackText: _companyNameController.text,
            size: 112,
          ),
          const SizedBox(height: 12),
          Text(
            _logoSourceLabel(source),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            hasLogo
                ? isSystemLogo
                      ? 'Logo par défaut utilisé sur l’aperçu A4 et les PDF.'
                      : 'Utilisé sur l’aperçu A4, le PDF et la sauvegarde locale.'
                : 'PNG, JPG ou WebP léger pour une facture nette.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploadingLogo ? null : _pickCompanyLogo,
              icon: _isUploadingLogo
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                _isUploadingLogo
                    ? 'Envoi...'
                    : (isSystemLogo || !hasLogo
                          ? 'Importer logo'
                          : 'Remplacer'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: hasLogo && !isSystemLogo ? _clearCompanyLogo : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Retirer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyIdentityFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations principales',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Elles apparaissent sur les nouveaux devis, bons et factures.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _fieldBox(
              width: 320,
              child: TextField(
                controller: _companyNameController,
                onChanged: (_) => _updateState(() {}),
                decoration: const InputDecoration(labelText: 'Nom société'),
              ),
            ),
            _fieldBox(
              width: 240,
              child: TextField(
                controller: _companyTaxIdController,
                onChanged: (_) => _updateState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Matricule fiscal',
                ),
              ),
            ),
            _fieldBox(
              width: 360,
              child: TextField(
                controller: _companyAddressController,
                onChanged: (_) => _updateState(() {}),
                decoration: const InputDecoration(labelText: 'Adresse'),
              ),
            ),
            _fieldBox(
              width: 220,
              child: TextField(
                controller: _companyCityController,
                onChanged: (_) => _updateState(() {}),
                decoration: const InputDecoration(labelText: 'Ville'),
              ),
            ),
            _fieldBox(
              width: 220,
              child: TextField(
                controller: _companyPhoneController,
                onChanged: (_) => _updateState(() {}),
                decoration: const InputDecoration(labelText: 'Téléphone'),
              ),
            ),
            _fieldBox(
              width: 300,
              child: TextField(
                controller: _companyEmailController,
                onChanged: (_) => _updateState(() {}),
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          'Mentions sur les documents',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _fieldBox(
              width: 360,
              child: TextField(
                controller: _companyLegalController,
                decoration: const InputDecoration(
                  labelText: 'Mention légale courte',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildLogoSourceEditor(),
        const SizedBox(height: 14),
        TextField(
          controller: _companyFooterController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Pied de page document',
            helperText:
                'Exemple: conditions de paiement, garantie, remerciement.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            SmallChip(label: 'Logo sur facture'),
            SmallChip(label: 'PDF avec identité'),
            SmallChip(label: 'Matricule fiscal sur A4'),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoSourceEditor() {
    final source = _normalizedLogoSource(_companyLogoController.text);
    final assetPath = _logoAssetPath(source);
    if (assetPath != null) {
      final isSystemLogo = _isSystemLogoSource(source);
      return InlineNotice(
        icon: isSystemLogo ? Icons.verified_outlined : Icons.image_outlined,
        title: isSystemLogo ? 'Logo système actif' : 'Logo intégré',
        message: isSystemLogo
            ? 'Le logo Trace Ultra est utilisé par défaut. Importez votre logo pour personnaliser les documents.'
            : 'Cette image intégrée est utilisée sur les aperçus, les PDF et la sauvegarde locale.',
        color: AppColors.primary,
      );
    }
    if (source.startsWith('data:image/')) {
      return InlineNotice(
        icon: Icons.image_outlined,
        title: 'Logo intégré',
        message:
            'L’image importée est enregistrée dans la base locale et suit les exports JSON.',
        color: AppColors.primary,
      );
    }

    return TextField(
      controller: _companyLogoController,
      onChanged: (_) => _updateState(() {}),
      decoration: const InputDecoration(
        labelText: 'Lien ou chemin logo',
        helperText:
            'Optionnel: préférez le bouton Importer pour garder le logo dans la sauvegarde.',
        prefixIcon: Icon(Icons.link_outlined),
      ),
    );
  }
}
