import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'create_order_screen.dart';
import 'login_screen.dart';
import 'widgets/product_cart_widgets.dart';
import 'widgets/product_catalog_card.dart';

class ProductsScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;
  final bool showBack;

  const ProductsScreen({
    super.key,
    this.onBackToHome,
    this.showBack = false,
  });

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;
  final TextEditingController _search = TextEditingController();
  List<ProductCatalogItem> _products = const [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _load();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _search.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load([String query = '']) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final items = await _store.api.fetchProducts(query: query);
      if (!mounted) return;
      setState(() {
        _products = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Unable to load products from backend API.';
      });
    }
  }

  Future<void> _orderAllFromCart() async {
    if (_store.cartItems.isEmpty) return;
    if (!_store.isLoggedIn) {
      final user = await Navigator.of(context).push<AuthUser>(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(
            reason: 'Please sign in before placing your order.',
          ),
        ),
      );
      if (user == null || !mounted) return;
    }
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateOrderScreen(
          initialProducts: _store.cartItems,
          fromCart: true,
        ),
      ),
    );
  }

  Future<void> _openLogin() async {
    await Navigator.of(context).push<AuthUser>(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => ProductCartSheet(
        store: _store,
        onCheckout: () {
          Navigator.of(ctx).pop();
          _orderAllFromCart();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartUnits = _store.cartTotalUnits;

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
                  title: 'SELL • Products',
                  showBack: widget.showBack,
                  onBack: widget.onBackToHome,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: _store.isLoggedIn ? null : _openLogin,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _store.isLoggedIn ? AppTheme.lightPurple : AppTheme.primaryPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _store.isLoggedIn
                                ? _store.currentUser!.roleLabel
                                : 'Login',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: _store.isLoggedIn
                                  ? AppTheme.primaryPurple
                                  : AppTheme.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CartIconBadge(
                        count: cartUnits,
                        onTap: _openCartSheet,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 8),
                  child: Text(
                    'Tap a product to add it to your cart.',
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
        Expanded(child: _buildBody()),
        if (cartUnits > 0)
          CartBottomBar(
            totalUnits: cartUnits,
            totalAmount: _store.cartTotalAmount,
            onViewCart: _openCartSheet,
            onOrderAll: _orderAllFromCart,
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryPurple),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ApiErrorBanner(
            message: _errorMessage!,
            onRetry: () => _load(_search.text),
          ),
        ),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryPurple,
      onRefresh: () => _load(_search.text),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final item = _products[index];
          return ProductCatalogCard(
            item: item,
            qtyInCart: _store.cartQuantityFor(item.productCode),
            onAdd: () => _store.addToCart(item),
            onDecrement: () => _store.updateCartQuantity(item.productCode, -1),
            onIncrement: () => _store.updateCartQuantity(item.productCode, 1),
          );
        },
      ),
    );
  }
}
