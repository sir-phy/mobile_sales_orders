import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'order_detail_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final String orderNumber;
  final Customer customer;
  final List<ProductItem> products;
  final bool fromCart;

  const OrderSummaryScreen({
    super.key,
    required this.orderNumber,
    required this.customer,
    required this.products,
    this.fromCart = false,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool _isConfirming = false;

  double get _subtotal =>
      widget.products.fold(0, (s, p) => s + (p.unitPrice * p.quantity));
  double get _totalDiscount => widget.products.fold(0, (s, p) => s + p.discount);
  double get _grandTotal => (_subtotal - _totalDiscount).clamp(0, double.infinity);
  int get _totalUnits => widget.products.fold(0, (s, p) => s + p.quantity);

  Future<void> _confirmOrder() async {
    if (_isConfirming) return;
    setState(() => _isConfirming = true);
    try {
      final createdOrder = await SalesOrderStore.instance.confirmNewOrder(
        orderNumber: widget.orderNumber,
        customer: widget.customer,
        items: widget.products,
        fromCart: widget.fromCart,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: createdOrder, showSuccessBanner: true),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      final msg = e is ApiException ? e.message : 'Unable to confirm order. Please retry.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm order: $msg')),
      );
    }
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
                    title: 'Order summary',
                    showBack: true,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 10),
                    child: Text(
                      'Everything look right?',
                      style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey),
                    ),
                  ),
                  const StepIndicator(currentStep: 2),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.orderNumber,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const Text(
                        '11 Nov 2026',
                        style: TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomerInfoCard(
                    customer: widget.customer,
                    actionLabel: 'Edit',
                    onActionTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Selected products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OrderProductsListCard(products: widget.products),
                  const SizedBox(height: 14),
                  OrderTotalsCard(
                    totalUnits: _totalUnits,
                    subtotal: _subtotal,
                    totalDiscount: _totalDiscount,
                    grandTotal: _grandTotal,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPurple,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Confirming changes this order to Confirmed.',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          StickyPrimaryBottomBar(
            label: 'Confirm order',
            icon: Icons.check,
            isLoading: _isConfirming,
            onPressed: _confirmOrder,
          ),
        ],
      ),
    );
  }
}
