import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/sales_order_api.dart';

class SearchPickerSheet<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final double maxListHeight;
  final Future<List<T>> Function(String query) fetcher;
  final Widget Function(BuildContext context, T item) itemBuilder;

  const SearchPickerSheet({
    super.key,
    required this.title,
    required this.searchHint,
    required this.fetcher,
    required this.itemBuilder,
    this.maxListHeight = 320,
  });

  @override
  State<SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<SearchPickerSheet<T>> {
  final TextEditingController _search = TextEditingController();
  List<T> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([String q = '']) async {
    setState(() => _loading = true);
    try {
      final res = await widget.fetcher(q);
      if (!mounted) return;
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _search,
              onChanged: _load,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 19, color: AppTheme.textGrey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxListHeight),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppTheme.divider),
                    itemBuilder: (ctx, i) => widget.itemBuilder(ctx, _items[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomerPickerSheet extends StatelessWidget {
  final SalesOrderApi api;
  final Customer? selectedCustomer;

  const CustomerPickerSheet({
    super.key,
    required this.api,
    this.selectedCustomer,
  });

  @override
  Widget build(BuildContext context) {
    return SearchPickerSheet<Customer>(
      title: 'Select customer',
      searchHint: 'Search customer or contact',
      fetcher: (q) => api.fetchCustomers(query: q),
      itemBuilder: (ctx, c) {
        final isSelected = selectedCustomer == c;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            c.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          subtitle: Text(
            '${c.contactName} · ${c.phone}',
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: AppTheme.primaryPurple)
              : null,
          onTap: () => Navigator.of(ctx).pop(c),
        );
      },
    );
  }
}

class ProductPickerSheet extends StatelessWidget {
  final SalesOrderApi api;
  final Set<String> existingCodes;

  const ProductPickerSheet({
    super.key,
    required this.api,
    required this.existingCodes,
  });

  @override
  Widget build(BuildContext context) {
    return SearchPickerSheet<ProductCatalogItem>(
      title: 'Add product',
      searchHint: 'Search product name or code',
      maxListHeight: 340,
      fetcher: (q) => api.fetchProducts(query: q),
      itemBuilder: (ctx, p) {
        final alreadyAdded = existingCodes.contains(p.productCode);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            p.name,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark),
          ),
          subtitle: Text(
            '${p.productCode} · ${p.category} · ${p.stock} in stock',
            style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatCurrency(p.unitPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryPurple,
                ),
              ),
              if (alreadyAdded)
                const Text(
                  'Added (+1)',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          onTap: () => Navigator.of(ctx).pop(p),
        );
      },
    );
  }
}

