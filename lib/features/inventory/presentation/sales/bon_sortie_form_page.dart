import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/app_colors.dart';
import '../../../../domain/app_enums.dart';
import '../../../../domain/app_models.dart';
import '../../application/documents_cubit.dart';
import '../../application/products_cubit.dart';
import '../../application/stock_cubit.dart';
import '../../application/warehouse_cubit.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/panel.dart';

class BonSortieFormPage extends StatefulWidget {
  const BonSortieFormPage({
    super.key,
    required this.company,
    required this.nextNumber,
    this.initialDocument,
  });

  final CompanyProfile company;
  final String nextNumber;
  final BusinessDocument? initialDocument;

  @override
  State<BonSortieFormPage> createState() => _BonSortieFormPageState();
}

class _BonSortieFormPageState extends State<BonSortieFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _driverController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _noteController = TextEditingController();

  late String _number;
  late DateTime _date;
  String? _sourceWarehouseId;
  String? _targetWarehouseId;
  final List<DocumentLine> _lines = [];

  @override
  void initState() {
    super.initState();
    final doc = widget.initialDocument;
    _number = doc?.number ?? widget.nextNumber;
    _date = doc?.date ?? DateTime.now();
    _sourceWarehouseId = doc?.warehouseId;
    _targetWarehouseId = doc?.metadata['targetWarehouseId'] as String?;
    _driverController.text = doc?.metadata['driverName'] as String? ?? '';
    _vehicleController.text = doc?.metadata['vehiclePlate'] as String? ?? '';
    _destinationController.text = doc?.metadata['destination'] as String? ?? '';
    _noteController.text = doc?.note ?? '';
    if (doc != null) {
      _lines.addAll(doc.lines);
    }
  }

  @override
  void dispose() {
    _driverController.dispose();
    _vehicleController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addLine(Product product) {
    if (_lines.any((l) => l.productId == product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produit déjà présent dans la liste.')),
      );
      return;
    }

    setState(() {
      _lines.add(
        DocumentLine(
          productId: product.id,
          sku: product.sku,
          label: product.name,
          unitHt: product.saleHt,
          quantity: 1,
          tvaRate: product.tvaRate,
          serialNumbers: const [],
        ),
      );
    });
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final line = _lines[index];
      final newQty = (line.quantity + delta).clamp(1, 999999);
      _lines[index] = line.copyWith(quantity: newQty);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un produit.')),
      );
      return;
    }

    if (_sourceWarehouseId == null || _targetWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez les dépôts source et destination.'),
        ),
      );
      return;
    }

    if (_sourceWarehouseId == _targetWarehouseId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le dépôt de départ et de destination doivent être différents.',
          ),
        ),
      );
      return;
    }

    final doc = BusinessDocument(
      id:
          widget.initialDocument?.id ??
          'bs-${DateTime.now().microsecondsSinceEpoch}',
      type: DocumentType.bonSortie,
      number: _number,
      status: DocumentStatus.draft,
      partnerId: 'system-mobile',
      partnerName: 'Chargement Camion',
      partnerTaxId: '',
      partnerAddress: '',
      date: _date,
      lines: _lines,
      warehouseId: _sourceWarehouseId!,
      companySnapshot: widget.company,
      note: _noteController.text,
      metadata: {
        'targetWarehouseId': _targetWarehouseId,
        'driverName': _driverController.text,
        'vehiclePlate': _vehicleController.text,
        'destination': _destinationController.text,
      },
    );

    context.read<DocumentsCubit>().createDevis(
      doc,
    ); // Using generic create for draft
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.initialDocument == null
              ? 'Nouvelle Sortie Camion'
              : 'Modifier Sortie Camion',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Enregistrer Brouillon'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderPanel(),
              const SizedBox(height: 24),
              _buildLinesPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPanel() {
    return Panel(
      title: 'Informations Générales',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: BlocBuilder<WarehouseCubit, WarehouseState>(
                  builder: (context, state) {
                    final warehouses = context
                        .read<WarehouseCubit>()
                        .warehouses;
                    final sourceWarehouses = warehouses
                        .where((w) => w.active)
                        .toList();
                    return DropdownButtonFormField<String>(
                      initialValue: _sourceWarehouseId,
                      decoration: const InputDecoration(
                        labelText: 'Dépôt de départ (Source)',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                      ),
                      items: sourceWarehouses.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _sourceWarehouseId = val),
                      validator: (val) => val == null ? 'Requis' : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BlocBuilder<WarehouseCubit, WarehouseState>(
                  builder: (context, state) {
                    final warehouses = context
                        .read<WarehouseCubit>()
                        .warehouses;
                    final mobileWarehouses = warehouses
                        .where((w) => w.active && w.type == 'mobile')
                        .toList();
                    if (mobileWarehouses.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Aucun dépôt mobile (camion) configuré.',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      initialValue: _targetWarehouseId,
                      decoration: const InputDecoration(
                        labelText: 'Véhicule / Dépôt mobile (Cible)',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      items: mobileWarehouses.map((w) {
                        return DropdownMenuItem(
                          value: w.id,
                          child: Text(w.name),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setState(() => _targetWarehouseId = val),
                      validator: (val) => val == null ? 'Requis' : null,
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _driverController,
                  decoration: const InputDecoration(
                    labelText: 'Chauffeur / Responsable',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _vehicleController,
                  decoration: const InputDecoration(
                    labelText: 'Matricule Véhicule',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _destinationController,
            decoration: const InputDecoration(
              labelText: 'Destination / Zone',
              prefixIcon: Icon(Icons.map_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes / Instructions',
              prefixIcon: Icon(Icons.note_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesPanel() {
    return Panel(
      title: 'Produits à charger',
      trailing: _buildProductPicker(),
      child: _lines.isEmpty
          ? const EmptyState(
              text: 'Aucun produit sélectionné.',
              icon: Icons.inventory_2_outlined,
            )
          : Column(
              children: [
                for (var i = 0; i < _lines.length; i++) _buildLineRow(i),
                const Divider(height: 32),
                _buildTotalFooter(),
              ],
            ),
    );
  }

  Widget _buildProductPicker() {
    return BlocBuilder<ProductsCubit, ProductsState>(
      builder: (context, state) {
        final activeProducts = state.products.where((p) => p.active).toList();
        return SizedBox(
          width: 300,
          child: Autocomplete<Product>(
            displayStringForOption: (p) => p.name,
            optionsBuilder: (textValue) {
              if (textValue.text.isEmpty) {
                return const Iterable<Product>.empty();
              }
              return activeProducts.where((p) {
                return p.name.toLowerCase().contains(
                      textValue.text.toLowerCase(),
                    ) ||
                    p.sku.toLowerCase().contains(textValue.text.toLowerCase());
              });
            },
            onSelected: _addLine,
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  hintText: 'Ajouter un produit...',
                  prefixIcon: Icon(Icons.search, size: 20),
                  isDense: true,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLineRow(int index) {
    final line = _lines[index];
    final stock = context.watch<StockCubit>().state.products.firstWhere(
      (p) => p.id == line.productId,
      orElse: () => Product.initial(),
    );
    final available = _sourceWarehouseId != null
        ? stock.stockIn(_sourceWarehouseId!)
        : 0;
    final isLow = available < line.quantity;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: .1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'SKU: ${line.sku} · Stock: $available',
                  style: TextStyle(
                    color: isLow ? AppColors.danger : AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _updateQuantity(index, -1),
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.muted,
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${line.quantity}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _updateQuantity(index, 1),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: () => _removeLine(index),
            icon: const Icon(Icons.delete_outline),
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter() {
    final totalQty = _lines.fold(0, (sum, l) => sum + l.quantity);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Text('Total produits:', style: TextStyle(color: AppColors.muted)),
        const SizedBox(width: 12),
        Text(
          '$totalQty',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
      ],
    );
  }
}
