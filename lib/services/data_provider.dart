// lib/services/data_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import 'firestore_service.dart';
import 'local_db.dart';

class DataProvider extends ChangeNotifier {
  final _fs = FirestoreService();
  final _local = LocalDb();

  List<Product>  products  = [];
  List<Customer> customers = [];
  List<Purchase> purchases = [];

  bool isOnline = true;
  bool loading  = true;

  StreamSubscription? _prodSub, _custSub, _purchSub, _connSub;
  bool _fsListening = false;

  Future<void> init() async {
    products  = await _local.getProducts();
    customers = await _local.getCustomers();
    purchases = await _local.getPurchases();
    loading   = false;
    notifyListeners();

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      _handleConnectivityChange(online);
    });

    final result = await Connectivity().checkConnectivity();
    final online = result.any((r) => r != ConnectivityResult.none);
    _handleConnectivityChange(online);
  }

  void _handleConnectivityChange(bool online) {
    isOnline = online;
    notifyListeners();
    if (online) {
      _startFirestoreListeners();
      _fs.syncPendingWrites();
    } else {
      _stopFirestoreListeners();
    }
  }

  void _startFirestoreListeners() {
    if (_fsListening) return;
    _fsListening = true;
    _prodSub = _fs.productsStream().listen((list) { products = list; notifyListeners(); });
    _custSub = _fs.customersStream().listen((list) { customers = list; notifyListeners(); });
    _purchSub = _fs.purchasesStream().listen((list) { purchases = list; notifyListeners(); });
  }

  void _stopFirestoreListeners() {
    _prodSub?.cancel(); _custSub?.cancel(); _purchSub?.cancel();
    _prodSub = _custSub = _purchSub = null;
    _fsListening = false;
  }

  Future<void> addProduct(Map<String, dynamic> data) async {
    if (isOnline) {
      await _fs.addProduct(data);
    } else {
      final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final p = Product.fromFirestore(id, {...data, 'createdAt': DateTime.now().toIso8601String()});
      await _local.upsertProduct(p);
      products = await _local.getProducts();
      notifyListeners();
    }
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    if (isOnline) {
      await _fs.updateProduct(id, data);
    } else {
      final existing = products.firstWhere((p) => p.id == id);
      final updated = Product.fromFirestore(id, {
        'productCode': existing.productCode, 'name': existing.name,
        'costPrice': existing.costPrice, 'retailPrice': existing.retailPrice,
        'price': existing.retailPrice, 'stock': existing.stock,
        'lowStockThreshold': existing.lowStockThreshold, 'category': existing.category,
        ...data, 'updatedAt': DateTime.now().toIso8601String(),
      });
      await _local.upsertProduct(updated);
      products = await _local.getProducts();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    if (isOnline) {
      await _fs.deleteProduct(id);
    } else {
      await _local.deleteProductLocal(id);
      products = await _local.getProducts();
      notifyListeners();
    }
  }

  Future<Customer> addCustomer(Map<String, dynamic> data) async {
    if (isOnline) {
      final id = await _fs.addCustomer(data);
      return Customer.fromFirestore(id, {...data, 'createdAt': DateTime.now().toIso8601String()});
    } else {
      final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final c = Customer.fromFirestore(id, {...data, 'createdAt': DateTime.now().toIso8601String()});
      await _local.upsertCustomer(c);
      customers = await _local.getCustomers();
      notifyListeners();
      return c;
    }
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    if (isOnline) {
      await _fs.updateCustomer(id, data);
    } else {
      final existing = customers.firstWhere((c) => c.id == id);
      final updated = Customer.fromFirestore(id, {
        'name': existing.name, 'phone': existing.phone, 'email': existing.email,
        ...data, 'updatedAt': DateTime.now().toIso8601String(),
      });
      await _local.upsertCustomer(updated);
      customers = await _local.getCustomers();
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    if (isOnline) {
      await _fs.deleteCustomer(id);
    } else {
      await _local.deleteCustomerLocal(id);
      for (final p in purchases.where((p) => p.customerId == id).toList()) {
        await _local.deletePurchaseLocal(p.id);
      }
      customers = await _local.getCustomers();
      purchases = await _local.getPurchases();
      notifyListeners();
    }
  }

  Future<void> addPurchase({
    required String customerId,
    required String customerName,
    required List<PurchaseItem> items,
    required double totalAmount,
    String status = 'pending',
    String? purchaseDate,
  }) async {
    if (isOnline) {
      await _fs.addPurchase(
        customerId: customerId, customerName: customerName,
        items: items, totalAmount: totalAmount, status: status, purchaseDate: purchaseDate,
      );
    } else {
      final id = 'local_${DateTime.now().millisecondsSinceEpoch}';
      final raw = jsonEncode(items.map((i) => i.toMap()).toList());
      final p = Purchase.fromFirestore(id, {
        'created_by': 'offline', 'created_by_email': 'offline',
        'customer_id': customerId, 'customer_name': customerName,
        'product_data': raw, 'purchase_date': purchaseDate ?? DateTime.now().toIso8601String(),
        'status': status, 'total_amount': totalAmount,
      });
      await _local.upsertPurchase(p);
      purchases = await _local.getPurchases();
      notifyListeners();
    }
  }

  Future<void> updatePurchase(String id, Map<String, dynamic> updates) async {
    if (isOnline) {
      await _fs.updatePurchase(id, updates);
    } else {
      final existing = purchases.firstWhere((p) => p.id == id);
      final updated = existing.copyWith(
        status: updates['status'] as String? ?? existing.status,
        totalAmount: (updates['total_amount'] as num?)?.toDouble() ?? existing.totalAmount,
      );
      await _local.upsertPurchase(updated);
      purchases = await _local.getPurchases();
      notifyListeners();
    }
  }

  Future<void> deletePurchase(String id) async {
    if (isOnline) {
      await _fs.deletePurchase(id);
    } else {
      await _local.deletePurchaseLocal(id);
      purchases = await _local.getPurchases();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _prodSub?.cancel(); _custSub?.cancel(); _purchSub?.cancel(); _connSub?.cancel();
    super.dispose();
  }
}
