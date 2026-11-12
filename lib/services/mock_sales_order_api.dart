import '../models/models.dart';
import 'api_config.dart';
import 'mock_seed_data.dart';

/// In-memory REST API simulator for offline tests and previews.
class MockSalesOrderApi implements SalesOrderApi {
  final Duration simulatedLatency;

  MockSalesOrderApi({this.simulatedLatency = const Duration(milliseconds: 120)});

  int _totalMonthBaseline = 248;
  int _pendingMonthBaseline = 32;
  int _completedMonthBaseline = 216;
  int _nextSequence = 149;
  OrderDraft? _currentDraft;
  late final List<OrderItem> _orders = createMockSeedOrders();
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
  Future<DashboardOverview> fetchDashboardOverview({
    String period = 'This month',
  }) async {
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
      if (found == null) continue;
      final usePending =
          _initialHomePendingShown && found.orderNumber == 'SO-2026-0148';
      result.add(usePending ? found.copyWith(status: 'Pending') : found);
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
    final filtered = _orders.where((order) {
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

    if (status == 'All' && q.isEmpty && newestFirst) {
      final idx0146 = filtered.indexWhere((o) => o.orderNumber == 'SO-2026-0146');
      final idx0139 = filtered.indexWhere((o) => o.orderNumber == 'SO-2026-0139');
      if (idx0146 != -1 && idx0139 != -1 && idx0146 < idx0139) {
        final item = filtered.removeAt(idx0146);
        filtered.insert(idx0139, item);
      }
    }

    final totalDataset =
        status == 'All' && q.isEmpty ? _totalMonthBaseline : filtered.length;
    final endIndex = (page * pageSize).clamp(0, filtered.length);
    return PaginatedOrdersResult(
      orders: filtered.take(endIndex).toList(),
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
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final newOrder = OrderItem(
      orderNumber: orderNumber,
      customerName: customer.name,
      customer: customer,
      date: '11 Nov 2026',
      time: '10:42 AM',
      createdAt: DateTime.now(),
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
      if (old.status == 'Pending') {
        _pendingMonthBaseline = (_pendingMonthBaseline - 1).clamp(0, 99999);
      }
      if (old.status == 'Confirmed') {
        _completedMonthBaseline = (_completedMonthBaseline - 1).clamp(0, 99999);
      }
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
    if (q.isEmpty) return List.unmodifiable(mockCustomers);
    return mockCustomers
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
    if (q.isEmpty) return List.unmodifiable(mockProductCatalog);
    return mockProductCatalog
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.productCode.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<List<AppNotification>> fetchNotifications() async {
    await _delay();
    return mockSeedNotifications;
  }

  @override
  void setAuthToken(String? token) {}

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    await _delay();
    final clean = email.trim().toLowerCase();
    final isLead = clean.contains('lead');
    return AuthSession(
      token: 'mock-token',
      user: AuthUser(
        id: isLead ? 'USR-LEAD-01' : 'USR-CUST-01',
        name: isLead ? 'Alex Morgan' : 'Priya Sharma',
        email: clean,
        role: isLead ? 'sell_lead' : 'customer',
        customerId: isLead ? null : mockCustomers.first.id,
        customer: isLead ? null : mockCustomers.first,
      ),
    );
  }

  @override
  Future<AuthSession> registerCustomer({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String companyName = '',
  }) async {
    await _delay();
    final cust = Customer(
      id: 'CUS-MOCK',
      name: companyName.trim().isEmpty ? name.trim() : companyName.trim(),
      contactName: name.trim(),
      phone: phone.trim(),
      email: email.trim(),
    );
    return AuthSession(
      token: 'mock-token',
      user: AuthUser(
        id: 'USR-MOCK',
        name: name.trim(),
        email: email.trim(),
        role: 'customer',
        phone: phone.trim(),
        customerId: cust.id,
        customer: cust,
      ),
    );
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _delay();
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _delay();
  }

  @override
  Future<UserProfile> fetchUserProfile() async {
    await _delay();
    return mockDefaultProfile;
  }
}

