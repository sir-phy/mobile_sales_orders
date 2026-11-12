import 'customer.dart';
import 'product.dart';

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
        .whereType<Map<String, dynamic>>()
        .map(ProductItem.fromJson)
        .toList();
    return OrderItem(
      orderNumber: json['orderNumber'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      customer: json['customer'] is Map<String, dynamic>
          ? Customer.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '10:42 AM',
      createdAt: json['createdAt'] is String
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
          .whereType<Map<String, dynamic>>()
          .map(OrderItem.fromJson)
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

