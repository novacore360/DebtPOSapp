// lib/models/models.dart
import 'dart:convert';

// ─── Product ──────────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String productCode;
  final String name;
  final double costPrice;
  final double retailPrice;
  int stock;
  final int lowStockThreshold;
  final String category;
  final String? createdAt;
  final String? updatedAt;

  Product({
    required this.id,
    required this.productCode,
    required this.name,
    required this.costPrice,
    required this.retailPrice,
    required this.stock,
    this.lowStockThreshold = 5,
    this.category = '',
    this.createdAt,
    this.updatedAt,
  });

  double get price => retailPrice;

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    final retail = (data['retailPrice'] ?? data['price'] ?? 0).toDouble();
    return Product(
      id: id,
      productCode: data['productCode']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      costPrice: (data['costPrice'] ?? 0).toDouble(),
      retailPrice: retail,
      stock: (data['stock'] ?? 0).toInt(),
      lowStockThreshold: (data['lowStockThreshold'] ?? 5).toInt(),
      category: data['category']?.toString() ?? '',
      createdAt: data['createdAt']?.toString(),
      updatedAt: data['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'productCode': productCode,
    'name': name,
    'costPrice': costPrice,
    'retailPrice': retailPrice,
    'price': retailPrice,
    'stock': stock,
    'lowStockThreshold': lowStockThreshold,
    'category': category,
  };

  factory Product.fromSqlite(Map<String, dynamic> row) {
    final retail = (row['retailPrice'] ?? row['price'] ?? 0).toDouble();
    return Product(
      id: row['id']?.toString() ?? '',
      productCode: row['productCode']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      costPrice: (row['costPrice'] ?? 0).toDouble(),
      retailPrice: retail,
      stock: (row['stock'] ?? 0).toInt(),
      lowStockThreshold: (row['lowStockThreshold'] ?? 5).toInt(),
      category: row['category']?.toString() ?? '',
      createdAt: row['createdAt']?.toString(),
      updatedAt: row['updatedAt']?.toString(),
    );
  }

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'productCode': productCode,
    'name': name,
    'costPrice': costPrice,
    'retailPrice': retailPrice,
    'price': retailPrice,
    'stock': stock,
    'lowStockThreshold': lowStockThreshold,
    'category': category,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'syncedAt': null,
    'pendingDelete': 0,
  };

  Product copyWith({
    String? productCode, String? name, double? costPrice,
    double? retailPrice, int? stock, int? lowStockThreshold, String? category,
  }) => Product(
    id: id,
    productCode: productCode ?? this.productCode,
    name: name ?? this.name,
    costPrice: costPrice ?? this.costPrice,
    retailPrice: retailPrice ?? this.retailPrice,
    stock: stock ?? this.stock,
    lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    category: category ?? this.category,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ─── Customer ─────────────────────────────────────────────────────────────────
class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? createdAt;
  final String? updatedAt;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Customer.fromFirestore(String id, Map<String, dynamic> data) => Customer(
    id: id,
    name: data['name']?.toString() ?? '',
    phone: data['phone']?.toString() ?? '',
    email: data['email']?.toString() ?? '',
    createdAt: data['createdAt']?.toString(),
    updatedAt: data['updatedAt']?.toString(),
  );

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'phone': phone,
    'email': email,
  };

  factory Customer.fromSqlite(Map<String, dynamic> row) => Customer(
    id: row['id']?.toString() ?? '',
    name: row['name']?.toString() ?? '',
    phone: row['phone']?.toString() ?? '',
    email: row['email']?.toString() ?? '',
    createdAt: row['createdAt']?.toString(),
    updatedAt: row['updatedAt']?.toString(),
  );

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'syncedAt': null,
    'pendingDelete': 0,
  };

  Customer copyWith({String? name, String? phone, String? email}) => Customer(
    id: id,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

// ─── Purchase Item ─────────────────────────────────────────────────────────────
class PurchaseItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final double subtotal;

  const PurchaseItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory PurchaseItem.fromMap(Map<String, dynamic> m) => PurchaseItem(
    productId: m['product_id']?.toString() ?? '',
    name: m['name']?.toString() ?? '',
    price: (m['price'] ?? 0).toDouble(),
    quantity: (m['quantity'] ?? 0).toInt(),
    subtotal: (m['subtotal'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'product_id': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'subtotal': subtotal,
  };
}

// ─── Purchase ─────────────────────────────────────────────────────────────────
class Purchase {
  final String id;
  final String createdBy;
  final String createdByEmail;
  final String customerId;
  final String customerName;
  final List<PurchaseItem> productData;
  final String productDataRaw;
  final String purchaseDate;
  String status;
  final double totalAmount;

  Purchase({
    required this.id,
    required this.createdBy,
    required this.createdByEmail,
    required this.customerId,
    required this.customerName,
    required this.productData,
    required this.productDataRaw,
    required this.purchaseDate,
    required this.status,
    required this.totalAmount,
  });

  factory Purchase.fromFirestore(String id, Map<String, dynamic> data) {
    List<PurchaseItem> items = [];
    final rawVal = data['product_data'];
    final raw = rawVal is String ? rawVal : '[]';
    try {
      final list = jsonDecode(raw) as List;
      items = list.map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    return Purchase(
      id: id,
      createdBy: data['created_by']?.toString() ?? '',
      createdByEmail: data['created_by_email']?.toString() ?? '',
      customerId: data['customer_id']?.toString() ?? '',
      customerName: data['customer_name']?.toString() ?? '',
      productData: items,
      productDataRaw: raw,
      purchaseDate: data['purchase_date']?.toString() ?? DateTime.now().toIso8601String(),
      status: data['status']?.toString() ?? 'pending',
      totalAmount: (data['total_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'created_by': createdBy,
    'created_by_email': createdByEmail,
    'customer_id': customerId,
    'customer_name': customerName,
    'product_data': productDataRaw,
    'purchase_date': purchaseDate,
    'status': status,
    'total_amount': totalAmount,
  };

  factory Purchase.fromSqlite(Map<String, dynamic> row) {
    final raw = row['product_data']?.toString() ?? '[]';
    List<PurchaseItem> items = [];
    try {
      final list = jsonDecode(raw) as List;
      items = list.map((e) => PurchaseItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {}
    return Purchase(
      id: row['id']?.toString() ?? '',
      createdBy: row['created_by']?.toString() ?? '',
      createdByEmail: row['created_by_email']?.toString() ?? '',
      customerId: row['customer_id']?.toString() ?? '',
      customerName: row['customer_name']?.toString() ?? '',
      productData: items,
      productDataRaw: raw,
      purchaseDate: row['purchase_date']?.toString() ?? DateTime.now().toIso8601String(),
      status: row['status']?.toString() ?? 'pending',
      totalAmount: (row['total_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toSqlite() => {
    'id': id,
    'created_by': createdBy,
    'created_by_email': createdByEmail,
    'customer_id': customerId,
    'customer_name': customerName,
    'product_data': productDataRaw,
    'purchase_date': purchaseDate,
    'status': status,
    'total_amount': totalAmount,
    'syncedAt': null,
    'pendingDelete': 0,
  };

  Purchase copyWith({
    String? status,
    double? totalAmount,
    String? productDataRaw,
    List<PurchaseItem>? productData,
  }) => Purchase(
    id: id,
    createdBy: createdBy,
    createdByEmail: createdByEmail,
    customerId: customerId,
    customerName: customerName,
    productData: productData ?? this.productData,
    productDataRaw: productDataRaw ?? this.productDataRaw,
    purchaseDate: purchaseDate,
    status: status ?? this.status,
    totalAmount: totalAmount ?? this.totalAmount,
  );
}
