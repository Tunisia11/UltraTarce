import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../app/app_colors.dart';
import '../../../../domain/app_enums.dart';
import '../../../../domain/app_models.dart';
import '../../../../data/storage/file_upload_service.dart';
import '../../application/products_cubit.dart';
import '../../application/warehouse_cubit.dart';
import '../../application/category_cubit.dart';
import '../../widgets/price_insight.dart';
import '../widgets/product_image.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({
    super.key,
    this.product,
    required this.tenantId,
    this.fileUploadService,
  });

  final Product? product;
  final String tenantId;
  final FileUploadService? fileUploadService;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _brandController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _purchaseController;
  late final TextEditingController _saleController;
  late final TextEditingController _minStockController;
  late final TextEditingController _initialStockController;

  late String _category;
  late TvaRate _tvaRate;
  late bool _stockTracked;
  late bool _serialTracked;
  late bool _active;
  String? _initialWarehouseId;

  String? _imageDataUrl;
  bool _isSaving = false;
  late final String _productId;

  // Deferred image upload state
  Uint8List? _pendingImageBytes;
  String? _pendingImageName;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _productId = p?.id ?? 'prod-${DateTime.now().microsecondsSinceEpoch}';
    _nameController = TextEditingController(text: p?.name ?? '');
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _brandController = TextEditingController(text: p?.brand ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _purchaseController = TextEditingController(
      text: p?.purchaseHt.toStringAsFixed(3) ?? '0.000',
    );
    _saleController = TextEditingController(
      text: p?.saleHt.toStringAsFixed(3) ?? '',
    );
    _minStockController = TextEditingController(text: '${p?.minStock ?? 0}');
    _initialStockController = TextEditingController(text: '0');

    _category = p?.category ?? 'Général';
    _tvaRate = p?.tvaRate ?? TvaRate.rate19;
    _stockTracked = p?.stockTracked ?? true;
    _serialTracked = p?.serialTracked ?? false;
    _active = p?.active ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _purchaseController.dispose();
    _saleController.dispose();
    _minStockController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    debugPrint('[image_picker] start');

    try {
      setState(() => _isPickingImage = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('[image_picker] cancelled');
        return;
      }

      final file = result.files.single;
      debugPrint('[image_picker] selected name=${file.name} size=${file.size}');

      Uint8List? bytes;
      if (kIsWeb || file.bytes != null) {
        bytes = file.bytes;
      } else if (file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }

      if (bytes == null) return;

      if (bytes.length > 1024 * 1024) {
        _showError('Image trop lourde. Choisissez une image de moins de 1 Mo.');
        return;
      }

      final mimeType = _getMimeType(file.name);
      if (mimeType != 'image/jpeg' &&
          mimeType != 'image/png' &&
          mimeType != 'image/webp') {
        _showError('Format image non supporté.');
        return;
      }

      final localDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      setState(() {
        _pendingImageBytes = bytes;
        _pendingImageName = file.name;
        _imageDataUrl = localDataUrl;
      });

      debugPrint('[image_picker] preview ready');
    } catch (e) {
      debugPrint('[image_picker] error: $e');
      _showError('Erreur lors de la sélection de l\'image');
    } finally {
      setState(() => _isPickingImage = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.danger),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  final _historyKey = GlobalKey();
  double _parseAmount(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0.0;
  }

  Future<void> _save() async {
    debugPrint('[product_save] start');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[product_save] validation failed');
      return;
    }

    final isNew = widget.product == null;
    final productsCubit = context.read<ProductsCubit>();

    // Check SKU uniqueness
    final existingProducts = productsCubit.state.products;
    final sku = _skuController.text.trim();
    if (existingProducts.any(
      (p) =>
          p.id != widget.product?.id &&
          p.sku.toLowerCase() == sku.toLowerCase(),
    )) {
      _showError('Ce code SKU est déjà utilisé.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Deferred Image Upload
      if (_pendingImageBytes != null && widget.fileUploadService != null) {
        debugPrint('[product_save] image upload start');
        final uploadResult = await widget.fileUploadService!
            .uploadProductImage(
              tenantId: widget.tenantId,
              productId: _productId,
              bytes: _pendingImageBytes!,
              fileName: _pendingImageName ?? 'image.jpg',
            )
            .timeout(const Duration(seconds: 15));

        uploadResult.fold(
          (storage) {
            debugPrint(
              '[product_save] image upload success path=${storage.path}',
            );
            _imageDataUrl = storage.path;
          },
          (error) {
            debugPrint(
              '[product_save] image upload failed fallback local error=$error',
            );
            _showMessage(
              'Image non envoyée au cloud. Le produit est enregistré localement.',
            );
            // _imageDataUrl remains the data URL set in _pickImage
          },
        );
      }

      final product = Product(
        id: _productId,
        name: _nameController.text.trim(),
        sku: sku,
        category: _category,
        purchaseHt: _parseAmount(_purchaseController.text),
        saleHt: _parseAmount(_saleController.text),
        tvaRate: _tvaRate,
        minStock: int.tryParse(_minStockController.text) ?? 0,
        serialTracked: _serialTracked,
        stockTracked: _stockTracked,
        active: _active,
        stockByWarehouse: widget.product?.stockByWarehouse ?? {},
        serialsByWarehouse: widget.product?.serialsByWarehouse ?? {},
        imageUrl: _imageDataUrl ?? widget.product?.imageUrl ?? '',
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        brand: _brandController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (isNew) {
        final initialStock = int.tryParse(_initialStockController.text) ?? 0;
        productsCubit.createProduct(
          product,
          initialWarehouseId: _initialWarehouseId,
          initialStockQuantity: initialStock,
          movementNumber: initialStock > 0
              ? 'INI-${DateTime.now().millisecondsSinceEpoch}'
              : null,
          serialGenerator: (sku, index) => '$sku-INI-$index',
        );
      } else {
        productsCubit.updateProduct(product);
      }

      debugPrint('[product_save] local save success');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('[product_save] error: $e');
      _showError('Erreur lors de la sauvegarde: $e');
    } finally {
      debugPrint('[product_save] complete');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = context.watch<ProductsCubit>().state;
    final product = widget.product != null
        ? productsState.products.firstWhere(
            (p) => p.id == widget.product!.id,
            orElse: () => widget.product!,
          )
        : null;
    final isNew = product == null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isNew ? 'Nouveau Produit' : 'Modifier Produit'),
        centerTitle: false,
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text(
                'Enregistrer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Informations Générales'),
                  const SizedBox(height: 16),
                  _buildMainInfo(),
                  const SizedBox(height: 32),
                  if (product != null) ...[
                    _buildSectionHeader('Stock actuel'),
                    const SizedBox(height: 16),
                    _buildStockSummary(product),
                    const SizedBox(height: 32),
                  ],
                  _buildSectionHeader('Prix et Taxes'),
                  const SizedBox(height: 16),
                  _buildPricingInfo(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Stock et Inventaire'),
                  const SizedBox(height: 16),
                  _buildStockInfo(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Détails Supplémentaires'),
                  const SizedBox(height: 16),
                  _buildExtraInfo(),
                  if (product != null) _buildStockHistory(product),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: .2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockActionButton(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildStockSummary(Product p) {
    final warehouses = context.read<WarehouseCubit>().warehouses;
    final low = p.stockTracked && p.active && p.totalStock <= p.minStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (low)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: .3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Attention: Le stock est inférieur au seuil d\'alerte.',
                    style: TextStyle(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            _buildStatCard('Stock Total', '${p.totalStock}', AppColors.primary),
            const SizedBox(width: 16),
            _buildStatCard(
              'Seuil d\'alerte',
              '${p.minStock}',
              AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: .5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Répartition par dépôt',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (p.stockByWarehouse.isEmpty)
                const Text(
                  'Aucun stock enregistré.',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...p.stockByWarehouse.entries.map((e) {
                  final w = warehouses.firstWhere(
                    (w) => w.id == e.key,
                    orElse: () => Warehouse(
                      id: e.key,
                      name: e.key,
                      city: '',
                      active: true,
                    ),
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(w.name),
                        Text(
                          '${e.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStockActionButton(
              'Entrée stock',
              Icons.add_circle_outline,
              () => _showStockActionDialog(StockDirection.inbound),
            ),
            _buildStockActionButton(
              'Sortie stock',
              Icons.remove_circle_outline,
              () => _showStockActionDialog(StockDirection.outbound),
            ),
            _buildStockActionButton(
              'Ajuster stock',
              Icons.tune,
              () => _showStockActionDialog(null),
            ),
            _buildStockActionButton(
              'Transférer',
              Icons.swap_horiz,
              _showTransferDialog,
            ),
            _buildStockActionButton('Historique stock', Icons.history, () {
              Scrollable.ensureVisible(
                _historyKey.currentContext!,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildStockHistory(Product product) {
    final movements = context.read<ProductsCubit>().getMovementsForProduct(
      product.id,
    )..sort((a, b) => b.date.compareTo(a.date));

    if (movements.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        _buildSectionHeader('Historique stock', key: _historyKey),
        const SizedBox(height: 16),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: movements.take(10).length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final m = movements[index];
            final warehouses = context.read<WarehouseCubit>().warehouses;
            final w = warehouses.firstWhere(
              (w) => w.id == m.warehouseId,
              orElse: () => Warehouse(
                id: m.warehouseId,
                name: m.warehouseId,
                city: '',
                active: true,
              ),
            );

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                m.direction == StockDirection.inbound
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: m.direction == StockDirection.inbound
                    ? AppColors.success
                    : AppColors.danger,
              ),
              title: Text(
                '${m.direction == StockDirection.inbound ? '+' : '-'}${m.quantity} · ${m.reason ?? m.documentNumber}',
              ),
              subtitle: Text(
                '${w.name} · ${m.date.day}/${m.date.month}/${m.date.year}${m.documentNumber.isNotEmpty ? " · Doc: ${m.documentNumber}" : ""}',
              ),
              trailing: m.note != null && m.note!.isNotEmpty
                  ? const Icon(
                      Icons.note_outlined,
                      size: 16,
                      color: AppColors.muted,
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }

  Future<void> _showStockActionDialog(StockDirection? direction) async {
    final productsCubit = context.read<ProductsCubit>();
    final warehouseCubit = context.read<WarehouseCubit>();
    final isAdjustment = direction == null;
    final warehouses = warehouseCubit.warehouses
        .where((w) => w.active)
        .toList();
    if (warehouses.isEmpty) {
      _showError('Aucun dépôt actif disponible.');
      return;
    }

    String? selectedWarehouseId = warehouses.first.id;
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final noteController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            isAdjustment
                ? 'Ajuster stock'
                : (direction == StockDirection.inbound
                      ? 'Entrée stock'
                      : 'Sortie stock'),
          ),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedWarehouseId,
                    decoration: const InputDecoration(labelText: 'Dépôt'),
                    items: warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedWarehouseId = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isAdjustment
                          ? 'Nouveau stock réel'
                          : 'Quantité',
                    ),
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val < 0) return 'Quantité invalide';
                      if (!isAdjustment && val == 0) return 'Quantité invalide';
                      if (!isAdjustment &&
                          direction == StockDirection.outbound) {
                        final current = widget.product!.stockIn(
                          selectedWarehouseId!,
                        );
                        if (val > current) return 'Stock insuffisant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Motif (obligatoire)',
                    ),
                    validator: (v) =>
                        v?.trim().isEmpty == true ? 'Champ obligatoire' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optionnel)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!dialogFormKey.currentState!.validate()) return;

                final qty = int.parse(quantityController.text);
                final reason = reasonController.text.trim();
                final note = noteController.text.trim();

                try {
                  if (isAdjustment) {
                    final current = widget.product!.stockIn(
                      selectedWarehouseId!,
                    );
                    final delta = qty - current;
                    if (delta == 0) {
                      Navigator.pop(context);
                      return;
                    }
                    productsCubit.adjustStock(
                      productId: widget.product!.id,
                      warehouseId: selectedWarehouseId!,
                      quantity: delta.abs(),
                      direction: delta > 0
                          ? StockDirection.inbound
                          : StockDirection.outbound,
                      reason: reason,
                      note: note,
                      movementNumber:
                          'ADJ-${DateTime.now().millisecondsSinceEpoch}',
                      serialGenerator: (sku, index) => '$sku-ADJ-$index',
                    );
                  } else {
                    productsCubit.adjustStock(
                      productId: widget.product!.id,
                      warehouseId: selectedWarehouseId!,
                      quantity: qty,
                      direction: direction,
                      reason: reason,
                      note: note,
                      movementNumber:
                          '${direction == StockDirection.inbound ? 'IN' : 'OUT'}-${DateTime.now().millisecondsSinceEpoch}',
                      serialGenerator: (sku, index) =>
                          '$sku-${direction.name}-$index',
                    );
                  }
                  Navigator.pop(context);
                  _showSuccess(
                    isAdjustment
                        ? 'Stock ajusté.'
                        : (direction == StockDirection.inbound
                              ? 'Entrée de stock enregistrée.'
                              : 'Sortie de stock enregistrée.'),
                  );
                  setState(() {}); // Refresh local summary
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              child: Text(
                isAdjustment
                    ? 'Confirmer ajustement'
                    : (direction == StockDirection.inbound
                          ? 'Confirmer entrée'
                          : 'Confirmer sortie'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTransferDialog() async {
    final productsCubit = context.read<ProductsCubit>();
    final warehouseCubit = context.read<WarehouseCubit>();
    final warehouses = warehouseCubit.warehouses
        .where((w) => w.active)
        .toList();
    if (warehouses.length < 2) {
      _showError('Il faut au moins deux dépôts actifs pour un transfert.');
      return;
    }

    String? fromWarehouseId = warehouses.first.id;
    String? toWarehouseId = warehouses.length > 1 ? warehouses[1].id : null;
    final quantityController = TextEditingController();
    final noteController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Transférer du stock'),
          content: Form(
            key: dialogFormKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: fromWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Dépôt source',
                    ),
                    items: warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => fromWarehouseId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: toWarehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Dépôt destination',
                    ),
                    items: warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => toWarehouseId = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantité'),
                    validator: (v) {
                      final val = int.tryParse(v ?? '');
                      if (val == null || val <= 0) return 'Quantité invalide';
                      if (widget.product!.stockIn(fromWarehouseId!) < val) {
                        return 'Stock insuffisant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optionnel)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!dialogFormKey.currentState!.validate()) return;
                if (fromWarehouseId == toWarehouseId) {
                  _showError(
                    'Le dépôt source et le dépôt destination doivent être différents.',
                  );
                  return;
                }

                final qty = int.parse(quantityController.text);
                final note = noteController.text.trim();

                try {
                  productsCubit.transferStock(
                    productId: widget.product!.id,
                    fromWarehouseId: fromWarehouseId!,
                    toWarehouseId: toWarehouseId!,
                    quantity: qty,
                    reason: 'Transfert inter-dépôt',
                    note: note,
                    movementNumber:
                        'TRF-${DateTime.now().millisecondsSinceEpoch}',
                  );
                  Navigator.pop(context);
                  _showSuccess('Transfert de stock enregistré.');
                  setState(() {});
                } catch (e) {
                  _showError('Erreur: $e');
                }
              },
              child: const Text('Confirmer transfert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildMainInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              ProductImage(
                url: _imageDataUrl ?? widget.product?.imageUrl ?? '',
                width: 160,
                height: 160,
                borderRadius: 12,
              ),
              if (_imageDataUrl != null ||
                  (widget.product?.imageUrl.isNotEmpty ?? false))
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du produit *',
                  hintText: 'Ex: Samsung Galaxy S24 Ultra',
                ),
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Champ obligatoire' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU / Référence *',
                        hintText: 'Ex: SAM-S24-U',
                      ),
                      validator: (v) => v?.trim().isEmpty == true
                          ? 'Champ obligatoire'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BlocBuilder<CategoryCubit, CategoryState>(
                      builder: (context, state) {
                        final categories = state is CategoryLoaded
                            ? state.categories
                            : context.read<CategoryCubit>().categories;

                        return DropdownButtonFormField<String>(
                          initialValue:
                              categories.any((c) => c.name == _category)
                              ? _category
                              : (categories.isNotEmpty
                                    ? categories.first.name
                                    : 'Général'),
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                          ),
                          items: [
                            if (!categories.any((c) => c.name == 'Général'))
                              const DropdownMenuItem(
                                value: 'Général',
                                child: Text('Général'),
                              ),
                            for (final c in categories)
                              DropdownMenuItem(
                                value: c.name,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (v) => setState(() => _category = v!),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: .5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _purchaseController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prix d\'achat HT',
                    suffixText: 'TND',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _saleController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Prix de vente HT *',
                    suffixText: 'TND',
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty == true ? 'Champ obligatoire' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<TvaRate>(
                  initialValue: _tvaRate,
                  decoration: const InputDecoration(labelText: 'TVA'),
                  items: [
                    for (final rate in TvaRate.values)
                      DropdownMenuItem(value: rate, child: Text(rate.label)),
                  ],
                  onChanged: (v) => setState(() => _tvaRate = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PriceInsight(
            saleHt: _parseAmount(_saleController.text),
            purchaseHt: _parseAmount(_purchaseController.text),
            tvaRate: _tvaRate,
          ),
        ],
      ),
    );
  }

  Widget _buildStockInfo() {
    final isNew = widget.product == null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                title: const Text('Suivre le stock'),
                subtitle: const Text('Gérer les quantités et alertes'),
                value: _stockTracked,
                onChanged: (v) => setState(() => _stockTracked = v),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: SwitchListTile(
                title: const Text('Numéros de série'),
                subtitle: const Text('Tracer chaque unité individuellement'),
                value: _serialTracked,
                onChanged: (v) => setState(() => _serialTracked = v),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_stockTracked)
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Seuil d\'alerte stock',
                    helperText: 'Alerte quand le stock est inférieur',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (isNew) ...[
                Expanded(
                  child: TextFormField(
                    controller: _initialStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock initial',
                      helperText: 'Quantité disponible à la création',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: BlocBuilder<WarehouseCubit, WarehouseState>(
                    builder: (context, state) {
                      final warehouses = state is WarehouseLoaded
                          ? state.warehouses.where((w) => w.active).toList()
                          : context
                                .read<WarehouseCubit>()
                                .warehouses
                                .where((w) => w.active)
                                .toList();

                      _initialWarehouseId ??= warehouses.firstOrNull?.id;

                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue:
                            warehouses.any((w) => w.id == _initialWarehouseId)
                            ? _initialWarehouseId
                            : warehouses.firstOrNull?.id,
                        decoration: const InputDecoration(
                          labelText: 'Dépôt de départ',
                        ),
                        items: [
                          for (final w in warehouses)
                            DropdownMenuItem(value: w.id, child: Text(w.name)),
                        ],
                        onChanged: (v) =>
                            setState(() => _initialWarehouseId = v),
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(flex: 2),
            ],
          ),
      ],
    );
  }

  Widget _buildExtraInfo() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Code-barres (EAN)',
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Marque / Fabricant',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Produit actif'),
          subtitle: const Text('Visible dans le catalogue et les ventes'),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
