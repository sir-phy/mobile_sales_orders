import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';

class OrderProductRow extends StatelessWidget {
  final ProductItem product;

  const OrderProductRow({super.key, required this.product});

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

class OrderProductsListCard extends StatelessWidget {
  final List<ProductItem> products;

  const OrderProductsListCard({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (int i = 0; i < products.length; i++) ...[
            OrderProductRow(product: products[i]),
            if (i < products.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: AppTheme.divider),
              ),
          ],
        ],
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightPurple,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Icon(Icons.remove, size: 15, color: AppTheme.primaryPurple),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '$quantity',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryPurple,
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrement,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Icon(Icons.add, size: 15, color: AppTheme.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }
}

