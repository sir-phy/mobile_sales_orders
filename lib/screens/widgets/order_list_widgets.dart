import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';

class OrderHistoryCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onTap;

  const OrderHistoryCard({super.key, required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryPurple,
                  ),
                ),
                StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.customerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.date,
                  style: const TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
                ),
                Text(
                  formatCurrency(order.amount),
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyOrdersCard extends StatelessWidget {
  const EmptyOrdersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.textGrey),
          SizedBox(height: 10),
          Text(
            'No matching orders',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try another search term or status filter.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }
}

class OrderFilterSheet extends StatefulWidget {
  final List<String> filters;
  final String selectedFilter;
  final bool newestFirst;
  final void Function(String filter, bool newestFirst) onApply;

  const OrderFilterSheet({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.newestFirst,
    required this.onApply,
  });

  @override
  State<OrderFilterSheet> createState() => _OrderFilterSheetState();
}

class _OrderFilterSheetState extends State<OrderFilterSheet> {
  late String _status = widget.selectedFilter;
  late bool _newestFirst = widget.newestFirst;

  Widget _sortButton(String label, bool targetNewest) {
    final active = _newestFirst == targetNewest;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() => _newestFirst = targetNewest),
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? AppTheme.lightPurple : null,
          side: BorderSide(
            color: active ? AppTheme.primaryPurple : AppTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppTheme.primaryPurple : AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter & sort orders',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Status',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: widget.filters.map((f) {
              final selected = f == _status;
              return ChoiceChip(
                label: Text(f),
                selected: selected,
                selectedColor: AppTheme.primaryPurple,
                backgroundColor: AppTheme.scaffoldBg,
                labelStyle: TextStyle(
                  color: selected ? AppTheme.white : AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide.none,
                onSelected: (_) => setState(() => _status = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sort order',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _sortButton('Newest first', true),
              const SizedBox(width: 10),
              _sortButton('Oldest first', false),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onApply(_status, _newestFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Apply filters',
                style: TextStyle(color: AppTheme.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

