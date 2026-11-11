import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'create_order_screen.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback onBackToHome;

  const ProductsScreen({super.key, required this.onBackToHome});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;
  final TextEditingController _search = TextEditingController();
  List<ProductCatalogItem> _products = const [];
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

  Future<void> _load([String query = '']) async {
    setState(() => _loading = true);
    try {
      final items = await _store.api.fetchProducts(query: query);
      if (!mounted) return;
      setState(() {
        _products = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.headerBg,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBarContent(
                  title: 'Products',
                  showBack: true,
                  onBack: widget.onBackToHome,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 8),
                  child: Text(
                    'Catalog and live stock.',
                    style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey),
                  ),
                ),
                const BreadcrumbRow(items: ['WORKSPACE', 'PRODUCTS']),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _search,
              onChanged: _load,
              decoration: const InputDecoration(
                hintText: 'Search product name or code',
                hintStyle: TextStyle(color: AppTheme.textGrey, fontSize: 13.5),
                prefixIcon: Icon(Icons.search, color: AppTheme.textGrey, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryPurple),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final item = _products[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.lightPurple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.view_in_ar_outlined,
                              color: AppTheme.primaryPurple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${item.productCode} · ${item.category} · ${item.stock} units',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatCurrency(item.unitPrice),
                                style: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryPurple,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CreateOrderScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '+ Order',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

