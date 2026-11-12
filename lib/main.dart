import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sell_lead_screen.dart';
import 'services/sales_order_api.dart';
import 'widgets/shared_widgets.dart';

void main() {
  runApp(const OrderlyApp());
}

class OrderlyApp extends StatelessWidget {
  const OrderlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SELL',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final SalesOrderStore _store = SalesOrderStore.instance;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (!mounted) return;
    final maxIdx = _store.isSellLead ? 3 : 2;
    setState(() {
      if (_selectedIndex > maxIdx) _selectedIndex = 0;
    });
  }

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isLead = _store.isSellLead;
    final pages = isLead
        ? [
            const ProductsScreen(),
            SellLeadScreen(onViewAllOrders: () => _onTabChanged(2)),
            OrdersScreen(onBackToHome: () => _onTabChanged(0)),
            ProfileScreen(onBackToHome: () => _onTabChanged(0)),
          ]
        : [
            const ProductsScreen(),
            OrdersScreen(onBackToHome: () => _onTabChanged(0)),
            ProfileScreen(onBackToHome: () => _onTabChanged(0)),
          ];

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: safeIndex,
              children: pages,
            ),
          ),
          AppBottomNavBar(
            selectedIndex: safeIndex,
            onTap: _onTabChanged,
            isSellLead: isLead,
            unreadAlerts: _store.unreadNotificationCount,
          ),
        ],
      ),
    );
  }
}
