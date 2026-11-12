import 'package:flutter/material.dart';
import '../../core/theme.dart';

class EmptyProductsCard extends StatelessWidget {
  final VoidCallback onAddProduct;

  const EmptyProductsCard({super.key, required this.onAddProduct});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.view_in_ar_outlined, size: 38, color: AppTheme.primaryPurple),
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
            style: TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onAddProduct,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
    );
  }
}

class AddMoreProductButton extends StatelessWidget {
  final VoidCallback onTap;

  const AddMoreProductButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.softPurpleBorder, width: 1),
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
    );
  }
}

class CreateOrderBottomBar extends StatelessWidget {
  final int totalUnits;
  final double grandTotal;
  final bool hasProducts;
  final bool isSavingDraft;
  final bool canReview;
  final VoidCallback onReview;

  const CreateOrderBottomBar({
    super.key,
    required this.totalUnits,
    required this.grandTotal,
    required this.hasProducts,
    required this.isSavingDraft,
    required this.canReview,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          if (hasProducts) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalUnits ${totalUnits == 1 ? 'unit' : 'units'}  ·  Total ${formatCurrency(grandTotal)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                Text(
                  isSavingDraft ? 'Saving draft...' : 'Saved as draft',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textGrey),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onReview,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canReview ? AppTheme.primaryPurple : AppTheme.disabledBtnBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      color: canReview ? AppTheme.white : AppTheme.disabledBtnText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: canReview ? AppTheme.white : AppTheme.disabledBtnText,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

