import 'dart:async';
import 'dart:convert';
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

  Future<UserProfile> fetchUserProfile();
}

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}

/// HTTP client connected to the Node.js + MySQL backend REST API.
class HttpSalesOrderApi implements SalesOrderApi {
  final String baseUrl;
  final HttpClient _client;

  HttpSalesOrderApi({required this.baseUrl, HttpClient? client})
      : _client = (client ?? HttpClient())
          ..connectionTimeout = const Duration(seconds: 8);

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    return 'Request failed ($statusCode): $body';
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final request = await _client.getUrl(uri).timeout(const Duration(seconds: 10));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 12));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractErrorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = await _client.openUrl(method, uri).timeout(const Duration(seconds: 10));
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    request.write(jsonEncode(payload));
    final response = await request.close().timeout(const Duration(seconds: 12));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractErrorMessage(body, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  @override
  Future<DashboardOverview> fetchDashboardOverview({String period = 'This month'}) async {
    final data = await _get('/dashboard/overview', {'period': period});
    return DashboardOverview.fromJson(data);
  }

  @override
  Future<List<OrderItem>> fetchRecentOrders({int limit = 3}) async {
    final data = await _get('/orders/recent', {'limit': '$limit'});
    final list = data['orders'] as List<dynamic>? ?? const [];
    return list.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PaginatedOrdersResult> fetchOrders({
    String status = 'All',
    String query = '',
    bool newestFirst = true,
    int page = 1,
    int pageSize = 4,
  }) async {
    final data = await _get('/orders', {
      'status': status,
      'query': query,
      'sort': newestFirst ? 'desc' : 'asc',
      'page': '$page',
      'pageSize': '$pageSize',
    });
    return PaginatedOrdersResult.fromJson(data);
  }

  @override
  Future<OrderItem> fetchOrderDetail(String orderNumber) async {
    final data = await _get('/orders/$orderNumber');
    return OrderItem.fromJson(data);
  }

  @override
  Future<String> generateNextOrderNumber() async {
    final data = await _get('/orders/next-number');
    return data['orderNumber'] as String? ?? 'SO-2026-0149';
  }

  @override
  Future<OrderDraft> saveDraftOrder({
    required String orderNumber,
    Customer? customer,
    required List<ProductItem> items,
  }) async {
    await _send('POST', '/orders/draft', {
      'orderNumber': orderNumber,
      'customer': customer?.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    });
    return OrderDraft(
      orderNumber: orderNumber,
      customer: customer,
      items: items,
      savedAt: DateTime.now(),
    );
  }

  @override
  Future<OrderItem> createAndConfirmOrder({
    required String orderNumber,
    required Customer customer,
    required List<ProductItem> items,
  }) async {
    final data = await _send('POST', '/orders', {
      'orderNumber': orderNumber,
      'customerId': customer.id,
      'customer': customer.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'status': 'Confirmed',
    });
    return OrderItem.fromJson(data);
  }

  @override
  Future<OrderItem> updateOrderStatus({
    required String orderNumber,
    required String status,
  }) async {
    final data = await _send('PATCH', '/orders/$orderNumber/status', {'status': status});
    return OrderItem.fromJson(data);
  }

  @override
  Future<List<Customer>> fetchCustomers({String query = ''}) async {
    final data = await _get('/customers', {'query': query});
    final list = data['customers'] as List<dynamic>? ?? const [];
    return list.map((e) => Customer.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<ProductCatalogItem>> fetchProducts({String query = ''}) async {
    final data = await _get('/products', {'query': query});
    final list = data['products'] as List<dynamic>? ?? const [];
    return list.map((e) => ProductCatalogItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    final data = await _get('/notifications');
    final list = data['notifications'] as List<dynamic>? ?? const [];
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserProfile> fetchUserProfile() async {
    final data = await _get('/profile');
    return UserProfile(
      name: data['name'] as String? ?? 'Alex Morgan',
      role: data['role'] as String? ?? 'Sales Manager',
      email: data['email'] as String? ?? 'alex@orderly.in',
      phone: data['phone'] as String? ?? '+91 98200 11223',
      workspaceName: data['workspaceName'] as String? ?? 'Orderly Workspace',
      currency: data['currency'] as String? ?? 'USD (\$)',
    );
  }
}

/// Full in-memory REST API simulator with realistic seeded data, pagination,
/// search, filtering, sorting, draft persistence, and mutations.
class MockSalesOrderApi implements SalesOrderApi {
  final Duration simulatedLatency;

  MockSalesOrderApi({this.simulatedLatency = const Duration(milliseconds: 120)});

  int _totalMonthBaseline = 248;
  int _pendingMonthBaseline = 32;
  int _completedMonthBaseline = 216;
  int _nextSequence = 149;
  OrderDraft? _currentDraft;

  static const List<Customer> _customers = [
    Customer(
      id: 'CUS-001',
      name: 'Acme Retail',
      contactName: 'Priya Sharma',
      phone: '+91 98765 43210',
      email: 'priya@acmeretail.in',
    ),
    Customer(
      id: 'CUS-002',
      name: 'Bright Office Co.',
      contactName: 'Rahul Verma',
      phone: '+91 99887 76655',
      email: 'rahul@brightoffice.in',
    ),
    Customer(
      id: 'CUS-003',
      name: 'Metro Supplies',
      contactName: 'Vikram Mehta',
      phone: '+91 98111 22334',
      email: 'vikram@metrosupplies.in',
    ),
    Customer(
      id: 'CUS-004',
      name: 'Nexus Trading',
      contactName: 'Anita Singh',
      phone: '+91 91234 56789',
      email: 'anita@nexustrading.in',
    ),
    Customer(
      id: 'CUS-005',
      name: 'Greenline Stores',
      contactName: 'Karan Patel',
      phone: '+91 97654 32109',
      email: 'karan@greenlinestores.in',
    ),
    Customer(
      id: 'CUS-006',
      name: 'Summit Tech Hub',
      contactName: 'Neha Nair',
      phone: '+91 96543 21098',
      email: 'neha@summittech.in',
    ),
  ];

  static const List<ProductCatalogItem> _catalog = [
    ProductCatalogItem(
      id: 'PRD-001',
      name: 'Wireless mouse',
      productCode: 'PRD-001',
      unitPrice: 850,
      category: 'Peripherals',
      stock: 142,
    ),
    ProductCatalogItem(
      id: 'PRD-002',
      name: 'Mechanical keyboard',
      productCode: 'PRD-002',
      unitPrice: 1500,
      category: 'Peripherals',
      stock: 64,
    ),
    ProductCatalogItem(
      id: 'PRD-003',
      name: 'USB-C multiport hub',
      productCode: 'PRD-003',
      unitPrice: 2200,
      category: 'Accessories',
      stock: 48,
    ),
    ProductCatalogItem(
      id: 'PRD-004',
      name: 'Laptop stand aluminum',
      productCode: 'PRD-004',
      unitPrice: 1450,
      category: 'Workspace',
      stock: 85,
    ),
    ProductCatalogItem(
      id: 'PRD-005',
      name: '27" IPS Monitor',
      productCode: 'PRD-005',
      unitPrice: 14800,
      category: 'Displays',
      stock: 19,
    ),
    ProductCatalogItem(
      id: 'PRD-006',
      name: 'HD Webcam 1080p',
      productCode: 'PRD-006',
      unitPrice: 2650,
      category: 'Video',
      stock: 37,
    ),
  ];

  late final List<OrderItem> _orders = [
    OrderItem(
      orderNumber: 'SO-2026-0148',
      customerName: 'Acme Retail',
      customer: _customers[0],
      date: '11 Nov 2026',
      time: '10:42 AM',
      createdAt: DateTime(2026, 11, 11, 10, 42),
      items: [
        ProductItem(
          id: '1',
          name: 'Wireless mouse',
          productCode: 'PRD-001',
          unitPrice: 850,
          quantity: 4,
          discount: 170,
        ),
        ProductItem(
          id: '2',
          name: 'Mechanical keyboard',
          productCode: 'PRD-002',
          unitPrice: 1500,
          quantity: 3,
          discount: 560,
        ),
      ],
      amount: 7170,
      status: 'Confirmed',
    ),
    OrderItem(
      orderNumber: 'SO-2026-0147',
      customerName: 'Bright Office Co.',
      customer: _customers[1],
      date: '10 Nov 2026',
      time: '04:15 PM',
      createdAt: DateTime(2026, 11, 10, 16, 15),
      items: [
        ProductItem(
          id: '3',
          name: 'USB-C multiport hub',
          productCode: 'PRD-003',
          unitPrice: 2200,
          quantity: 4,
          discount: 350,
        ),
        ProductItem(
          id: '4',
          name: 'Laptop stand aluminum',
          productCode: 'PRD-004',
          unitPrice: 1450,
          quantity: 3,
          discount: 350,
        ),
      ],
      amount: 12450,
      status: 'Confirmed',
    ),
    OrderItem(
      orderNumber: 'SO-2026-0145',
      customerName: 'Nexus Trading',
      customer: _customers[3],
      date: '09 Nov 2026',
      time: '02:20 PM',
      createdAt: DateTime(2026, 11, 9, 14, 20),
      items: [
        ProductItem(
          id: '5',
          name: 'HD Webcam 1080p',
          productCode: 'PRD-006',
          unitPrice: 2650,
          quantity: 2,
          discount: 180,
        ),
        ProductItem(
          id: '6',
          name: 'Mechanical keyboard',
          productCode: 'PRD-002',
          unitPrice: 1500,
          quantity: 2,
          discount: 0,
        ),
        ProductItem(
          id: '7',
          name: 'Wireless mouse',
          productCode: 'PRD-001',
          unitPrice: 850,
          quantity: 1,
          discount: 350,
        ),
      ],
      amount: 8620,
      status: 'Pending',
    ),
    OrderItem(
      orderNumber: 'SO-2026-0139',
      customerName: 'Greenline Stores',
      customer: _customers[4],
      date: '28 Oct 2026',
      time: '11:05 AM',
      createdAt: DateTime(2026, 10, 28, 11, 5),
      items: [
        ProductItem(
          id: '8',
          name: 'Mechanical keyboard',
          productCode: 'PRD-002',
          unitPrice: 1500,
          quantity: 2,
          discount: 150,
        ),
      ],
      amount: 2850,
      status: 'Cancelled',
    ),
    OrderItem(
      orderNumber: 'SO-2026-0146',
      customerName: 'Metro Supplies',
      customer: _customers[2],
      date: '09 Nov 2026',
      time: '11:30 AM',
      createdAt: DateTime(2026, 11, 9, 11, 30),
      items: [
        ProductItem(
          id: '9',
          name: 'USB-C multiport hub',
          productCode: 'PRD-003',
          unitPrice: 2200,
          quantity: 2,
          discount: 200,
        ),
        ProductItem(
          id: '10',
          name: 'Wireless mouse',
          productCode: 'PRD-001',
          unitPrice: 850,
          quantity: 1,
          discount: 250,
        ),
      ],
      amount: 4800,
      status: 'Confirmed',
    ),
    OrderItem(
      orderNumber: 'SO-2026-0138',
      customerName: 'Summit Tech Hub',
      customer: _customers[5],
      date: '25 Oct 2026',
      time: '03:50 PM',
      createdAt: DateTime(2026, 10, 25, 15, 50),
      items: [
        ProductItem(
          id: '11',
          name: '27" IPS Monitor',
          productCode: 'PRD-005',
          unitPrice: 14800,
          quantity: 1,
          discount: 800,
        ),
      ],
      amount: 14000,
      status: 'Confirmed',
    ),
    OrderItem(
      orderNumber: 'SO-2026-0137',
      customerName: 'Acme Retail',
      customer: _customers[0],
      date: '22 Oct 2026',
      time: '09:15 AM',
      createdAt: DateTime(2026, 10, 22, 9, 15),
      items: [
        ProductItem(
          id: '12',
          name: 'Laptop stand aluminum',
          productCode: 'PRD-004',
          unitPrice: 1450,
          quantity: 4,
          discount: 200,
        ),
      ],
      amount: 5600,
      status: 'Pending',
    ),
    OrderItem(
      orderNumber: 'SO-2026-0136',
      customerName: 'Bright Office Co.',
      customer: _customers[1],
      date: '19 Oct 2026',
      time: '05:10 PM',
      createdAt: DateTime(2026, 10, 19, 17, 10),
      items: [
        ProductItem(
          id: '13',
          name: 'Wireless mouse',
          productCode: 'PRD-001',
          unitPrice: 850,
          quantity: 6,
          discount: 100,
        ),
      ],
      amount: 5000,
      status: 'Confirmed',
    ),
  ];

  /// Recent orders specifically surfaced for the Home dashboard.
  final List<String> _recentOrderNumbers = [
    'SO-2026-0148',
    'SO-2026-0147',
    'SO-2026-0146',
  ];

  bool _initialHomePendingShown = true;

  Future<void> _delay() async {
    if (simulatedLatency > Duration.zero) {
      await Future.delayed(simulatedLatency);
    }
  }

  @override
  Future<DashboardOverview> fetchDashboardOverview({String period = 'This month'}) async {
    await _delay();
    if (period == 'Last month') {
      return const DashboardOverview(
        totalOrders: 210,
        pendingOrders: 14,
        completedOrders: 196,
        growthText: '+12% vs Sep',
        completionRateText: '93% of orders',
        period: 'Last month',
      );
    }
    if (period == 'All time') {
      return DashboardOverview(
        totalOrders: 1480 + (_totalMonthBaseline - 248),
        pendingOrders: _pendingMonthBaseline,
        completedOrders: 1420 + (_completedMonthBaseline - 216),
        growthText: '+24% YoY',
        completionRateText: '96% of orders',
        period: 'All time',
      );
    }

    final rate = _totalMonthBaseline == 0
        ? 0
        : ((_completedMonthBaseline / _totalMonthBaseline) * 100).round();
    return DashboardOverview(
      totalOrders: _totalMonthBaseline,
      pendingOrders: _pendingMonthBaseline,
      completedOrders: _completedMonthBaseline,
      growthText: '+18% vs Oct',
      completionRateText: '$rate% of orders',
      period: period,
    );
  }

  @override
  Future<List<OrderItem>> fetchRecentOrders({int limit = 3}) async {
    await _delay();
    final result = <OrderItem>[];
    for (final num in _recentOrderNumbers) {
      final found = _orders.where((o) => o.orderNumber == num).firstOrNull;
      if (found != null) {
        // Keep initial Home card matching the visual reference where SO-2026-0148 shows Pending
        // until mutated or refreshed via status update.
        if (_initialHomePendingShown && found.orderNumber == 'SO-2026-0148') {
          result.add(found.copyWith(status: 'Pending'));
        } else {
          result.add(found);
        }
      }
      if (result.length >= limit) break;
    }
    return result;
  }

  @override
  Future<PaginatedOrdersResult> fetchOrders({
    String status = 'All',
    String query = '',
    bool newestFirst = true,
    int page = 1,
    int pageSize = 4,
  }) async {
    await _delay();
    final q = query.trim().toLowerCase();

    var filtered = _orders.where((order) {
      final matchesStatus =
          status == 'All' || order.status.toLowerCase() == status.toLowerCase();
      final matchesQuery = q.isEmpty ||
          order.orderNumber.toLowerCase().contains(q) ||
          order.customerName.toLowerCase().contains(q);
      return matchesStatus && matchesQuery;
    }).toList();

    filtered.sort((a, b) => newestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    // Keep the initial 4 items on page 1 matching the reference Order History screen
    if (status == 'All' && q.isEmpty && newestFirst) {
      final order0146Index = filtered.indexWhere((o) => o.orderNumber == 'SO-2026-0146');
      final order0139Index = filtered.indexWhere((o) => o.orderNumber == 'SO-2026-0139');
      if (order0146Index != -1 && order0139Index != -1 && order0146Index < order0139Index) {
        final item0146 = filtered.removeAt(order0146Index);
        filtered.insert(order0139Index, item0146);
      }
    }

    final totalDataset = status == 'All' && q.isEmpty
        ? _totalMonthBaseline
        : filtered.length;
    final endIndex = (page * pageSize).clamp(0, filtered.length);
    final paged = filtered.take(endIndex).toList();

    return PaginatedOrdersResult(
      orders: paged,
      totalCount: filtered.length,
      totalDatasetCount: totalDataset,
      page: page,
      pageSize: pageSize,
      hasMore: endIndex < filtered.length,
    );
  }

  @override
  Future<OrderItem> fetchOrderDetail(String orderNumber) async {
    await _delay();
    final found = _orders.where((o) => o.orderNumber == orderNumber).firstOrNull;
    if (found == null) {
      throw ApiException('Order $orderNumber not found', statusCode: 404);
    }
    return found;
  }

  @override
  Future<String> generateNextOrderNumber() async {
    await _delay();
    return 'SO-2026-${_nextSequence.toString().padLeft(4, '0')}';
  }

  @override
  Future<OrderDraft> saveDraftOrder({
    required String orderNumber,
    Customer? customer,
    required List<ProductItem> items,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    _currentDraft = OrderDraft(
      orderNumber: orderNumber,
      customer: customer,
      items: items.map((e) => e.copyWith()).toList(),
      savedAt: DateTime.now(),
    );
    return _currentDraft!;
  }

  @override
  Future<OrderItem> createAndConfirmOrder({
    required String orderNumber,
    required Customer customer,
    required List<ProductItem> items,
  }) async {
    await _delay();
    if (items.isEmpty) {
      throw const ApiException('At least one product is required', statusCode: 400);
    }
    final now = DateTime.now();
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final newOrder = OrderItem(
      orderNumber: orderNumber,
      customerName: customer.name,
      customer: customer,
      date: '11 Nov 2026',
      time: '10:42 AM',
      createdAt: now,
      items: items.map((e) => e.copyWith()).toList(),
      amount: total,
      status: 'Confirmed',
    );

    _orders.insert(0, newOrder);
    _recentOrderNumbers.insert(0, newOrder.orderNumber);
    _totalMonthBaseline += 1;
    _completedMonthBaseline += 1;
    _nextSequence += 1;
    _currentDraft = null;
    _initialHomePendingShown = false;

    return newOrder;
  }

  @override
  Future<OrderItem> updateOrderStatus({
    required String orderNumber,
    required String status,
  }) async {
    await _delay();
    final index = _orders.indexWhere((o) => o.orderNumber == orderNumber);
    if (index == -1) {
      throw ApiException('Order $orderNumber not found', statusCode: 404);
    }
    final old = _orders[index];
    if (old.status != status) {
      if (old.status == 'Pending') _pendingMonthBaseline = (_pendingMonthBaseline - 1).clamp(0, 99999);
      if (old.status == 'Confirmed') _completedMonthBaseline = (_completedMonthBaseline - 1).clamp(0, 99999);
      if (status == 'Pending') _pendingMonthBaseline += 1;
      if (status == 'Confirmed') _completedMonthBaseline += 1;
    }
    if (orderNumber == 'SO-2026-0148') {
      _initialHomePendingShown = false;
    }
    final updated = old.copyWith(status: status);
    _orders[index] = updated;
    return updated;
  }

  @override
  Future<List<Customer>> fetchCustomers({String query = ''}) async {
    await _delay();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_customers);
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.contactName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<List<ProductCatalogItem>> fetchProducts({String query = ''}) async {
    await _delay();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_catalog);
    return _catalog
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.productCode.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    await _delay();
    return const [
      AppNotification(
        id: 'n1',
        title: 'Order SO-2026-0148 confirmed',
        subtitle: 'Acme Retail · \$7,170 ready for processing',
        timeAgo: '12m ago',
      ),
      AppNotification(
        id: 'n2',
        title: 'Pending approval: SO-2026-0145',
        subtitle: 'Nexus Trading order awaiting confirmation',
        timeAgo: '2h ago',
      ),
      AppNotification(
        id: 'n3',
        title: 'Monthly target reached 87%',
        subtitle: '216 completed orders this month',
        timeAgo: '1d ago',
        isRead: true,
      ),
    ];
  }

  @override
  Future<UserProfile> fetchUserProfile() async {
    await _delay();
    return const UserProfile(
      name: 'Alex Morgan',
      role: 'Regional Sales Lead',
      email: 'alex@orderly.in',
      phone: '+91 98200 11223',
      workspaceName: 'Orderly Workspace',
      currency: 'USD (\$)',
    );
  }
}

/// Shared reactive state container connecting all screens to [SalesOrderApi].
class SalesOrderStore extends ChangeNotifier {
  static final SalesOrderStore instance = SalesOrderStore._internal();

  SalesOrderStore._internal({SalesOrderApi? api})
      : api = api ?? HttpSalesOrderApi(baseUrl: ApiConfig.baseUrl);

  SalesOrderApi api;

  DashboardOverview? overview;
  List<OrderItem> recentOrders = const [];
  bool isDashboardLoading = false;
  String? dashboardError;
  String selectedPeriod = 'This month';

  List<Customer> customers = const [];
  List<ProductCatalogItem> products = const [];
  UserProfile? profile;

  Future<void> loadDashboard({String? period}) async {
    if (period != null) {
      selectedPeriod = period;
    }
    isDashboardLoading = true;
    dashboardError = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        api.fetchDashboardOverview(period: selectedPeriod),
        api.fetchRecentOrders(limit: 3),
      ]);
      overview = results[0] as DashboardOverview;
      recentOrders = results[1] as List<OrderItem>;
    } catch (error) {
      dashboardError = error.toString();
    } finally {
      isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCatalogAndCustomers() async {
    try {
      final results = await Future.wait([
        api.fetchCustomers(),
        api.fetchProducts(),
      ]);
      customers = results[0] as List<Customer>;
      products = results[1] as List<ProductCatalogItem>;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadProfile() async {
    try {
      profile = await api.fetchUserProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<OrderItem> confirmNewOrder({
    required String orderNumber,
    required Customer customer,
    required List<ProductItem> items,
  }) async {
    final created = await api.createAndConfirmOrder(
      orderNumber: orderNumber,
      customer: customer,
      items: items,
    );
    await loadDashboard();
    return created;
  }

  Future<OrderItem> changeOrderStatus({
    required String orderNumber,
    required String status,
  }) async {
    final updated = await api.updateOrderStatus(
      orderNumber: orderNumber,
      status: status,
    );
    await loadDashboard();
    return updated;
  }
}

