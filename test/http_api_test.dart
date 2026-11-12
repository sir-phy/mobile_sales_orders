import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_sales_orders/services/sales_order_api.dart';

void main() {
  late HttpServer server;
  late HttpSalesOrderApi api;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    api = HttpSalesOrderApi(baseUrl: 'http://127.0.0.1:${server.port}');

    server.listen((HttpRequest request) async {
      final path = request.uri.path;
      final method = request.method;
      final query = request.uri.queryParameters;
      final bodyText = await utf8.decoder.bind(request).join();
      final body = bodyText.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(bodyText) as Map<String, dynamic>;

      request.response.headers.contentType = ContentType.json;

      if (method == 'GET' && path == '/dashboard/overview') {
        request.response.write(jsonEncode({
          'totalOrders': 4,
          'pendingOrders': 1,
          'completedOrders': 3,
          'growthText': '+18% vs Oct',
          'completionRateText': '75% of orders',
          'period': query['period'] ?? 'This month',
          'updatedLabel': 'Updated just now',
        }));
      } else if (method == 'GET' && path == '/orders/recent') {
        request.response.write(jsonEncode({
          'orders': [
            {
              'orderNumber': 'SO-2026-0148',
              'customerName': 'Acme Retail',
              'date': '11 Nov 2026',
              'time': '10:42 AM',
              'amount': 7170,
              'status': 'Confirmed',
              'items': [],
            }
          ],
        }));
      } else if (method == 'GET' && path == '/orders') {
        request.response.write(jsonEncode({
          'orders': [
            {
              'orderNumber': 'SO-2026-0148',
              'customerName': 'Acme Retail',
              'date': '11 Nov 2026',
              'time': '10:42 AM',
              'amount': 7170,
              'status': query['status'] == 'All' ? 'Confirmed' : query['status'],
              'items': [],
            }
          ],
          'totalCount': 1,
          'totalDatasetCount': 8,
          'page': int.parse(query['page'] ?? '1'),
          'pageSize': int.parse(query['pageSize'] ?? '4'),
          'hasMore': false,
        }));
      } else if (method == 'GET' && path == '/orders/next-number') {
        request.response.write(jsonEncode({'orderNumber': 'SO-2026-0149'}));
      } else if (method == 'GET' && path == '/orders/SO-2026-0148') {
        request.response.write(jsonEncode({
          'orderNumber': 'SO-2026-0148',
          'customerName': 'Acme Retail',
          'date': '11 Nov 2026',
          'time': '10:42 AM',
          'amount': 7170,
          'status': 'Confirmed',
          'items': [
            {
              'id': '1',
              'name': 'Wireless mouse',
              'productCode': 'PRD-001',
              'unitPrice': 850,
              'quantity': 4,
              'discount': 170,
            }
          ],
        }));
      } else if (method == 'GET' && path == '/orders/MISSING') {
        request.response.statusCode = 404;
        request.response.write(jsonEncode({'success': false, 'message': 'Order MISSING not found'}));
      } else if (method == 'POST' && path == '/orders/draft') {
        request.response.write(jsonEncode({
          'orderNumber': body['orderNumber'],
          'savedAt': DateTime.now().toIso8601String(),
        }));
      } else if (method == 'POST' && path == '/orders') {
        request.response.statusCode = 201;
        request.response.write(jsonEncode({
          'orderNumber': body['orderNumber'],
          'customerName': (body['customer'] as Map<String, dynamic>)['name'],
          'customer': body['customer'],
          'date': '12 Nov 2026',
          'time': '08:25 AM',
          'amount': 1600,
          'status': body['status'],
          'items': body['items'],
        }));
      } else if (method == 'PATCH' && path == '/orders/SO-2026-0148/status') {
        request.response.write(jsonEncode({
          'orderNumber': 'SO-2026-0148',
          'customerName': 'Acme Retail',
          'date': '11 Nov 2026',
          'time': '10:42 AM',
          'amount': 7170,
          'status': body['status'],
          'items': [],
        }));
      } else if (method == 'GET' && path == '/customers') {
        request.response.write(jsonEncode({
          'customers': [
            {
              'id': 'CUS-001',
              'name': 'Acme Retail',
              'contactName': 'Priya Sharma',
              'phone': '+91 98765 43210',
              'email': 'priya@acmeretail.in',
            }
          ],
        }));
      } else if (method == 'GET' && path == '/products') {
        request.response.write(jsonEncode({
          'products': [
            {
              'id': 'PRD-001',
              'name': 'Wireless mouse',
              'productCode': 'PRD-001',
              'unitPrice': 850,
              'category': 'Peripherals',
              'stock': 142,
            }
          ],
        }));
      } else if (method == 'GET' && path == '/notifications') {
        request.response.write(jsonEncode({
          'notifications': [
            {
              'id': 'n1',
              'title': 'Order SO-2026-0148 confirmed',
              'subtitle': 'Acme Retail · \$7,170 ready for processing',
              'timeAgo': '12m ago',
              'isRead': false,
            }
          ],
        }));
      } else if (method == 'GET' && path == '/profile') {
        request.response.write(jsonEncode({
          'name': 'Alex Morgan',
          'role': 'Regional Sales Lead',
          'email': 'alex@orderly.in',
          'phone': '+91 98200 11223',
          'workspaceName': 'Orderly Workspace',
          'currency': 'USD (\$)',
        }));
      } else {
        request.response.statusCode = 404;
        request.response.write(jsonEncode({'message': 'Not found'}));
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('HttpSalesOrderApi communicates across all endpoints', () async {
    final overview = await api.fetchDashboardOverview(period: 'This month');
    expect(overview.totalOrders, 4);
    expect(overview.completedOrders, 3);

    final recent = await api.fetchRecentOrders(limit: 3);
    expect(recent.single.orderNumber, 'SO-2026-0148');

    final paged = await api.fetchOrders(status: 'Confirmed', page: 1, pageSize: 4);
    expect(paged.totalDatasetCount, 8);
    expect(paged.orders.single.status, 'Confirmed');

    final nextNum = await api.generateNextOrderNumber();
    expect(nextNum, 'SO-2026-0149');

    final detail = await api.fetchOrderDetail('SO-2026-0148');
    expect(detail.items.single.productCode, 'PRD-001');

    final customers = await api.fetchCustomers();
    expect(customers.single.id, 'CUS-001');

    final products = await api.fetchProducts();
    expect(products.single.unitPrice, 850);

    final draft = await api.saveDraftOrder(
      orderNumber: nextNum,
      customer: customers.single,
      items: [products.single.toOrderItem(quantity: 2, discount: 100)],
    );
    expect(draft.orderNumber, 'SO-2026-0149');

    final created = await api.createAndConfirmOrder(
      orderNumber: nextNum,
      customer: customers.single,
      items: [products.single.toOrderItem(quantity: 2, discount: 100)],
    );
    expect(created.orderNumber, 'SO-2026-0149');
    expect(created.amount, 1600);

    final updated = await api.updateOrderStatus(
      orderNumber: 'SO-2026-0148',
      status: 'Pending',
    );
    expect(updated.status, 'Pending');

    final notifications = await api.fetchNotifications();
    expect(notifications.single.subtitle, contains('\$7,170'));

    final profile = await api.fetchUserProfile();
    expect(profile.currency, 'USD (\$)');

    expect(
      () => api.fetchOrderDetail('MISSING'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Order MISSING not found'),
      ),
    );
  });
}
