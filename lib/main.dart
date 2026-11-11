import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/home_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/products_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/shared_widgets.dart';

void main() {
  runApp(const OrderlyApp());
}

class OrderlyApp extends StatelessWidget {
  const OrderlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orderly',
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
  int _selectedIndex = 0;

  void _onTabChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeScreen(onTabChanged: _onTabChanged),
                OrdersScreen(onBackToHome: () => _onTabChanged(0)),
                ProductsScreen(onBackToHome: () => _onTabChanged(0)),
                ProfileScreen(onBackToHome: () => _onTabChanged(0)),
              ],
            ),
          ),
          AppBottomNavBar(
            selectedIndex: _selectedIndex,
            onTap: _onTabChanged,
          ),
        ],
      ),
    );
  }
}
