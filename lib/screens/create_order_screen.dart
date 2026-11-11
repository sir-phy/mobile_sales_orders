import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'order_summary_screen.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;

  String _orderNumber = 'SO-2026-0149';
  Customer? _selectedCustomer;
  final List<ProductItem> _products = [];
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
    try {
      final nextNumber = await _store.api.generateNextOrderNumber();
      await _store.loadCatalogAndCustomers();
      if (!mounted) return;
      setState(() {
        _orderNumber = nextNumber;
      });
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
      if (mounted) {
        setState(() => _isSavingDraft = false);
      }
    });
  }

  Future<void> _selectCustomer() async {
    final selected = await showModalBottomSheet<Customer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CustomerPickerSheet(
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
      builder: (ctx) => _ProductPickerSheet(
        api: _store.api,
        existingCodes: _products.map((p) => p.productCode).toSet(),
      ),
    );
    if (chosen != null) {
      setState(() {
        final existingIndex = _products.indexWhere(
          (p) => p.productCode == chosen.productCode,
        );
        if (existingIndex != -1) {
          _products[existingIndex].quantity += 1;
        } else {
          _products.add(chosen.toOrderItem());
        }
      });
      _scheduleDraftSave();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          // Purple header
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

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Validation error banner
                  if (_triedSubmit && !_canReview) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorBannerBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A couple of details are missing',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.red,
                              fontSize: 13.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Select a customer and add at least one product.',
                            style: TextStyle(
                              color: AppTheme.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Order number card
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPurple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ORDER NUMBER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textGrey,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _orderNumber,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          'Auto-generated',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Customer section
                  const Text(
                    'Customer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select customer *',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _selectCustomer,
                          child: Container(
                            height: 46,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (_triedSubmit && !_hasCustomer)
                                    ? AppTheme.red
                                    : AppTheme.inputBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedCustomer?.name ?? 'Choose a customer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedCustomer != null
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: _selectedCustomer != null
                                        ? AppTheme.textDark
                                        : AppTheme.textGrey,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: (_triedSubmit && !_hasCustomer)
                                      ? AppTheme.red
                                      : AppTheme.primaryPurple,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_triedSubmit && !_hasCustomer) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Please select a customer to continue.',
                            style: TextStyle(fontSize: 12, color: AppTheme.red),
                          ),
                        ],
                        if (_selectedCustomer != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'CONTACT NAME',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedCustomer!.contactName,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'PHONE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedCustomer!.phone,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'EMAIL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textGrey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedCustomer!.email,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Products section
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
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_products.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 32,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.view_in_ar_outlined,
                            size: 38,
                            color: AppTheme.primaryPurple,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Your order starts here',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add products to build your sales order.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textGrey,
                            ),
                          ),
                          const SizedBox(height: 18),
                          GestureDetector(
                            onTap: _addProduct,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.lightPurple,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '+  Add product',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._products.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final product = entry.value;
                      return _ProductInputCard(
                        key: ValueKey(product.id),
                        product: product,
                        index: idx,
                        onRemove: () => _removeProduct(product.id),
                        onChanged: () {
                          setState(() {});
                          _scheduleDraftSave();
                        },
                      );
                    }),

                  if (_triedSubmit && !_hasProducts) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Add at least one product to continue.',
                      style: TextStyle(fontSize: 12, color: AppTheme.red),
                    ),
                  ],

                  if (_products.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _addProduct,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppTheme.softPurpleBorder,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '+  Add product',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.white,
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_products.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_totalUnits ${_totalUnits == 1 ? 'unit' : 'units'}  ·  Total ${formatCurrency(_grandTotal)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      Text(
                        _isSavingDraft ? 'Saving draft...' : 'Saved as draft',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
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
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canReview
                          ? AppTheme.primaryPurple
                          : AppTheme.disabledBtnBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Review order',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: _canReview
                                ? AppTheme.white
                                : AppTheme.disabledBtnText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: _canReview
                              ? AppTheme.white
                              : AppTheme.disabledBtnText,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInputCard extends StatefulWidget {
  final ProductItem product;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const _ProductInputCard({
    super.key,
    required this.product,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_ProductInputCard> createState() => _ProductInputCardState();
}

class _ProductInputCardState extends State<_ProductInputCard> {
  late TextEditingController _discountController;

  @override
  void initState() {
    super.initState();
    _discountController = TextEditingController(
      text: widget.product.discount.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final badgeNumber = (widget.index + 1).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.lightPurple,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    badgeNumber,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryPurple,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.product.productCode}  ·  ${formatCurrency(widget.product.unitPrice)} / unit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onRemove,
                child: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.textGrey,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Quantity + Discount row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantity',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.inputBorder),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (widget.product.quantity > 1) {
                                setState(() => widget.product.quantity--);
                                widget.onChanged();
                              }
                            },
                            child: const SizedBox(
                              width: 40,
                              height: 42,
                              child: Center(
                                child: Text(
                                  '−',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppTheme.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${widget.product.quantity}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() => widget.product.quantity++);
                              widget.onChanged();
                            },
                            child: const SizedBox(
                              width: 40,
                              height: 42,
                              child: Center(
                                child: Text(
                                  '+',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppTheme.primaryPurple,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discount (\$)',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.textGrey),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 42,
                      child: TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (val) {
                          widget.product.discount = double.tryParse(val) ?? 0;
                          widget.onChanged();
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.inputBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primaryPurple),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.divider),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Item subtotal',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
              ),
              Text(
                formatCurrency(widget.product.subtotal),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final SalesOrderApi api;
  final Customer? selectedCustomer;

  const _CustomerPickerSheet({
    required this.api,
    this.selectedCustomer,
  });

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<Customer> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([String q = '']) async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.fetchCustomers(query: q);
      if (!mounted) return;
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select customer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _search,
              onChanged: _load,
              decoration: const InputDecoration(
                hintText: 'Search customer or contact',
                prefixIcon: Icon(Icons.search, size: 19, color: AppTheme.textGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppTheme.divider),
                    itemBuilder: (_, i) {
                      final c = _items[i];
                      final isSelected = widget.selectedCustomer == c;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          c.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        subtitle: Text(
                          '${c.contactName} · ${c.phone}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppTheme.primaryPurple)
                            : null,
                        onTap: () => Navigator.of(context).pop(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  final SalesOrderApi api;
  final Set<String> existingCodes;

  const _ProductPickerSheet({
    required this.api,
    required this.existingCodes,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<ProductCatalogItem> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([String q = '']) async {
    setState(() => _loading = true);
    try {
      final res = await widget.api.fetchProducts(query: q);
      if (!mounted) return;
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add product',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _search,
              onChanged: _load,
              decoration: const InputDecoration(
                hintText: 'Search product name or code',
                prefixIcon: Icon(Icons.search, size: 19, color: AppTheme.textGrey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 340),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppTheme.divider),
                    itemBuilder: (_, i) {
                      final p = _items[i];
                      final alreadyAdded =
                          widget.existingCodes.contains(p.productCode);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          p.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        subtitle: Text(
                          '${p.productCode} · ${p.category} · ${p.stock} in stock',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formatCurrency(p.unitPrice),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                            if (alreadyAdded)
                              const Text(
                                'Added (+1)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
