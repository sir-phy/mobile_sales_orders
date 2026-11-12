import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'create_order_screen.dart';
import 'login_screen.dart';
import 'order_detail_screen.dart';
import 'widgets/order_list_widgets.dart';
import 'widgets/orders_search_bar.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const OrdersScreen({super.key, this.onBackToHome});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const List<String> _filters = ['All', 'Pending', 'Confirmed', 'Cancelled'];

  final SalesOrderStore _store = SalesOrderStore.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _selectedFilter = 'All';
  bool _newestFirst = true;
  int _page = 1;
  int _lastOrderVersion = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  PaginatedOrdersResult? _result;

  @override
  void initState() {
    super.initState();
    _lastOrderVersion = _store.orderVersion;
    _store.addListener(_onStoreChanged);
    if (_store.isLoggedIn) {
      _fetchOrders(resetPage: true);
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted || _store.orderVersion == _lastOrderVersion) return;
    _lastOrderVersion = _store.orderVersion;
    _fetchOrders(resetPage: false);
  }

  Future<void> _fetchOrders({bool resetPage = true}) async {
    if (!_store.isLoggedIn) return;
    if (resetPage) _page = 1;
    setState(() {
      if (resetPage) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final res = await _store.api.fetchOrders(
        status: _selectedFilter,
        query: _searchController.text,
        newestFirst: _newestFirst,
        page: _page,
        pageSize: 4,
      );
      if (!mounted) return;
      setState(() => _result = res);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to reach backend API.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _fetchOrders(resetPage: true);
    });
    setState(() {});
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => OrderFilterSheet(
        filters: _filters,
        selectedFilter: _selectedFilter,
        newestFirst: _newestFirst,
        onApply: (filter, newest) {
          setState(() {
            _selectedFilter = filter;
            _newestFirst = newest;
          });
          _fetchOrders(resetPage: true);
        },
      ),
    );
  }

  void _openMoreMenu() {
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
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.add_circle_outline, color: AppTheme.primaryPurple),
              title: const Text('Create new sales order'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.refresh_rounded, color: AppTheme.textDark),
              title: const Text('Reset search & filters'),
              onTap: () {
                Navigator.of(ctx).pop();
                _searchController.clear();
                setState(() {
                  _selectedFilter = 'All';
                  _newestFirst = true;
                });
                _fetchOrders(resetPage: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(OrderItem order) async {
    try {
      final full = await _store.api.fetchOrderDetail(order.orderNumber);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: full)),
      );
    } catch (_) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_store.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 48, color: AppTheme.primaryPurple),
              const SizedBox(height: 12),
              const Text(
                'Login Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please sign in to view or place orders.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple,
                  foregroundColor: AppTheme.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }

    final orders = _result?.orders ?? const <OrderItem>[];
    final totalDataset = _result?.totalDatasetCount ?? 0;
    final hasMore = _result?.hasMore ?? false;

    final Widget content = Column(
      children: [
        Container(
          color: AppTheme.headerBg,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppBarContent(
                  title: 'Order history',
                  showBack: true,
                  onBack: widget.onBackToHome ?? () => Navigator.of(context).pop(),
                  onMoreTap: _openMoreMenu,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 8),
                  child: Text(
                    'Every order. One place.',
                    style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey),
                  ),
                ),
                const BreadcrumbRow(items: ['WORKSPACE', 'ORDERS']),
              ],
            ),
          ),
        ),
        OrdersSearchFilterBar(
          controller: _searchController,
          filters: _filters,
          selectedFilter: _selectedFilter,
          onSearchChanged: _onSearchChanged,
          onClearSearch: () {
            _searchController.clear();
            _fetchOrders(resetPage: true);
          },
          onOpenFilterSheet: _openFilterSheet,
          onSelectFilter: (f) {
            setState(() => _selectedFilter = f);
            _fetchOrders(resetPage: true);
          },
        ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryPurple,
            onRefresh: () => _fetchOrders(resetPage: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: _buildOrderListBody(orders, totalDataset, hasMore),
            ),
          ),
        ),
      ],
    );

    if (widget.onBackToHome != null) return content;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          Expanded(child: content),
          AppBottomNavBar(
            selectedIndex: 1,
            onTap: (i) {
              if (i != 1) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderListBody(List<OrderItem> orders, int totalDataset, bool hasMore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedFilter == 'All' ? 'All orders' : '$_selectedFilter orders',
              style: const TextStyle(
                fontSize: 18.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() => _newestFirst = !_newestFirst);
                _fetchOrders(resetPage: true);
              },
              child: Row(
                children: [
                  Text(
                    _newestFirst ? 'Newest first' : 'Oldest first',
                    style: const TextStyle(fontSize: 12.5, color: AppTheme.textGrey),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _newestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 13,
                    color: AppTheme.textGrey,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ApiErrorBanner(
              message: _errorMessage!,
              onRetry: () => _fetchOrders(resetPage: true),
            ),
          ),
        if (_isLoading && orders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryPurple)),
          )
        else if (orders.isEmpty)
          const EmptyOrdersCard()
        else
          ...orders.map(
            (order) => OrderHistoryCard(order: order, onTap: () => _openDetail(order)),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${orders.length} of $totalDataset orders',
              style: const TextStyle(fontSize: 12, color: AppTheme.textGrey),
            ),
            GestureDetector(
              onTap: (!hasMore || _isLoadingMore)
                  ? null
                  : () {
                      _page += 1;
                      _fetchOrders(resetPage: false);
                    },
              child: Text(
                _isLoadingMore ? 'Loading...' : (hasMore ? 'Load more' : 'All loaded'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: hasMore ? AppTheme.primaryPurple : AppTheme.textGrey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
