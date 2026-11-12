import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/models.dart';
import 'api_config.dart';

/// HTTP client connected to the Node.js + MySQL backend REST API.
class HttpSalesOrderApi implements SalesOrderApi {
  final Uri _baseUri;
  final HttpClient _client;
  String? _authToken;

  HttpSalesOrderApi({required String baseUrl, HttpClient? client})
      : _baseUri = _validateBaseUri(baseUrl),
        _client = (client ?? HttpClient())
          ..connectionTimeout = const Duration(seconds: 8);

  @override
  void setAuthToken(String? token) {
    _authToken = token;
  }

  static Uri _validateBaseUri(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      throw const ApiException('Invalid API base URL configuration');
    }
    return uri;
  }

  String _encodeSegment(String value, String label) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ApiException('$label cannot be empty', statusCode: 400);
    }
    return Uri.encodeComponent(trimmed);
  }

  String _extractErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {}
    final trimmed = body.trim();
    if (trimmed.isEmpty) return 'Request failed ($statusCode)';
    final safeSnippet =
        trimmed.length > 120 ? '${trimmed.substring(0, 120)}...' : trimmed;
    return 'Request failed ($statusCode): $safeSnippet';
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = _baseUri.replace(
      path: '${_baseUri.path.replaceAll(RegExp(r'/+$'), '')}$normalizedPath',
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    final request =
        await _client.openUrl(method, uri).timeout(const Duration(seconds: 10));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (_authToken != null && _authToken!.isNotEmpty) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $_authToken');
    }
    if (body != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 12));
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _extractErrorMessage(responseBody, response.statusCode),
        statusCode: response.statusCode,
      );
    }
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiException('Unexpected response format from server');
      }
      return decoded;
    } on FormatException {
      throw const ApiException('Invalid JSON response from server');
    }
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) =>
      _request('GET', path, query: query);

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) =>
      _request(method, path, body: payload);

  Future<List<T>> _getList<T>(
    String path,
    String key,
    T Function(Map<String, dynamic>) fromJson, [
    Map<String, String>? query,
  ]) async {
    final data = await _get(path, query);
    final raw = data[key] as List<dynamic>? ?? const [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  @override
  Future<DashboardOverview> fetchDashboardOverview({
    String period = 'This month',
  }) async {
    final data = await _get('/dashboard/overview', {'period': period});
    return DashboardOverview.fromJson(data);
  }

  @override
  Future<List<OrderItem>> fetchRecentOrders({int limit = 3}) => _getList(
        '/orders/recent',
        'orders',
        OrderItem.fromJson,
        {'limit': '${limit.clamp(1, 50)}'},
      );

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
      'query': query.trim(),
      'sort': newestFirst ? 'desc' : 'asc',
      'page': '${page < 1 ? 1 : page}',
      'pageSize': '${pageSize.clamp(1, 100)}',
    });
    return PaginatedOrdersResult.fromJson(data);
  }

  @override
  Future<OrderItem> fetchOrderDetail(String orderNumber) async {
    final encoded = _encodeSegment(orderNumber, 'Order number');
    final data = await _get('/orders/$encoded');
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
      'orderNumber': orderNumber.trim(),
      'customer': customer?.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
    });
    return OrderDraft(
      orderNumber: orderNumber.trim(),
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
    if (items.isEmpty) {
      throw const ApiException('At least one product is required', statusCode: 400);
    }
    final data = await _send('POST', '/orders', {
      'orderNumber': orderNumber.trim(),
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
    if (!allowedOrderStatuses.contains(status)) {
      throw ApiException('Unsupported order status: $status', statusCode: 400);
    }
    final encoded = _encodeSegment(orderNumber, 'Order number');
    final data = await _send('PATCH', '/orders/$encoded/status', {'status': status});
    return OrderItem.fromJson(data);
  }

  @override
  Future<List<Customer>> fetchCustomers({String query = ''}) => _getList(
        '/customers',
        'customers',
        Customer.fromJson,
        {'query': query.trim()},
      );

  @override
  Future<List<ProductCatalogItem>> fetchProducts({String query = ''}) => _getList(
        '/products',
        'products',
        ProductCatalogItem.fromJson,
        {'query': query.trim()},
      );

  @override
  Future<List<AppNotification>> fetchNotifications() =>
      _getList('/notifications', 'notifications', AppNotification.fromJson);

  @override
  Future<void> markNotificationRead(String id) async {
    final safeId = _encodeSegment(id, 'Notification ID');
    await _send('PATCH', '/notifications/$safeId/read', const {});
  }

  @override
  Future<void> markAllNotificationsRead() async {
    await _send('PATCH', '/notifications/read-all', const {});
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _send('POST', '/auth/login', {
      'email': email.trim(),
      'password': password,
    });
    return AuthSession.fromJson(data);
  }

  @override
  Future<AuthSession> registerCustomer({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String companyName = '',
  }) async {
    final data = await _send('POST', '/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
      'phone': phone.trim(),
      'companyName': companyName.trim(),
    });
    return AuthSession.fromJson(data);
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

