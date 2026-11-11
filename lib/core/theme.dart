import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryPurple = Color(0xFF6D1ED4);
  static const Color lightPurple = Color(0xFFEFE8FF);
  static const Color headerBg = Color(0xFFEAE0FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF7F6FB);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF181826);
  static const Color textGrey = Color(0xFF6E6A7C);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFECEAF2);
  static const Color green = Color(0xFF15803D);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color orange = Color(0xFFB45309);
  static const Color orangeBg = Color(0xFFFEF3C7);
  static const Color red = Color(0xFFB91C1C);
  static const Color redBg = Color(0xFFFEE2E2);
  static const Color errorBannerBg = Color(0xFFFDECEC);
  static const Color inputBorder = Color(0xFFD5D2E0);
  static const Color discountGreen = Color(0xFF15803D);
  static const Color disabledBtnBg = Color(0xFFDDD6E8);
  static const Color disabledBtnText = Color(0xFF7A7289);
  static const Color softPurpleBorder = Color(0xFFC4B5FD);

  static ThemeData get theme => ThemeData(
        scaffoldBackgroundColor: scaffoldBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryPurple,
          primary: primaryPurple,
        ),
        useMaterial3: true,
      );
}

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return AppTheme.green;
    case 'pending':
      return AppTheme.orange;
    case 'cancelled':
      return AppTheme.red;
    default:
      return AppTheme.textGrey;
  }
}

Color statusBgColor(String status) {
  switch (status.toLowerCase()) {
    case 'confirmed':
      return AppTheme.greenBg;
    case 'pending':
      return AppTheme.orangeBg;
    case 'cancelled':
      return AppTheme.redBg;
    default:
      return AppTheme.divider;
  }
}

/// Formats numeric amounts with comma grouping without decimals, e.g. `7,170`.
String formatAmount(double amount) {
  return amount
      .round()
      .toString()
      .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
}

String formatCurrency(double amount) => '\$${formatAmount(amount)}';
