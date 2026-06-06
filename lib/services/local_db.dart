// lib/services/local_db.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class LocalDb {
  static final LocalDb _instance = LocalDb._();
  factory LocalDb() => _instance;
  LocalDb._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'marnie_pos.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE products (
            id TEXT PRIMARY KEY,
            productCode TEXT,
            name TEXT,
            costPrice REAL DEFAULT 0,
            retailPrice REAL DEFAULT 0,
            price REAL DEFAULT 0,
            stock INTEGER DEFAULT 0,
            lowStockThreshold INTEGER DEFAULT 5,
            category TEXT DEFAULT '',
            createdAt TEXT,
            updatedAt TEXT,
            syncedAt TEXT,
            pendingDelete INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE customers (
            id TEXT PRIMARY KEY,
            name TEXT,
            phone TEXT DEFAULT '',
            email TEXT DEFAULT '',
            createdAt TEXT,
            updatedAt TEXT,
            syncedAt TEXT,
            pendingDelete INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE purchases (
            id TEXT PRIMARY KEY,
            created_by TEXT DEFAULT '',
            created_by_email TEXT DEFAULT '',
            customer_id TEXT DEFAULT '',
            customer_name TEXT DEFAULT '',
            product_data TEXT DEFAULT '[]',
            purchase_date TEXT,
            status TEXT DEFAULT 'pending',
            total_amount REAL DEFAULT 0,
            syncedAt TEXT,
            pendingDelete INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // ─── Products ───────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts() async {
    final d = await db;
    final rows = await d.query('products',
        where: 'pendingDelete = 0', orderBy: 'name ASC');
    return rows.map(Product.fromSqlite).toList();
  }

  Future<void> upsertProduct(Product p, {bool markSynced = false}) async {
    final d = await db;
    final row = p.toSqlite();
    if (markSynced) row['syncedAt'] = DateTime.now().toIso8601String();
    row.remove('pendingDelete');
    await d.insert('products', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProductLocal(String id) async {
    final d = await db;
    await d.update('products', {'pendingDelete': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> hardDeleteProduct(String id) async {
    final d = await db;
    await d.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPendingDeleteProducts() async {
    final d = await db;
    return d.query('products', where: 'pendingDelete = 1');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedProducts() async {
    final d = await db;
    return d.query('products',
        where: 'syncedAt IS NULL AND pendingDelete = 0');
  }

  Future<void> markSynced(String table, String id) async {
    final d = await db;
    await d.update(table, {'syncedAt': DateTime.now().toIso8601String()},
        where: 'id = ?', whereArgs: [id]);
  }

  // ─── Customers ──────────────────────────────────────────────────────────────
  Future<List<Customer>> getCustomers() async {
    final d = await db;
    final rows = await d.query('customers',
        where: 'pendingDelete = 0', orderBy: 'name ASC');
    return rows.map(Customer.fromSqlite).toList();
  }

  Future<void> upsertCustomer(Customer c, {bool markSynced = false}) async {
    final d = await db;
    final row = c.toSqlite();
    if (markSynced) row['syncedAt'] = DateTime.now().toIso8601String();
    row.remove('pendingDelete');
    await d.insert('customers', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCustomerLocal(String id) async {
    final d = await db;
    await d.update('customers', {'pendingDelete': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> hardDeleteCustomer(String id) async {
    final d = await db;
    await d.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPendingDeleteCustomers() async {
    final d = await db;
    return d.query('customers', where: 'pendingDelete = 1');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedCustomers() async {
    final d = await db;
    return d.query('customers',
        where: 'syncedAt IS NULL AND pendingDelete = 0');
  }

  // ─── Purchases ──────────────────────────────────────────────────────────────
  Future<List<Purchase>> getPurchases() async {
    final d = await db;
    final rows = await d.query('purchases',
        where: 'pendingDelete = 0', orderBy: 'purchase_date DESC');
    return rows.map(Purchase.fromSqlite).toList();
  }

  Future<void> upsertPurchase(Purchase p, {bool markSynced = false}) async {
    final d = await db;
    final row = p.toSqlite();
    if (markSynced) row['syncedAt'] = DateTime.now().toIso8601String();
    row.remove('pendingDelete');
    await d.insert('purchases', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deletePurchaseLocal(String id) async {
    final d = await db;
    await d.update('purchases', {'pendingDelete': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> hardDeletePurchase(String id) async {
    final d = await db;
    await d.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getPendingDeletePurchases() async {
    final d = await db;
    return d.query('purchases', where: 'pendingDelete = 1');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedPurchases() async {
    final d = await db;
    return d.query('purchases',
        where: 'syncedAt IS NULL AND pendingDelete = 0');
  }
}
