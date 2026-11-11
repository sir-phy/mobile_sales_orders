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

  const OrderSummaryScreen({
    super.key,
    required this.orderNumber,
    required this.customer,
    required this.products,
  });

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  bool _isConfirming = false;

  double get _subtotal =>
      widget.products.fold(0, (s, p) => s + (p.unitPrice * p.quantity));
  double get _totalDiscount =>
      widget.products.fold(0, (s, p) => s + p.discount);
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
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            order: createdOrder,
            showSuccessBanner: true,
          ),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isConfirming = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm order: $e')),
      );
    }
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

          // Scrollable body
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

                  // Customer card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CUSTOMER',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                letterSpacing: 0.6,
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
                        const SizedBox(height: 8),
                        Text(
                          widget.customer.name,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.customer.contactName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.customer.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.customer.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Products section header
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

                  // Products list card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < widget.products.length; i++) ...[
                          _SummaryProductRow(product: widget.products[i]),
                          if (i < widget.products.length - 1)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Divider(height: 1, color: AppTheme.divider),
                            ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Separate Totals card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal · $_totalUnits ${_totalUnits == 1 ? 'unit' : 'units'}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            Text(
                              formatCurrency(_subtotal),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total discount',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.discountGreen,
                              ),
                            ),
                            Text(
                              '– ${formatCurrency(_totalDiscount)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.discountGreen,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(height: 1, color: AppTheme.divider),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Grand total',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Text(
                              formatCurrency(_grandTotal),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Confirmation note
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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

          // Sticky bottom confirm bar
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
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  disabledBackgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isConfirming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppTheme.white,
                        ),
                      )
                    : const Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Confirm order',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            child: Icon(
                              Icons.check,
                              color: AppTheme.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryProductRow extends StatelessWidget {
  final ProductItem product;

  const _SummaryProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          product.productCode,
          style: const TextStyle(fontSize: 11.5, color: AppTheme.textGrey),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${product.quantity} × ${formatCurrency(product.unitPrice)}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
            ),
            Text(
              formatCurrency(product.subtotal),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        if (product.discount > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Discount –${formatCurrency(product.discount)}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.discountGreen,
            ),
          ),
        ],
      ],
    );
  }
}
