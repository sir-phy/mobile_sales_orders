import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_sales_orders/main.dart';
import 'package:mobile_sales_orders/services/sales_order_api.dart';

void main() {
  setUp(() {
    SalesOrderStore.instance.api = MockSalesOrderApi(
      simulatedLatency: Duration.zero,
    );
    SalesOrderStore.instance.profile = null;
    SalesOrderStore.instance.clearCart();
  });
  test('MockSalesOrderApi CRUD, filter, search, and pagination work', () async {
    final api = MockSalesOrderApi(simulatedLatency: Duration.zero);

    final overview = await api.fetchDashboardOverview();
    expect(overview.totalOrders, 248);
    expect(overview.pendingOrders, 32);
    expect(overview.completedOrders, 216);

    final page1 = await api.fetchOrders(page: 1, pageSize: 4);
    expect(page1.orders.length, 4);
    expect(page1.hasMore, isTrue);
    expect(page1.orders.first.orderNumber, 'SO-2026-0148');

    final page2 = await api.fetchOrders(page: 2, pageSize: 4);
    expect(page2.orders.length, greaterThan(4));

    final pending = await api.fetchOrders(status: 'Pending');
    expect(pending.orders.every((o) => o.status == 'Pending'), isTrue);

    final searched = await api.fetchOrders(query: 'Acme');
    expect(searched.orders.isNotEmpty, isTrue);
    expect(searched.orders.every((o) => o.customerName.contains('Acme')), isTrue);

    final customers = await api.fetchCustomers();
    final products = await api.fetchProducts();
    expect(customers.isNotEmpty, isTrue);
    expect(products.isNotEmpty, isTrue);

    final nextNum = await api.generateNextOrderNumber();
    expect(nextNum, 'SO-2026-0149');

    final created = await api.createAndConfirmOrder(
      orderNumber: nextNum,
      customer: customers.first,
      items: [products.first.toOrderItem(quantity: 2, discount: 100)],
    );
    expect(created.orderNumber, 'SO-2026-0149');
    expect(created.status, 'Confirmed');
    expect(created.amount, 1600);

    final updatedOverview = await api.fetchDashboardOverview();
    expect(updatedOverview.totalOrders, 249);
    expect(updatedOverview.completedOrders, 217);
  });

  testWidgets('OrderlyApp renders Products as home and navigates to Orders & Create Order',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OrderlyApp());
    await tester.pumpAndSettle();

    expect(find.text('Products'), findsWidgets);
    expect(find.text('Tap a product to add it to your cart.'), findsOneWidget);
    expect(find.text('Wireless mouse'), findsOneWidget);

    await tester.tap(find.text('Orders').last);
    await tester.pumpAndSettle();

    expect(find.text('Order history'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_horiz).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create new sales order'));
    await tester.pumpAndSettle();

    expect(find.text('Create sales order'), findsOneWidget);
    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();

    expect(find.text('A couple of details are missing'), findsOneWidget);
    expect(find.text('Please select a customer to continue.'), findsOneWidget);
    expect(find.text('Add at least one product to continue.'), findsOneWidget);
  });

  testWidgets('Add multiple products to cart and order all end-to-end',
      (WidgetTester tester) async {
    await tester.pumpWidget(const OrderlyApp());
    await tester.pumpAndSettle();

    // Add two products to cart on Products page
    await tester.tap(find.text('Wireless mouse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mechanical keyboard'));
    await tester.pumpAndSettle();

    expect(find.text('2 items in cart'), findsOneWidget);
    expect(find.text('Order all'), findsOneWidget);

    // Proceed to Create Order with all cart products
    await tester.tap(find.text('Order all'));
    await tester.pumpAndSettle();

    expect(find.text('Create sales order'), findsOneWidget);
    expect(find.text('Wireless mouse'), findsOneWidget);
    expect(find.text('Mechanical keyboard'), findsOneWidget);

    // Select customer
    await tester.tap(find.text('Choose a customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acme Retail').last);
    await tester.pumpAndSettle();

    expect(find.text('Priya Sharma'), findsOneWidget);

    // Go to Order Summary
    await tester.tap(find.text('Review order'));
    await tester.pumpAndSettle();

    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('Everything look right?'), findsOneWidget);
    expect(find.text('Confirming changes this order to Confirmed.'), findsOneWidget);

    // Confirm Order -> Order Details & cart cleared
    await tester.tap(find.text('Confirm order'));
    await tester.pumpAndSettle();

    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('Order confirmed successfully'), findsOneWidget);
    expect(find.text('Your order is ready for processing.'), findsOneWidget);
    expect(find.text('Create another order'), findsOneWidget);
    expect(SalesOrderStore.instance.cartItems, isEmpty);
  });

  test('ApiConfig resolves a valid base URL', () {
    expect(ApiConfig.baseUrl, startsWith('http'));
  });
}
