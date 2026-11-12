import 'package:flutter/material.dart';
import '../core/theme.dart';

class AppBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isSellLead;
  final int unreadAlerts;

  const AppBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
    this.isSellLead = false,
    this.unreadAlerts = 0,
  });

  @override
  Widget build(BuildContext context) {
    final items = isSellLead
        ? [
            _NavItem(
              icon: Icons.view_in_ar_outlined,
              label: 'Products',
              index: 0,
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.notifications_active_outlined,
              label: 'Sell Lead',
              index: 1,
              selectedIndex: selectedIndex,
              onTap: onTap,
              badgeCount: unreadAlerts,
            ),
            _NavItem(
              icon: Icons.article_outlined,
              label: 'Orders',
              index: 2,
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              index: 3,
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
          ]
        : [
            _NavItem(
              icon: Icons.view_in_ar_outlined,
              label: 'Products',
              index: 0,
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.article_outlined,
              label: 'Orders',
              index: 1,
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              index: 2,
              selectedIndex: selectedIndex,
              onTap: onTap,
            ),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        border: Border(
          top: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == selectedIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.lightPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppTheme.primaryPurple : AppTheme.textGrey,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppTheme.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: AppTheme.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppTheme.primaryPurple : AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

