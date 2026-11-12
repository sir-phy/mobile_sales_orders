import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

const Set<String> allowedOrderStatuses = {'Pending', 'Confirmed', 'Cancelled'};

/// REST API contract for all Orderly screens.
abstract class SalesOrderApi {
  Future<DashboardOverview> fetchDashboardOverview({String period = 'This month'});

  Future<List<OrderItem>> fetchRecentOrders({int limit = 3});

  Future<PaginatedOrdersResult> fetchOrders({
    String status = 'All',
    String query = '',
    bool newestFirst = true,
    int page = 1,
    int pageSize = 4,
  });

  Future<OrderItem> fetchOrderDetail(String orderNumber);

  Future<String> generateNextOrderNumber();

  Future<OrderDraft> saveDraftOrder({
    required String orderNumber,
    Customer? customer,
    required List<ProductItem> items,
  });

  Future<OrderItem> createAndConfirmOrder({
    required String orderNumber,
    required Customer customer,
    required List<ProductItem> items,
  });

  Future<OrderItem> updateOrderStatus({
    required String orderNumber,
    required String status,
  });

  Future<List<Customer>> fetchCustomers({String query = ''});

  Future<List<ProductCatalogItem>> fetchProducts({String query = ''});

  Future<List<AppNotification>> fetchNotifications();

  Future<void> markNotificationRead(String id);

  Future<void> markAllNotificationsRead();

  Future<UserProfile> fetchUserProfile();

  void setAuthToken(String? token);

  Future<AuthSession> login({
    required String email,
    required String password,
  });

  Future<AuthSession> registerCustomer({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String companyName = '',
  });
}

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final fallback = (!kIsWeb && Platform.isAndroid)
        ? 'http://10.0.2.2:3000'
        : 'http://localhost:3000';
    final candidate = _envBaseUrl.trim();
    if (candidate.isEmpty) return fallback;

    final parsed = Uri.tryParse(candidate);
    final isValidScheme = parsed != null &&
        (parsed.scheme == 'http' || parsed.scheme == 'https') &&
        parsed.host.isNotEmpty;
    return isValidScheme ? candidate.replaceAll(RegExp(r'/+$'), '') : fallback;
  }
}

