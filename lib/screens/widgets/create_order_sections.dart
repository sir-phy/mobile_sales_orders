import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class OrderValidationBanner extends StatelessWidget {
  const OrderValidationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.errorBannerBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A couple of details are missing',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.red,
              fontSize: 13.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Select a customer and add at least one product.',
            style: TextStyle(color: AppTheme.red, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class OrderNumberCard extends StatelessWidget {
  final String orderNumber;

  const OrderNumberCard({super.key, required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.lightPurple,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ORDER NUMBER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textGrey,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                orderNumber,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryPurple,
                ),
              ),
            ],
          ),
          const Text(
            'Auto-generated',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateCustomerCard extends StatelessWidget {
  final Customer? selectedCustomer;
  final bool showError;
  final VoidCallback onTap;

  const CreateCustomerCard({
    super.key,
    required this.selectedCustomer,
    required this.showError,
    required this.onTap,
  });

  Widget _metaField(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.textGrey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select customer *',
            style: TextStyle(fontSize: 12, color: AppTheme.textGrey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: showError ? AppTheme.red : AppTheme.inputBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedCustomer?.name ?? 'Choose a customer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selectedCustomer != null ? FontWeight.w600 : FontWeight.w400,
                      color:
                          selectedCustomer != null ? AppTheme.textDark : AppTheme.textGrey,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: showError ? AppTheme.red : AppTheme.primaryPurple,
                  ),
                ],
              ),
            ),
          ),
          if (showError) ...[
            const SizedBox(height: 8),
            const Text(
              'Please select a customer to continue.',
              style: TextStyle(fontSize: 12, color: AppTheme.red),
            ),
          ],
          if (selectedCustomer != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _metaField('CONTACT NAME', selectedCustomer!.contactName)),
                Expanded(child: _metaField('PHONE', selectedCustomer!.phone)),
              ],
            ),
            const SizedBox(height: 12),
            _metaField('EMAIL', selectedCustomer!.email),
          ],
        ],
      ),
    );
  }
}

