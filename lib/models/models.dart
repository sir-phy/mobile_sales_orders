class Customer {
  final String id;
  final String name;
  final String contactName;
  final String phone;
  final String email;

  const Customer({
    this.id = '',
    required this.name,
    required this.contactName,
    required this.phone,
    required this.email,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      contactName: json['contactName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'contactName': contactName,
        'phone': phone,
        'email': email,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => name.hashCode ^ email.hashCode;
}

class ProductCatalogItem {
  final String id;
  final String name;
  final String productCode;
  final double unitPrice;
  final String category;
  final int stock;

  const ProductCatalogItem({
    required this.id,
    required this.name,
    required this.productCode,
    required this.unitPrice,
    this.category = 'General',
    this.stock = 50,
  });

  factory ProductCatalogItem.fromJson(Map<String, dynamic> json) {
    return ProductCatalogItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      category: json['category'] as String? ?? 'General',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'productCode': productCode,
        'unitPrice': unitPrice,
        'category': category,
        'stock': stock,
      };

  ProductItem toOrderItem({int quantity = 1, double discount = 0}) {
    return ProductItem(
      id: '${productCode}_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      productCode: productCode,
      unitPrice: unitPrice,
      quantity: quantity,
      discount: discount,
    );
  }
}

class ProductItem {
  final String id;
  final String name;
  final String productCode;
  final double unitPrice;
  int quantity;
  double discount;

  ProductItem({
    required this.id,
    required this.name,
    required this.productCode,
    required this.unitPrice,
    this.quantity = 1,
    this.discount = 0,
  });

  double get grossTotal => unitPrice * quantity;
  double get subtotal => (grossTotal - discount).clamp(0, double.infinity);

  ProductItem copyWith({
    String? id,
    String? name,
    String? productCode,
    double? unitPrice,
    int? quantity,
    double? discount,
  }) {
    return ProductItem(
      id: id ?? this.id,
      name: name ?? this.name,
      productCode: productCode ?? this.productCode,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }

  factory ProductItem.fromJson(Map<String, dynamic> json) {
    return ProductItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'productCode': productCode,
        'unitPrice': unitPrice,
        'quantity': quantity,
        'discount': discount,
      };
}

class OrderItem {
  final String orderNumber;
  final String customerName;
  final Customer? customer;
  final String date;
  final String time;
  final DateTime createdAt;
  final List<ProductItem> items;
  final double amount;
  final String status;

  OrderItem({
    required this.orderNumber,
    required this.customerName,
    this.customer,
    required this.date,
    this.time = '10:42 AM',
    DateTime? createdAt,
    this.items = const [],
    required this.amount,
    required this.status,
  }) : createdAt = createdAt ?? DateTime(2026, 11, 11);

  int get totalUnits => items.fold(0, (s, p) => s + p.quantity);
  double get grossSubtotal => items.fold(0, (s, p) => s + p.grossTotal);
  double get totalDiscount => items.fold(0, (s, p) => s + p.discount);

  OrderItem copyWith({
    String? orderNumber,
    String? customerName,
    Customer? customer,
    String? date,
    String? time,
    DateTime? createdAt,
    List<ProductItem>? items,
    double? amount,
    String? status,
  }) {
    return OrderItem(
      orderNumber: orderNumber ?? this.orderNumber,
      customerName: customerName ?? this.customerName,
      customer: customer ?? this.customer,
      date: date ?? this.date,
      time: time ?? this.time,
      createdAt: createdAt ?? this.createdAt,
      items: items ?? this.items,
      amount: amount ?? this.amount,
      status: status ?? this.status,
    );
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final parsedItems = rawItems
        .map((e) => ProductItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return OrderItem(
      orderNumber: json['orderNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customer: json['customer'] != null
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '10:42 AM',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() => {
        'orderNumber': orderNumber,
        'customerName': customerName,
        'customer': customer?.toJson(),
        'date': date,
        'time': time,
        'createdAt': createdAt.toIso8601String(),
        'items': items.map((e) => e.toJson()).toList(),
        'amount': amount,
        'status': status,
      };
}

class DashboardOverview {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final String growthText;
  final String completionRateText;
  final String period;
  final String updatedLabel;

  const DashboardOverview({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.growthText,
    required this.completionRateText,
    required this.period,
    this.updatedLabel = 'Updated just now',
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      completedOrders: (json['completedOrders'] as num?)?.toInt() ?? 0,
      growthText: json['growthText'] as String? ?? '+18% vs Oct',
      completionRateText:
          json['completionRateText'] as String? ?? '87% of orders',
      period: json['period'] as String? ?? 'This month',
      updatedLabel: json['updatedLabel'] as String? ?? 'Updated just now',
    );
  }

  Map<String, dynamic> toJson() => {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'growthText': growthText,
        'completionRateText': completionRateText,
        'period': period,
        'updatedLabel': updatedLabel,
      };
}

class PaginatedOrdersResult {
  final List<OrderItem> orders;
  final int totalCount;
  final int totalDatasetCount;
  final int page;
  final int pageSize;
  final bool hasMore;

  const PaginatedOrdersResult({
    required this.orders,
    required this.totalCount,
    required this.totalDatasetCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedOrdersResult.fromJson(Map<String, dynamic> json) {
    final rawOrders = json['orders'] as List<dynamic>? ?? const [];
    return PaginatedOrdersResult(
      orders: rawOrders
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? rawOrders.length,
      totalDatasetCount:
          (json['totalDatasetCount'] as num?)?.toInt() ?? rawOrders.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 4,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}

class OrderDraft {
  final String orderNumber;
  final Customer? customer;
  final List<ProductItem> items;
  final DateTime savedAt;

  const OrderDraft({
    required this.orderNumber,
    this.customer,
    this.items = const [],
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
        'orderNumber': orderNumber,
        'customer': customer?.toJson(),
        'items': items.map((e) => e.toJson()).toList(),
        'savedAt': savedAt.toIso8601String(),
      };
}

class AppNotification {
  final String id;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
    );
  }
}

class UserProfile {
  final String name;
  final String role;
  final String email;
  final String phone;
  final String workspaceName;
  final String currency;

  const UserProfile({
    required this.name,
    required this.role,
    required this.email,
    required this.phone,
    required this.workspaceName,
    required this.currency,
  });
}

List<ProductItem> get defaultProducts => [
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
    ];
