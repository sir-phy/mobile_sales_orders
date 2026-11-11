import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<int> onTabChanged;

  const HomeScreen({
    super.key,
    required this.onTabChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    if (_store.overview == null) {
      _store.loadDashboard();
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _showNotificationsSheet() async {
    List<AppNotification> notifications = const [];
    try {
      notifications = await _store.api.fetchNotifications();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load notifications from server.')),
      );
      return;
    }
    if (!mounted) return;
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
                Text(
                  '${notifications.where((n) => !n.isRead).length} unread',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...notifications.map(
              (n) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: n.isRead ? AppTheme.scaffoldBg : AppTheme.lightPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      n.isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_outlined,
                      size: 18,
                      color: AppTheme.primaryPurple,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            n.subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      n.timeAgo,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPeriodPicker() async {
    const periods = ['This month', 'Last month', 'All time'];
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview period',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...periods.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  p,
                  style: TextStyle(
                    fontWeight: p == _store.selectedPeriod
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: p == _store.selectedPeriod
                        ? AppTheme.primaryPurple
                        : AppTheme.textDark,
                  ),
                ),
                trailing: p == _store.selectedPeriod
                    ? const Icon(Icons.check, color: AppTheme.primaryPurple)
                    : null,
                onTap: () => Navigator.of(ctx).pop(p),
              ),
            ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != _store.selectedPeriod) {
      await _store.loadDashboard(period: chosen);
    }
  }

  Future<void> _openOrderDetail(OrderItem order) async {
    try {
      final fullOrder = await _store.api.fetchOrderDetail(order.orderNumber);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: fullOrder),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _store.overview ??
        const DashboardOverview(
          totalOrders: 248,
          pendingOrders: 32,
          completedOrders: 216,
          growthText: '+18% vs Oct',
          completionRateText: '87% of orders',
          period: 'This month',
        );
    final recentOrders = _store.recentOrders;

    return Column(
      children: [
        // Purple Header
        Container(
          color: AppTheme.headerBg,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ORDERLY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryPurple,
                          letterSpacing: 1.2,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showNotificationsSheet,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            borderRadius: BorderRadius.circular(19),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Good morning, Alex',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your business, at a glance.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable body
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryPurple,
            onRefresh: () => _store.loadDashboard(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Overview section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Text(
                              'OVERVIEW',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGrey,
                                letterSpacing: 0.7,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showPeriodPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.lightPurple,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  overview.period,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryPurple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                value: '${overview.totalOrders}',
                                label: 'Total orders',
                                subtitle: overview.growthText,
                                subtitleColor: AppTheme.primaryPurple,
                                valueColor: AppTheme.primaryPurple,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                value: '${overview.pendingOrders}',
                                label: 'Pending',
                                subtitle: 'Needs action',
                                subtitleColor: AppTheme.orange,
                                valueColor: AppTheme.orange,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatCard(
                                value: '${overview.completedOrders}',
                                label: 'Completed',
                                subtitle: overview.completionRateText,
                                subtitleColor: AppTheme.green,
                                valueColor: AppTheme.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Create Order Banner
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CreateOrderScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPurple,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Less admin. More sales.',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Create new order',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: AppTheme.white,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Orders header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent orders',
                          style: TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => widget.onTabChanged(1),
                          child: const Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: recentOrders.isEmpty && _store.isDashboardLoading
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryPurple,
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentOrders.length,
                            separatorBuilder: (_, _) => const Divider(
                              height: 1,
                              color: AppTheme.divider,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (context, index) {
                              final order = recentOrders[index];
                              return InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openOrderDetail(order),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              order.orderNumber,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              order.customerName,
                                              style: const TextStyle(
                                                fontSize: 12.5,
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
                                            formatCurrency(order.amount),
                                            style: const TextStyle(
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          StatusBadge(status: order.status),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          overview.updatedLabel,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textGrey,
                          ),
                        ),
                        const Text(
                          'All amounts in USD',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final Color subtitleColor;
  final Color valueColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.subtitleColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: valueColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
