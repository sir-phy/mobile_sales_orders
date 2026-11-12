import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'order_summary_screen.dart';
import 'widgets/create_order_bottom_widgets.dart';
import 'widgets/create_order_sections.dart';
import 'widgets/order_picker_sheets.dart';
import 'widgets/order_product_input_card.dart';

class CreateOrderScreen extends StatefulWidget {
  final List<ProductItem> initialProducts;
  final bool fromCart;

  const CreateOrderScreen({
    super.key,
    this.initialProducts = const [],
    this.fromCart = false,
  });

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;

  String _orderNumber = 'SO-2026-0149';
  Customer? _selectedCustomer;
  late final List<ProductItem> _products =
      widget.initialProducts.map((e) => e.copyWith()).toList();
  bool _triedSubmit = false;
  bool _isSavingDraft = false;
  Timer? _draftDebounce;

  bool get _hasCustomer => _selectedCustomer != null;
  bool get _hasProducts => _products.isNotEmpty;
  bool get _canReview => _hasCustomer && _hasProducts;
  int get _totalUnits => _products.fold(0, (s, p) => s + p.quantity);
  double get _grandTotal => _products.fold(0.0, (s, p) => s + p.subtotal);

  @override
  void initState() {
    super.initState();
    _initOrderForm();
  }

  @override
  void dispose() {
    _draftDebounce?.cancel();
    super.dispose();
  }

  Future<void> _initOrderForm() async {
    if (_store.isCustomer && _store.currentUser?.customer != null) {
      _selectedCustomer = _store.currentUser!.customer;
    }
    try {
      final nextNumber = await _store.api.generateNextOrderNumber();
      await _store.loadCatalogAndCustomers();
      if (!mounted) return;
      setState(() => _orderNumber = nextNumber);
    } catch (_) {}
  }

  void _scheduleDraftSave() {
    _draftDebounce?.cancel();
    setState(() => _isSavingDraft = true);
    _draftDebounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        await _store.api.saveDraftOrder(
          orderNumber: _orderNumber,
          customer: _selectedCustomer,
          items: _products,
        );
      } catch (_) {}
      if (mounted) setState(() => _isSavingDraft = false);
    });
  }

  Future<void> _selectCustomer() async {
    if (_store.isCustomer && _store.currentUser?.customer != null) {
      return;
    }
    final selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CustomerPickerSheet(
        api: _store.api,
        selectedCustomer: _selectedCustomer,
      ),
    );
    if (selected != null) {
      setState(() => _selectedCustomer = selected);
      _scheduleDraftSave();
    }
  }

  Future<void> _addProduct() async {
    final chosen = await showModalBottomSheet<ProductCatalogItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductPickerSheet(
        api: _store.api,
        existingCodes: _products.map((p) => p.productCode).toSet(),
      ),
    );
    if (chosen == null) return;
    setState(() {
      final idx = _products.indexWhere((p) => p.productCode == chosen.productCode);
      if (idx != -1) {
        _products[idx].quantity += 1;
      } else {
        _products.add(chosen.toOrderItem());
      }
    });
    _scheduleDraftSave();
  }

  void _removeProduct(String id) {
    setState(() => _products.removeWhere((p) => p.id == id));
    _scheduleDraftSave();
  }

  void _openMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_fix_high, color: AppTheme.primaryPurple),
              title: const Text('Fill sample order (Acme Retail)'),
              onTap: () async {
                Navigator.of(ctx).pop();
                final custs = await _store.api.fetchCustomers();
                if (!mounted || custs.isEmpty) return;
                setState(() {
                  _selectedCustomer = custs.first;
                  _products
                    ..clear()
                    ..addAll(defaultProducts);
                  _triedSubmit = false;
                });
                _scheduleDraftSave();
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.delete_sweep_outlined, color: AppTheme.red),
              title: const Text('Clear draft'),
              onTap: () {
                Navigator.of(ctx).pop();
                setState(() {
                  _selectedCustomer = null;
                  _products.clear();
                  _triedSubmit = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleReview() {
    if (!_canReview) {
      setState(() => _triedSubmit = true);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderSummaryScreen(
          orderNumber: _orderNumber,
          customer: _selectedCustomer!,
          products: _products,
          fromCart: widget.fromCart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          Container(
            color: AppTheme.headerBg,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBarContent(
                    title: 'Create sales order',
                    showBack: true,
                    onBack: () => Navigator.of(context).pop(),
                    onMoreTap: _openMoreMenu,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 10),
                    child: Text(
                      'Build an order in a few simple steps.',
                      style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey),
                    ),
                  ),
                  const StepIndicator(currentStep: 1),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_triedSubmit && !_canReview) ...[
                    const OrderValidationBanner(),
                    const SizedBox(height: 16),
                  ],
                  OrderNumberCard(orderNumber: _orderNumber),
                  const SizedBox(height: 22),
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CreateCustomerCard(
                    selectedCustomer: _selectedCustomer,
                    showError: _triedSubmit && !_hasCustomer,
                    onTap: _selectCustomer,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '${_products.length} ${_products.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_products.isEmpty)
                    EmptyProductsCard(onAddProduct: _addProduct)
                  else
                    ..._products.asMap().entries.map(
                          (entry) => ProductInputCard(
                            key: ValueKey(entry.value.id),
                            product: entry.value,
                            index: entry.key,
                            onRemove: () => _removeProduct(entry.value.id),
                            onChanged: () {
                              setState(() {});
                              _scheduleDraftSave();
                            },
                          ),
                        ),
                  if (_triedSubmit && !_hasProducts) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Add at least one product to continue.',
                      style: TextStyle(fontSize: 12, color: AppTheme.red),
                    ),
                  ],
                  if (_products.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    AddMoreProductButton(onTap: _addProduct),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          CreateOrderBottomBar(
            totalUnits: _totalUnits,
            grandTotal: _grandTotal,
            hasProducts: _hasProducts,
            isSavingDraft: _isSavingDraft,
            canReview: _canReview,
            onReview: _handleReview,
          ),
        ],
      ),
    );
  }
}
