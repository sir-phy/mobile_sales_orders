import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class ProductInputCard extends StatefulWidget {
  final ProductItem product;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  const ProductInputCard({
    super.key,
    required this.product,
    required this.index,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<ProductInputCard> createState() => _ProductInputCardState();
}

class _ProductInputCardState extends State<ProductInputCard> {
  late final TextEditingController _discountController = TextEditingController(
    text: widget.product.discount.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Widget _qtyButton(String label, VoidCallback onTap) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 42,
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.primaryPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  InputBorder _fieldBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color),
      );

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
                      style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
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
          Row(
            children: [
              Expanded(child: _buildQuantityColumn()),
              const SizedBox(width: 12),
              Expanded(child: _buildDiscountColumn()),
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

  Widget _buildQuantityColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quantity', style: TextStyle(fontSize: 11.5, color: AppTheme.textGrey)),
        const SizedBox(height: 6),
        Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.inputBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _qtyButton('−', () {
                if (widget.product.quantity <= 1) return;
                setState(() => widget.product.quantity--);
                widget.onChanged();
              }),
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
              _qtyButton('+', () {
                setState(() => widget.product.quantity++);
                widget.onChanged();
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Discount (\$)', style: TextStyle(fontSize: 11.5, color: AppTheme.textGrey)),
        const SizedBox(height: 6),
        SizedBox(
          height: 42,
          child: TextField(
            controller: _discountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (val) {
              final parsed = double.tryParse(val) ?? 0;
              widget.product.discount = parsed < 0 ? 0 : parsed;
              widget.onChanged();
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: _fieldBorder(AppTheme.inputBorder),
              enabledBorder: _fieldBorder(AppTheme.inputBorder),
              focusedBorder: _fieldBorder(AppTheme.primaryPurple),
            ),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

