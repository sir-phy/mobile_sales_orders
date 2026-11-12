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
    final parsedPrice = (json['unitPrice'] as num?)?.toDouble() ?? 0;
    final parsedStock = (json['stock'] as num?)?.toInt() ?? 0;
    return ProductCatalogItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      unitPrice: parsedPrice < 0 ? 0 : parsedPrice,
      category: json['category'] as String? ?? 'General',
      stock: parsedStock < 0 ? 0 : parsedStock,
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
    final parsedPrice = (json['unitPrice'] as num?)?.toDouble() ?? 0;
    final parsedQty = (json['quantity'] as num?)?.toInt() ?? 1;
    final parsedDiscount = (json['discount'] as num?)?.toDouble() ?? 0;
    return ProductItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      productCode: json['productCode'] as String? ?? '',
      unitPrice: parsedPrice < 0 ? 0 : parsedPrice,
      quantity: parsedQty < 1 ? 1 : parsedQty,
      discount: parsedDiscount < 0 ? 0 : parsedDiscount,
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

