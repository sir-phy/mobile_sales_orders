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
  late OrderItem _order = widget.order;
  late bool _showSuccessBanner = widget.showSuccessBanner;
  bool _isUpdatingStatus = false;

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
      final msg = e is ApiException ? e.message : 'Unable to update order status.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update order: $msg')),
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
                      style: const TextStyle(fontSize: 13.5, color: AppTheme.textGrey),
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
                  if (_showSuccessBanner) ...[
                    const OrderSuccessBanner(),
                    const SizedBox(height: 14),
                  ],
                  OrderHeaderCard(order: _order),
                  const SizedBox(height: 12),
                  CustomerInfoCard(customer: customer),
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
                        '${products.length} ${products.length == 1 ? 'item' : 'items'} · $totalUnits ${totalUnits == 1 ? 'unit' : 'units'}',
                        style: const TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OrderProductsListCard(products: products),
                  const SizedBox(height: 14),
                  OrderTotalsCard(
                    totalUnits: totalUnits,
                    subtotal: subtotal,
                    totalDiscount: totalDiscount,
                    grandTotal: grandTotal,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          StickyPrimaryBottomBar(
            label: 'Create another order',
            icon: Icons.arrow_forward,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
