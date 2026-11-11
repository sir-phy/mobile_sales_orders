import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'create_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderItem order;
  final bool showSuccessBanner;

  const OrderDetailScreen({
    super.key,
    required this.order,
    this.showSuccessBanner = false,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderItem _order;
  late bool _showSuccessBanner;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _showSuccessBanner = widget.showSuccessBanner;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final updated = await SalesOrderStore.instance.changeOrderStatus(
        orderNumber: _order.orderNumber,
        status: newStatus,
      );
      if (!mounted) return;
      setState(() {
        _order = updated;
        _showSuccessBanner = newStatus == 'Confirmed';
        _isUpdatingStatus = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order: $e')),
      );
    }
  }

  void _openActionsMenu() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _order.orderNumber,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            if (_order.status != 'Confirmed')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline, color: AppTheme.green),
                title: const Text('Confirm order'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _updateStatus('Confirmed');
                },
              ),
            if (_order.status != 'Cancelled')
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.cancel_outlined, color: AppTheme.red),
                title: const Text('Cancel order'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _updateStatus('Cancelled');
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryPurple),
              title: const Text('Create another order'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _order.items.isNotEmpty ? _order.items : defaultProducts;
    final double subtotal = products.fold(0, (s, p) => s + (p.unitPrice * p.quantity));
    final double totalDiscount = products.fold(0, (s, p) => s + p.discount);
    final double grandTotal = (_order.items.isNotEmpty
            ? (subtotal - totalDiscount)
            : _order.amount)
        .clamp(0, double.infinity);
    final int totalUnits = products.fold(0, (s, p) => s + p.quantity);
    final customer = _order.customer ??
        Customer(
          name: _order.customerName,
          contactName: 'Priya Sharma',
          phone: '+91 98765 43210',
          email: 'priya@acmeretail.in',
        );

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
                    title: 'Order details',
                    showBack: true,
                    onBack: () => Navigator.of(context).pop(),
                    onMoreTap: _openActionsMenu,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 8),
                    child: Text(
                      _order.orderNumber,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),
                  const BreadcrumbRow(items: ['WORKSPACE', 'ORDER INFORMATION']),
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
                  if (_isUpdatingStatus)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        color: AppTheme.primaryPurple,
                        backgroundColor: AppTheme.lightPurple,
                      ),
                    ),

                  // Success Banner
                  if (_showSuccessBanner) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.greenBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.green,
                            size: 22,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order confirmed successfully',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.green,
                                    fontSize: 13.5,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your order is ready for processing.',
                                  style: TextStyle(
                                    color: AppTheme.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Order info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ORDER NUMBER',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _order.orderNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_order.date} · ${_order.time}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(status: _order.status),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Customer card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CUSTOMER',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textGrey,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.contactName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customer.phone,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer.email,
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
                        'Products',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        '${products.length} ${products.length == 1 ? 'item' : 'items'} · $totalUnits ${totalUnits == 1 ? 'unit' : 'units'}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Products card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < products.length; i++) ...[
                          _ProductRow(product: products[i]),
                          if (i < products.length - 1)
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
                              'Subtotal · $totalUnits ${totalUnits == 1 ? 'unit' : 'units'}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            Text(
                              formatCurrency(subtotal),
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
                              '– ${formatCurrency(totalDiscount)}',
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
                              formatCurrency(grandTotal),
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

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Sticky white bottom bar
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
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateOrderScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Create another order',
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
                        Icons.arrow_forward,
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

class _ProductRow extends StatelessWidget {
  final ProductItem product;

  const _ProductRow({required this.product});

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
