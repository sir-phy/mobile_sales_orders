import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/sales_order_api.dart';
import '../../widgets/shared_widgets.dart';

class CartBottomBar extends StatelessWidget {
  final int totalUnits;
  final double totalAmount;
  final VoidCallback onViewCart;
  final VoidCallback onOrderAll;

  const CartBottomBar({
    super.key,
    required this.totalUnits,
    required this.totalAmount,
    required this.onViewCart,
    required this.onOrderAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onViewCart,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalUnits ${totalUnits == 1 ? 'item' : 'items'} in cart',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatCurrency(totalAmount),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: onOrderAll,
            icon: const Icon(
              Icons.shopping_bag_outlined,
              size: 18,
              color: AppTheme.white,
            ),
            label: const Text(
              'Order all',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCartSheet extends StatefulWidget {
  final SalesOrderStore store;
  final VoidCallback onCheckout;

  const ProductCartSheet({
    super.key,
    required this.store,
    required this.onCheckout,
  });

  @override
  State<ProductCartSheet> createState() => _ProductCartSheetState();
}

class _ProductCartSheetState extends State<ProductCartSheet> {
  @override
  Widget build(BuildContext context) {
    final items = widget.store.cartItems;
    final totalUnits = widget.store.cartTotalUnits;
    final totalAmount = widget.store.cartTotalAmount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cart ($totalUnits ${totalUnits == 1 ? 'item' : 'items'})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      widget.store.clearCart();
                      setState(() {});
                    },
                    child: const Text('Clear', style: TextStyle(color: AppTheme.red)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: Text(
                    'Your cart is empty. Tap a product to add it.',
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 13.5),
                  ),
                ),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 16, color: AppTheme.divider),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${formatCurrency(item.unitPrice)} × ${item.quantity} = ${formatCurrency(item.subtotal)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        QtyStepper(
                          quantity: item.quantity,
                          onDecrement: () {
                            widget.store.updateCartQuantity(item.productCode, -1);
                            setState(() {});
                          },
                          onIncrement: () {
                            widget.store.updateCartQuantity(item.productCode, 1);
                            setState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 19,
                            color: AppTheme.textGrey,
                          ),
                          onPressed: () {
                            widget.store.removeFromCart(item.productCode);
                            setState(() {});
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: widget.onCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Order all ($totalUnits) · ${formatCurrency(totalAmount)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

