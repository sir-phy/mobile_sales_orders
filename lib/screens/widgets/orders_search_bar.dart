import 'package:flutter/material.dart';
import '../../core/theme.dart';

class OrdersSearchFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilterSheet;
  final ValueChanged<String> onSelectFilter;

  const OrdersSearchFilterBar({
    super.key,
    required this.controller,
    required this.filters,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilterSheet,
    required this.onSelectFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.scaffoldBg,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onSearchChanged,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: 'Search order or customer',
                      hintStyle: const TextStyle(color: AppTheme.textGrey, fontSize: 13.5),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textGrey, size: 20),
                      suffixIcon: controller.text.isNotEmpty
                          ? GestureDetector(
                              onTap: onClearSearch,
                              child: const Icon(Icons.close, size: 18, color: AppTheme.textGrey),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onOpenFilterSheet,
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.lightPurple,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.tune_rounded, color: AppTheme.primaryPurple, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final selected = f == selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onSelectFilter(f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryPurple : AppTheme.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? AppTheme.white : AppTheme.textGrey,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

