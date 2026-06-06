// lib/services/firestore_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import 'local_db.dart';

const _uuid = Uuid();

class FirestoreService {
  static final FirestoreService _i = FirestoreService._();
  factory FirestoreService() => _i;
  FirestoreService._();

  final _fs   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _local = LocalDb();

  // ─── Real-time streams → also mirror to local DB ──────────────────────────
  Stream<List<Product>> productsStream() {
    return _fs.collection('products')
        .orderBy('name')
        .snapshots()
        .asyncMap((snap) async {
      final items = snap.docs
          .map((d) => Product.fromFirestore(d.id, d.data()))
          .toList();
      for (final p in items) {
        await _local.upsertProduct(p, markSynced: true);
      }
      return items;
    });
  }

  Stream<List<Customer>> customersStream() {
    return _fs.collection('customers')
        .orderBy('name')
        .snapshots()
        .asyncMap((snap) async {
      final items = snap.docs
          .map((d) => Customer.fromFirestore(d.id, d.data()))
          .toList();
      for (final c in items) {
        await _local.upsertCustomer(c, markSynced: true);
      }
      return items;
    });
  }

  Stream<List<Purchase>> purchasesStream() {
    return _fs.collection('purchases')
        .orderBy('purchase_date', descending: true)
        .snapshots()
        .asyncMap((snap) async {
      final items = snap.docs
          .map((d) => Purchase.fromFirestore(d.id, d.data()))
          .toList();
      for (final p in items) {
        await _local.upsertPurchase(p, markSynced: true);
      }
      return items;
    });
  }

  // ─── Products CRUD ──────────────────────────────────────────────────────────
  Future<String> addProduct(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    final payload = {...data, 'createdAt': DateTime.now().toIso8601String()};
    await _local.upsertProduct(Product.fromFirestore(id, payload));
    await _fs.collection('products').doc(id).set(payload);
    await _local.markSynced('products', id);
    return id;
  }

  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final payload = {...data, 'updatedAt': DateTime.now().toIso8601String()};
    await _fs.collection('products').doc(id).update(payload);
    // Refresh local from Firestore after update
    final snap = await _fs.collection('products').doc(id).get();
    if (snap.exists) {
      await _local.upsertProduct(
          Product.fromFirestore(id, snap.data()!), markSynced: true);
    }
  }

  Future<void> deleteProduct(String id) async {
    await _local.deleteProductLocal(id);
    await _fs.collection('products').doc(id).delete();
    await _local.hardDeleteProduct(id);
  }

  // ─── Customers CRUD ─────────────────────────────────────────────────────────
  Future<String> addCustomer(Map<String, dynamic> data) async {
    final id = _uuid.v4();
    final payload = {...data, 'createdAt': DateTime.now().toIso8601String()};
    await _local.upsertCustomer(Customer.fromFirestore(id, payload));
    await _fs.collection('customers').doc(id).set(payload);
    await _local.markSynced('customers', id);
    return id;
  }

  Future<void> updateCustomer(String id, Map<String, dynamic> data) async {
    final payload = {...data, 'updatedAt': DateTime.now().toIso8601String()};
    await _fs.collection('customers').doc(id).update(payload);
    final snap = await _fs.collection('customers').doc(id).get();
    if (snap.exists) {
      await _local.upsertCustomer(
          Customer.fromFirestore(id, snap.data()!), markSynced: true);
    }
  }

  Future<void> deleteCustomer(String id) async {
    final batch = _fs.batch();
    final pSnap = await _fs.collection('purchases')
        .where('customer_id', isEqualTo: id).get();
    for (final doc in pSnap.docs) {
      batch.delete(doc.reference);
      await _local.hardDeletePurchase(doc.id);
    }
    batch.delete(_fs.collection('customers').doc(id));
    await batch.commit();
    await _local.hardDeleteCustomer(id);
  }

  // ─── Purchases CRUD ─────────────────────────────────────────────────────────
  Future<String> addPurchase({
    required String customerId,
    required String customerName,
    required List<PurchaseItem> items,
    required double totalAmount,
    String status = 'pending',
    String? purchaseDate,
  }) async {
    final user = _auth.currentUser;
    final id = _uuid.v4();
    final raw = jsonEncode(items.map((i) => i.toMap()).toList());
    final payload = {
      'created_by': user?.uid ?? 'unknown',
      'created_by_email': user?.email ?? 'unknown',
      'customer_id': customerId,
      'customer_name': customerName,
      'product_data': raw,
      'purchase_date': purchaseDate ?? DateTime.now().toIso8601String(),
      'status': status,
      'total_amount': totalAmount,
    };
    await _local.upsertPurchase(Purchase.fromFirestore(id, payload));
    await _fs.collection('purchases').doc(id).set(payload);
    await _local.markSynced('purchases', id);
    return id;
  }

  Future<void> updatePurchase(String id, Map<String, dynamic> updates) async {
    final payload = <String, dynamic>{};
    if (updates.containsKey('status'))        payload['status']        = updates['status'];
    if (updates.containsKey('total_amount'))  payload['total_amount']  = updates['total_amount'];
    if (updates.containsKey('customer_name')) payload['customer_name'] = updates['customer_name'];
    if (updates.containsKey('purchase_date')) payload['purchase_date'] = updates['purchase_date'];
    if (updates.containsKey('product_data')) {
      final pd = updates['product_data'];
      payload['product_data'] = pd is List ? jsonEncode(pd) : pd;
    }
    await _fs.collection('purchases').doc(id).update(payload);
    final snap = await _fs.collection('purchases').doc(id).get();
    if (snap.exists) {
      await _local.upsertPurchase(
          Purchase.fromFirestore(id, snap.data()!), markSynced: true);
    }
  }

  Future<void> deletePurchase(String id) async {
    await _local.deletePurchaseLocal(id);
    await _fs.collection('purchases').doc(id).delete();
    await _local.hardDeletePurchase(id);
  }

  // ─── Sync pending local-only writes → Firestore ───────────────────────────
  Future<void> syncPendingWrites() async {
    // Products
    for (final row in await _local.getUnsyncedProducts()) {
      try {
        await _fs.collection('products').doc(row['id'] as String).set(
          Product.fromSqlite(row).toFirestore(), SetOptions(merge: true));
        await _local.markSynced('products', row['id'] as String);
      } catch (_) {}
    }
    for (final row in await _local.getPendingDeleteProducts()) {
      try {
        await _fs.collection('products').doc(row['id'] as String).delete();
        await _local.hardDeleteProduct(row['id'] as String);
      } catch (_) {}
    }

    // Customers
    for (final row in await _local.getUnsyncedCustomers()) {
      try {
        await _fs.collection('customers').doc(row['id'] as String).set(
          Customer.fromSqlite(row).toFirestore(), SetOptions(merge: true));
        await _local.markSynced('customers', row['id'] as String);
      } catch (_) {}
    }
    for (final row in await _local.getPendingDeleteCustomers()) {
      try {
        await _fs.collection('customers').doc(row['id'] as String).delete();
        await _local.hardDeleteCustomer(row['id'] as String);
      } catch (_) {}
    }

    // Purchases
    for (final row in await _local.getUnsyncedPurchases()) {
      try {
        await _fs.collection('purchases').doc(row['id'] as String).set(
          Purchase.fromSqlite(row).toFirestore(), SetOptions(merge: true));
        await _local.markSynced('purchases', row['id'] as String);
      } catch (_) {}
    }
    for (final row in await _local.getPendingDeletePurchases()) {
      try {
        await _fs.collection('purchases').doc(row['id'] as String).delete();
        await _local.hardDeletePurchase(row['id'] as String);
      } catch (_) {}
    }
  }
}
