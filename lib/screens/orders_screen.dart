import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const OrdersScreen({super.key, this.onBackToHome});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _selectedFilter = 'All';
  bool _newestFirst = true;
  int _page = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  PaginatedOrdersResult? _result;

  final List<String> _filters = ['All', 'Pending', 'Confirmed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _fetchOrders(resetPage: true);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) {
      _fetchOrders(resetPage: false);
    }
  }

  Future<void> _fetchOrders({bool resetPage = true}) async {
    if (resetPage) {
      _page = 1;
      setState(() => _isLoading = true);
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final res = await _store.api.fetchOrders(
        status: _selectedFilter,
        query: _searchController.text,
        newestFirst: _newestFirst,
        page: _page,
        pageSize: 4,
      );
      if (!mounted) return;
      setState(() {
        _result = res;
      });
    } catch (_) {
      // Keep existing list state if network request fails.
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
                children: _filters.map((f) {
                  final selected = f == _selectedFilter;
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
                    onSelected: (_) {
                      setModalState(() => _selectedFilter = f);
                      setState(() => _selectedFilter = f);
                    },
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
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() => _newestFirst = true);
                        setState(() => _newestFirst = true);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _newestFirst ? AppTheme.lightPurple : null,
                        side: BorderSide(
                          color: _newestFirst
                              ? AppTheme.primaryPurple
                              : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        'Newest first',
                        style: TextStyle(
                          color: _newestFirst
                              ? AppTheme.primaryPurple
                              : AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() => _newestFirst = false);
                        setState(() => _newestFirst = false);
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: !_newestFirst ? AppTheme.lightPurple : null,
                        side: BorderSide(
                          color: !_newestFirst
                              ? AppTheme.primaryPurple
                              : AppTheme.divider,
                        ),
                      ),
                      child: Text(
                        'Oldest first',
                        style: TextStyle(
                          color: !_newestFirst
                              ? AppTheme.primaryPurple
                              : AppTheme.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _fetchOrders(resetPage: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply filters',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final orders = _result?.orders ?? const <OrderItem>[];
    final totalDataset = _result?.totalDatasetCount ?? 248;
    final hasMore = _result?.hasMore ?? false;

    final Widget content = Column(
      children: [
        // Purple header
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
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),
                const BreadcrumbRow(items: ['WORKSPACE', 'ORDERS']),
              ],
            ),
          ),
        ),

        // Search + filter + tabs
        Container(
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
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search order or customer',
                          hintStyle: const TextStyle(
                            color: AppTheme.textGrey,
                            fontSize: 13.5,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.textGrey,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _fetchOrders(resetPage: true);
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: AppTheme.textGrey,
                                  ),
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
                    onTap: _openFilterSheet,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppTheme.lightPurple,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppTheme.primaryPurple,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Filter pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((f) {
                    final bool selected = f == _selectedFilter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedFilter = f);
                          _fetchOrders(resetPage: true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 8,
                          ),
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
        ),

        // Orders list
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryPurple,
            onRefresh: () => _fetchOrders(resetPage: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedFilter == 'All'
                            ? 'All orders'
                            : '$_selectedFilter orders',
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
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppTheme.textGrey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _newestFirst
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              size: 13,
                              color: AppTheme.textGrey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading && orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    )
                  else if (orders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 36,
                            color: AppTheme.textGrey,
                          ),
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
                    )
                  else
                    ...orders.map(
                      (order) => _OrderCard(
                        order: order,
                        onTap: () => _openDetail(order),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${orders.length} of $totalDataset orders',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textGrey,
                        ),
                      ),
                      GestureDetector(
                        onTap: (!hasMore || _isLoadingMore)
                            ? null
                            : () {
                                _page += 1;
                                _fetchOrders(resetPage: false);
                              },
                        child: Text(
                          _isLoadingMore
                              ? 'Loading...'
                              : (hasMore ? 'Load more' : 'All loaded'),
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: hasMore
                                ? AppTheme.primaryPurple
                                : AppTheme.textGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.onBackToHome != null) {
      return content;
    }

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
}

class _OrderCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.onTap});

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
              crossAxisAlignment: CrossAxisAlignment.center,
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
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textGrey,
                  ),
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
