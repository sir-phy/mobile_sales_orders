import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'api_config.dart';
import 'http_sales_order_api.dart';

/// Shared reactive state container connecting all screens to [SalesOrderApi].
class SalesOrderStore extends ChangeNotifier {
  static final SalesOrderStore instance = SalesOrderStore._internal();

  SalesOrderStore._internal({SalesOrderApi? api})
      : api = api ?? HttpSalesOrderApi(baseUrl: ApiConfig.baseUrl);

  SalesOrderApi api;

  AuthUser? currentUser;
  String? authToken;
  Timer? _notifTimer;

  List<Customer> customers = const [];
  List<ProductCatalogItem> products = const [];
  List<AppNotification> notifications = const [];
  UserProfile? profile;
  int orderVersion = 0;
  final List<ProductItem> cartItems = [];

  bool get isLoggedIn => currentUser != null && authToken != null;
  bool get isSellLead => currentUser?.isSellLead ?? false;
  bool get isCustomer => currentUser?.isCustomer ?? false;
  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  int get cartTotalUnits => cartItems.fold(0, (s, p) => s + p.quantity);

  double get cartTotalAmount => cartItems.fold(0.0, (s, p) => s + p.subtotal);

  int cartQuantityFor(String productCode) {
    final found =
        cartItems.where((item) => item.productCode == productCode).firstOrNull;
    return found?.quantity ?? 0;
  }

  void addToCart(ProductCatalogItem product) {
    final index =
        cartItems.indexWhere((item) => item.productCode == product.productCode);
    if (index != -1) {
      cartItems[index].quantity += 1;
    } else {
      cartItems.add(product.toOrderItem(quantity: 1));
    }
    notifyListeners();
  }

  void updateCartQuantity(String productCode, int delta) {
    final index =
        cartItems.indexWhere((item) => item.productCode == productCode);
    if (index == -1) return;
    final nextQty = cartItems[index].quantity + delta;
    if (nextQty <= 0) {
      cartItems.removeAt(index);
    } else {
      cartItems[index].quantity = nextQty;
    }
    notifyListeners();
  }

  void removeFromCart(String productCode) {
    cartItems.removeWhere((item) => item.productCode == productCode);
    notifyListeners();
  }

  void clearCart() {
    if (cartItems.isEmpty) return;
    cartItems.clear();
    notifyListeners();
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

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final session = await api.login(email: email, password: password);
    _applySession(session);
    return session.user;
  }

  Future<AuthUser> registerCustomer({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String companyName = '',
  }) async {
    final session = await api.registerCustomer(
      name: name,
      email: email,
      password: password,
      phone: phone,
      companyName: companyName,
    );
    _applySession(session);
    return session.user;
  }

  void _applySession(AuthSession session) {
    authToken = session.token;
    currentUser = session.user;
    api.setAuthToken(session.token);
    orderVersion += 1;
    _startNotificationPollingIfLead();
    notifyListeners();
  }

  void logout() {
    _notifTimer?.cancel();
    _notifTimer = null;
    authToken = null;
    currentUser = null;
    notifications = const [];
    api.setAuthToken(null);
    orderVersion += 1;
    notifyListeners();
  }

  void _startNotificationPollingIfLead() {
    _notifTimer?.cancel();
    if (!isSellLead) return;
    refreshNotifications();
    _notifTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => refreshNotifications(),
    );
  }

  Future<void> refreshNotifications() async {
    if (!isLoggedIn) return;
    try {
      notifications = await api.fetchNotifications();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markNotificationRead(String id) async {
    notifications = notifications
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    notifyListeners();
    try {
      await api.markNotificationRead(id);
    } catch (_) {}
  }

  Future<void> markAllNotificationsRead() async {
    notifications =
        notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();
    try {
      await api.markAllNotificationsRead();
    } catch (_) {}
  }

  Future<OrderItem> confirmNewOrder({
    required String orderNumber,
    required Customer customer,
    required List<ProductItem> items,
    bool fromCart = false,
  }) async {
    final created = await api.createAndConfirmOrder(
      orderNumber: orderNumber,
      customer: customer,
      items: items,
    );
    if (fromCart) {
      cartItems.clear();
    }
    orderVersion += 1;
    notifyListeners();
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
    orderVersion += 1;
    notifyListeners();
    return updated;
  }
}

