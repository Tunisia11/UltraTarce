part of 'inventory_shell_page.dart';

class _ActivityEntry {
  const _ActivityEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.date,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final DateTime date;
  final String? trailing;
}

enum _GlobalSearchKind { product, client, supplier, document }

class _GlobalSearchResult {
  const _GlobalSearchResult({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final _GlobalSearchKind kind;
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

extension _InventoryShellPageUi on _InventoryHomePageState {
  Widget _buildInventoryShell() {
    final guideSteps = _guidedFocusSteps();
    final safeGuideIndex = guideSteps.isEmpty
        ? 0
        : _guidedFocusIndex.clamp(0, guideSteps.length - 1).toInt();
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 980;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDesktop) _buildSidebar(),
                    Expanded(
                      child: Column(
                        children: [
                          if (!isDesktop) _buildMobileNav(),
                          _buildTopBar(isDesktop: isDesktop),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(
                                  isDesktop ? 32 : 16,
                                  isDesktop ? 28 : 18,
                                  isDesktop ? 32 : 16,
                                  isDesktop ? 36 : 24,
                                ),
                                child: _buildCurrentSection(
                                  isDesktop: isDesktop,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          GuidedFocusOverlay(
            visible:
                _guidedFocusActive &&
                _shouldShowFirstSuccessGuide &&
                guideSteps.isNotEmpty,
            steps: guideSteps,
            currentIndex: safeGuideIndex,
            onNext: _nextGuidedFocusStep,
            onPrevious: _previousGuidedFocusStep,
            onSkip: _skipFirstSuccessGuide,
            onPrimaryAction: _runGuidedPrimaryAction,
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar({required bool isDesktop}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 28 : 16,
        12,
        isDesktop ? 28 : 16,
        12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest.withValues(alpha: .88),
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: .18)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .035),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isDesktop)
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Autocomplete<_GlobalSearchResult>(
                  displayStringForOption: (result) => result.title,
                  optionsBuilder: (textEditingValue) =>
                      _globalSearchResults(textEditingValue.text),
                  onSelected: _openGlobalSearchResult,
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onSubmitted: (value) {
                            final results = _globalSearchResults(value);
                            if (results.isEmpty) {
                              _showMessage(
                                'Aucun résultat trouvé pour "$value".',
                                isError: true,
                              );
                              return;
                            }
                            _openGlobalSearchResult(results.first);
                          },
                          decoration: const InputDecoration(
                            hintText:
                                'Rechercher produit, client, fournisseur ou document...',
                            prefixIcon: Icon(Icons.search),
                            isDense: true,
                          ),
                        );
                      },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(10),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 520,
                            maxHeight: 320,
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final result = options.elementAt(index);
                              return ListTile(
                                dense: true,
                                leading: Icon(result.icon),
                                title: Text(
                                  result.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(
                                  result.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => onSelected(result),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                _section.label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          if (isDesktop) const Spacer(),
          const SizedBox(width: 12),
          _systemStatusPill(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Brouillons à traiter',
            onPressed: () => _updateState(() => _section = Section.documents),
            icon: Badge.count(
              count: _draftDocuments.length,
              isLabelVisible: _draftDocuments.isNotEmpty,
              child: const Icon(Icons.notifications_none_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Société',
            onPressed: () => _updateState(() => _section = Section.settings),
            icon: const Icon(Icons.settings_outlined),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceHigh,
              child: Text(
                _company.name.trim().isEmpty
                    ? 'TN'
                    : _company.name
                          .trim()
                          .characters
                          .take(2)
                          .toString()
                          .toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primaryContainer,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _systemStatusPill() {
    final label = _lastSavedAt == null
        ? 'Local'
        : 'Sauvegardé ${formatTime(_lastSavedAt!)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_appConfig.cloudPilotEnabled) ...[
          _statusPill(
            label: SyncPilotMessages.modeLabel,
            dotColor: AppColors.cyan,
            tooltip:
                '${SyncPilotMessages.localThenCloud} ${SyncPilotMessages.oneDevicePilot}',
          ),
          const SizedBox(width: 8),
        ],
        _statusPill(
          label: label,
          dotColor: AppColors.emerald,
          tooltip: _storageStatus,
        ),
        const SizedBox(width: 8),
        BlocBuilder<SyncStatusCubit, SyncStatusState>(
          builder: (context, state) {
            final pendingSuffix = state.pendingCount > 0
                ? ' (${state.pendingCount})'
                : '';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _statusPill(
                  label: '${state.label}$pendingSuffix',
                  dotColor: _syncStatusColor(state),
                  tooltip: state.lastError ?? state.label,
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Synchroniser maintenant',
                  visualDensity: VisualDensity.compact,
                  onPressed: state is SyncProcessing
                      ? null
                      : _triggerManualPushSync,
                  icon: const Icon(Icons.sync, size: 18),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  tooltip: 'Options de synchronisation',
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'repair',
                      child: Text(SyncPilotMessages.repairSyncActionLabel),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'repair') {
                      _triggerRepairSync();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statusPill({
    required String label,
    required Color dotColor,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border.withValues(alpha: .18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _syncStatusColor(SyncStatusState state) {
    return switch (state) {
      SyncOffline() => AppColors.subtle,
      SyncFailed() => AppColors.danger,
      SyncProcessing() => AppColors.cyan,
      SyncPending() => AppColors.warning,
      SyncSynced() || SyncIdle() => AppColors.emerald,
    };
  }

  Widget _buildSystemLogoTile({double width = 68, double height = 44}) {
    return Semantics(
      label: 'Logo Trace Ultra',
      image: true,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border.withValues(alpha: .35)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.asset(
          AppAssets.systemLogo,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.inventory_2_outlined,
            color: AppColors.primaryContainer,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSection({required bool isDesktop}) {
    switch (_section) {
      case Section.dashboard:
        return _buildDashboard(isDesktop: isDesktop);
      case Section.sales:
        return _buildSales(isDesktop: isDesktop);
      case Section.products:
        return _buildProducts();
      case Section.customers:
        return _buildCustomers();
      case Section.suppliers:
        return _buildSuppliers();
      case Section.documents:
        return _buildDocuments(isDesktop: isDesktop);
      case Section.stock:
        return _buildStock();
      case Section.purchases:
        return _buildPurchases(isDesktop: isDesktop);
      case Section.reports:
        return _buildReports();
      case Section.settings:
        return _buildSettings(isDesktop: isDesktop);
      case Section.tax:
        return _buildTaxSettings();
      case Section.audit:
        return _buildAudit();
      case Section.team:
        return _buildTeamSection();
    }
  }

  Widget _buildTeamSection() {
    // Get current user's role from TenantContext
    final role = _tenantContext.currentRole;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(
          title: 'Équipe',
          subtitle: 'Gérer les membres de votre société',
        ),
        const Text(
          'Utilisez le bouton ci-dessous pour ouvrir la gestion d\'équipe.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.group),
          label: const Text('Ouvrir la gestion d\'équipe'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryContainer,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TeamPage(
                  tenantId: _tenantContext.selectedTenantId,
                  currentRole: role,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader({
    required String title,
    required String subtitle,
    List<Widget> actions = const [],
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;
          final heading = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
            ],
          );
          final actionBar = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions,
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  actionBar,
                ],
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              if (actions.isNotEmpty) ...[const SizedBox(width: 20), actionBar],
            ],
          );
        },
      ),
    );
  }
}
