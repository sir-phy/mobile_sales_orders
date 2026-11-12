import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'order_detail_screen.dart';

class SellLeadScreen extends StatefulWidget {
  final VoidCallback onViewAllOrders;

  const SellLeadScreen({super.key, required this.onViewAllOrders});

  @override
  State<SellLeadScreen> createState() => _SellLeadScreenState();
}

class _SellLeadScreenState extends State<SellLeadScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;
  DashboardOverview? _overview;
  List<OrderItem> _recentOrders = const [];
  bool _loading = true;
  int _lastOrderVersion = 0;

  @override
  void initState() {
    super.initState();
    _lastOrderVersion = _store.orderVersion;
    _store.addListener(_onStoreChanged);
    _load();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    if (_store.orderVersion != _lastOrderVersion) {
      _lastOrderVersion = _store.orderVersion;
      _load();
    } else {
      setState(() {});
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await _store.refreshNotifications();
      final results = await Future.wait([
        _store.api.fetchDashboardOverview(),
        _store.api.fetchRecentOrders(limit: 4),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as DashboardOverview;
        _recentOrders = results[1] as List<OrderItem>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openOrder(String orderNumber) async {
    try {
      final full = await _store.api.fetchOrderDetail(orderNumber);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: full),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open $orderNumber')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _store.notifications;
    final unread = _store.unreadNotificationCount;

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
                  title: 'Sell Lead Hub',
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryPurple),
                    onPressed: _load,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  child: Text(
                    'Welcome, ${_store.currentUser?.name ?? 'Sell Lead'} • $unread unread customer alert(s)',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textGrey),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppTheme.primaryPurple,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildKpiRow(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Customer Order Alerts',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.redBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread NEW',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.red,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (unread > 0)
                      TextButton(
                        onPressed: _store.markAllNotificationsRead,
                        child: const Text('Mark all read'),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (notifications.isEmpty)
                  _emptyCard('No customer order alerts yet.')
                else
                  ...notifications.take(8).map((n) => _alertTile(n)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onViewAllOrders,
                      child: const Text('View all'),
                    ),
                  ],
                ),
                if (_loading && _recentOrders.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else
                  ..._recentOrders.map(_recentOrderTile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiRow() {
    final total = _overview?.totalOrders ?? 0;
    final pending = _overview?.pendingOrders ?? 0;
    final confirmed = _overview?.completedOrders ?? 0;
    return Row(
      children: [
        _kpiCard('Total', '$total', AppTheme.primaryPurple, AppTheme.lightPurple),
        const SizedBox(width: 10),
        _kpiCard('Pending', '$pending', AppTheme.orange, AppTheme.orangeBg),
        const SizedBox(width: 10),
        _kpiCard('Confirmed', '$confirmed', AppTheme.green, AppTheme.greenBg),
      ],
    );
  }

  Widget _kpiCard(String label, String value, Color fg, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
              child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(AppNotification n) {
    return GestureDetector(
      onTap: () {
        _store.markNotificationRead(n.id);
        if (n.orderNumber != null && n.orderNumber!.isNotEmpty) {
          _openOrder(n.orderNumber!);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isRead ? AppTheme.white : AppTheme.lightPurple.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isRead ? AppTheme.divider : AppTheme.softPurpleBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              n.isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
              color: n.isRead ? AppTheme.textGrey : AppTheme.primaryPurple,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(n.subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
                ],
              ),
            ),
            Text(n.timeAgo, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ],
        ),
      ),
    );
  }

  Widget _recentOrderTile(OrderItem o) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(o.customerName, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
              ],
            ),
            Text(
              '\$${o.amount.toStringAsFixed(0)} • ${o.status}',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: statusColor(o.status)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppTheme.white, borderRadius: BorderRadius.circular(14)),
      child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textGrey)),
    );
  }
}
