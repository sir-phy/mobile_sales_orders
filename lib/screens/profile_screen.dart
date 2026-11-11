import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../services/sales_order_api.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onBackToHome;

  const ProfileScreen({super.key, required this.onBackToHome});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SalesOrderStore _store = SalesOrderStore.instance;

  @override
  void initState() {
    super.initState();
    if (_store.profile == null) {
      _store.loadProfile().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _store.profile ??
        const UserProfile(
          name: 'Alex Morgan',
          role: 'Regional Sales Lead',
          email: 'alex@orderly.in',
          phone: '+91 98200 11223',
          workspaceName: 'Orderly Workspace',
          currency: 'USD (\$)',
        );

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
                  title: 'Profile',
                  showBack: true,
                  onBack: widget.onBackToHome,
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 8),
                  child: Text(
                    'Account and workspace preferences.',
                    style: TextStyle(fontSize: 13.5, color: AppTheme.textGrey),
                  ),
                ),
                const BreadcrumbRow(items: ['WORKSPACE', 'PROFILE']),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.lightPurple,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: const Center(
                          child: Text(
                            'AM',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.role,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _ProfileRow(label: 'WORKSPACE', value: profile.workspaceName),
                      const Divider(height: 22, color: AppTheme.divider),
                      _ProfileRow(label: 'EMAIL', value: profile.email),
                      const Divider(height: 22, color: AppTheme.divider),
                      _ProfileRow(label: 'PHONE', value: profile.phone),
                      const Divider(height: 22, color: AppTheme.divider),
                      _ProfileRow(label: 'CURRENCY', value: profile.currency),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textGrey,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}

