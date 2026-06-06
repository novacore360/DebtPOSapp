// lib/screens/new_purchase_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/data_provider.dart';
import '../utils/theme.dart';
import '../widgets/app_widgets.dart';
import 'products_screen.dart' show BarcodeScanPage;

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});
  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  // Customer
  final _custNameCtrl  = TextEditingController();
  final _custPhoneCtrl = TextEditingController();
  final _custEmailCtrl = TextEditingController();
  Customer? _selectedCustomer;
  List<Customer> _custSuggestions = [];

  // Product
  final _productSearchCtrl = TextEditingController();
  Product? _selectedProduct;
  List<Product> _productSuggestions = [];
  int _qty = 1;

  // Cart
  final List<_CartItem> _cart = [];
  bool _finalizing = false;
  _ReceiptData? _receipt;

  // ── Customer autocomplete ──────────────────────────────────────────────────
  void _onCustChanged(String val) {
    _selectedCustomer = null;
    if (val.trim().isEmpty) { setState(() => _custSuggestions = []); return; }
    final q  = val.toLowerCase();
    final dp = context.read<DataProvider>();
    setState(() {
      _custSuggestions = dp.customers
          .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
          .take(6).toList();
    });
  }

  void _selectCustomer(Customer c) {
    setState(() {
      _selectedCustomer    = c;
      _custNameCtrl.text   = c.name;
      _custPhoneCtrl.text  = c.phone;
      _custEmailCtrl.text  = c.email;
      _custSuggestions     = [];
    });
  }

  void _clearCustomer() => setState(() {
    _selectedCustomer = null;
    _custNameCtrl.clear(); _custPhoneCtrl.clear(); _custEmailCtrl.clear();
    _custSuggestions = [];
  });

  // ── Product autocomplete ───────────────────────────────────────────────────
  void _onProductChanged(String val) {
    _selectedProduct = null;
    if (val.trim().isEmpty) { setState(() => _productSuggestions = []); return; }
    final q  = val.toLowerCase();
    final dp = context.read<DataProvider>();
    setState(() {
      _productSuggestions = dp.products
          .where((p) => p.name.toLowerCase().contains(q) ||
              p.productCode.toLowerCase().contains(q))
          .take(8).toList();
    });
  }

  void _selectProduct(Product p) => setState(() {
    _selectedProduct         = p;
    _productSearchCtrl.text  = p.name;
    _productSuggestions      = [];
  });

  // ── Barcode scanner ────────────────────────────────────────────────────────
  void _openScanner() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScanPage()),
    );
    if (code == null || !mounted) return;
    final dp = context.read<DataProvider>();
    final found = dp.products.where((p) =>
        p.productCode == code ||
        p.productCode.toLowerCase() == code.toLowerCase()).firstOrNull;
    if (found != null) {
      _selectProduct(found);
    } else {
      showToast(context, 'No product found for barcode: "$code"', error: true);
    }
  }

  // ── Cart ───────────────────────────────────────────────────────────────────
  void _addToCart() {
    final p = _selectedProduct;
    if (p == null) { showToast(context, 'Please select a product.', error: true); return; }
    if (_qty < 1)  { showToast(context, 'Quantity must be at least 1.', error: true); return; }
    if (_qty > p.stock) {
      showToast(context, 'Only ${p.stock} units available.', error: true); return;
    }
    setState(() {
      final idx = _cart.indexWhere((i) => i.productId == p.id);
      if (idx >= 0) {
        final newQty = _cart[idx].quantity + _qty;
        if (newQty > p.stock) {
          showToast(context, 'Only ${p.stock} units available.', error: true); return;
        }
        _cart[idx] = _cart[idx].copyWith(quantity: newQty);
      } else {
        _cart.add(_CartItem(
          productId: p.id, name: p.name,
          price: p.retailPrice, quantity: _qty));
      }
      _selectedProduct = null;
      _productSearchCtrl.clear();
      _productSuggestions = [];
      _qty = 1;
    });
  }

  void _removeFromCart(int i) => setState(() => _cart.removeAt(i));

  void _updateQty(int idx, int newQty) {
    if (newQty < 1) return;
    final dp = context.read<DataProvider>();
    final prod = dp.products.where((p) => p.id == _cart[idx].productId).firstOrNull;
    if (prod != null && newQty > prod.stock) {
      showToast(context, 'Only ${prod.stock} in stock.', error: true); return;
    }
    setState(() => _cart[idx] = _cart[idx].copyWith(quantity: newQty));
  }

  double get _total      => _cart.fold(0, (s, i) => s + i.subtotal);
  int    get _totalItems => _cart.fold(0, (s, i) => s + i.quantity);

  // ── Finalize ───────────────────────────────────────────────────────────────
  Future<void> _finalize() async {
    if (_cart.isEmpty)             { showToast(context, 'Cart is empty.', error: true); return; }
    if (_custNameCtrl.text.isEmpty){ showToast(context, 'Customer name is required.', error: true); return; }
    setState(() => _finalizing = true);
    try {
      final dp = context.read<DataProvider>();
      final customer = _selectedCustomer ?? await dp.addCustomer({
        'name': _custNameCtrl.text.trim(),
        'phone': _custPhoneCtrl.text.trim(),
        'email': _custEmailCtrl.text.trim(),
      });

      final items = _cart.map((i) => PurchaseItem(
        productId: i.productId, name: i.name,
        price: i.price, quantity: i.quantity, subtotal: i.subtotal,
      )).toList();

      await dp.addPurchase(
        customerId: customer.id, customerName: customer.name,
        items: items, totalAmount: _total, status: 'pending',
        purchaseDate: DateTime.now().toIso8601String(),
      );

      // Deduct stock
      for (final item in _cart) {
        final p = dp.products.where((p) => p.id == item.productId).firstOrNull;
        if (p != null) {
          await dp.updateProduct(item.productId,
              {'stock': (p.stock - item.quantity).clamp(0, 999999)});
        }
      }

      final snap = _ReceiptData(
        customer: customer, items: List.from(_cart),
        totalAmount: _total, date: DateTime.now());

      setState(() {
        _receipt = snap; _cart.clear(); _clearCustomer();
      });
    } catch (e) {
      if (mounted) showToast(context, 'Failed: $e', error: true);
    } finally {
      if (mounted) setState(() => _finalizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    return Column(children: [
      if (!dp.isOnline) const OfflineBanner(),
      Expanded(child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // ── Customer ──
          AppCard(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer', style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _AcField(
                label: 'Name *', hint: 'Search or type new customer…',
                controller: _custNameCtrl, onChanged: _onCustChanged,
                showClear: _selectedCustomer != null, onClear: _clearCustomer,
                suggestions: _custSuggestions,
                buildRow: (s) {
                  final c = s as Customer;
                  return _SuggRow(
                    main: c.name,
                    sub: c.phone.isNotEmpty ? c.phone : null,
                  );
                },
                onSelect: (s) => _selectCustomer(s as Customer),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: AppTextField(label: 'Phone', hint: 'Optional',
                    controller: _custPhoneCtrl, keyboardType: TextInputType.phone)),
                const SizedBox(width: 10),
                Expanded(child: AppTextField(label: 'Email', hint: 'Optional',
                    controller: _custEmailCtrl,
                    keyboardType: TextInputType.emailAddress)),
              ]),
            ],
          )),
          const SizedBox(height: 14),

          // ── Add Product ──
          AppCard(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Product', style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _AcField(
                label: 'Search product by name or barcode',
                hint: 'Product name or code…',
                controller: _productSearchCtrl,
                onChanged: _onProductChanged,
                showClear: false, onClear: () {},
                trailing: GestureDetector(
                  onTap: _openScanner,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_scanner,
                        color: AppColors.primary, size: 20),
                  ),
                ),
                suggestions: _productSuggestions,
                buildRow: (s) {
                  final p = s as Product;
                  return _SuggRow(
                    main: p.name,
                    code: p.productCode,
                    price: '₱${p.retailPrice.toStringAsFixed(2)}',
                    sub: 'Stock: ${p.stock}',
                    subColor: p.stock == 0 ? AppColors.red : AppColors.textMuted,
                  );
                },
                onSelect: (s) => _selectProduct(s as Product),
              ),
              // Selected preview
              if (_selectedProduct != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_selectedProduct!.name,
                          style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('₱${_selectedProduct!.retailPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12)),
                    ])),
                    Text('Stock: ${_selectedProduct!.stock}',
                        style: GoogleFonts.dmSans(
                            color: _selectedProduct!.stock == 0 ? AppColors.red : AppColors.green,
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ],
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Quantity', style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 5),
                  _QtyStepper(
                    value: _qty,
                    onDecrement: () => setState(() { if (_qty > 1) _qty--; }),
                    onIncrement: () => setState(() => _qty++),
                  ),
                ])),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: ElevatedButton.icon(
                    onPressed: _addToCart,
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Add'),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)),
                  ),
                ),
              ]),
            ],
          )),
          const SizedBox(height: 14),

          // ── Cart ──
          AppCard(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.shopping_cart, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text('Cart', style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  if (_totalItems > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$_totalItems',
                          style: GoogleFonts.dmSans(color: AppColors.primary,
                              fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ]),
                if (_cart.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _cart.clear()),
                    child: Text('Clear All', style: GoogleFonts.dmSans(
                        color: AppColors.red, fontSize: 12)),
                  ),
              ]),
              const SizedBox(height: 10),

              if (_cart.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(children: [
                    const Icon(Icons.shopping_cart_outlined,
                        color: AppColors.textMuted, size: 44),
                    const SizedBox(height: 8),
                    Text('Cart is empty', style: GoogleFonts.dmSans(
                        color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 3),
                    Text('Scan a barcode or search for a product',
                        style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
                  ]),
                )
              else ...[
                ...List.generate(_cart.length, (idx) {
                  final item = _cart[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                          color: AppColors.border.withOpacity(0.5))),
                    ),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(item.name,
                            style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                                fontSize: 13, fontWeight: FontWeight.w600),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text('₱${item.price.toStringAsFixed(2)} each',
                            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
                      ])),
                      const SizedBox(width: 8),
                      _QtyStepper(
                        value: item.quantity, compact: true,
                        onDecrement: () => _updateQty(idx, item.quantity - 1),
                        onIncrement: () => _updateQty(idx, item.quantity + 1),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70,
                        child: Text('₱${item.subtotal.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.dmSans(color: AppColors.green,
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _removeFromCart(idx),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.red.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.close,
                              color: AppColors.red, size: 13),
                        ),
                      ),
                    ]),
                  );
                }),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('TOTAL', style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 15,
                      fontWeight: FontWeight.w800)),
                  Text('₱${_total.toStringAsFixed(2)}',
                      style: GoogleFonts.dmSans(color: AppColors.green,
                          fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: 'Finalize Purchase',
                  icon: Icons.check_circle_outline,
                  color: AppColors.green,
                  loading: _finalizing,
                  onPressed: _finalize,
                ),
              ],
            ],
          )),
        ]),
      )),

      // ── Receipt overlay ──
      if (_receipt != null) _ReceiptOverlay(
        receipt: _receipt!,
        onClose: () => setState(() => _receipt = null),
      ),
    ]);
  }

  @override
  void dispose() {
    _custNameCtrl.dispose(); _custPhoneCtrl.dispose(); _custEmailCtrl.dispose();
    _productSearchCtrl.dispose();
    super.dispose();
  }
}

// ─── Autocomplete field ───────────────────────────────────────────────────────
class _AcField extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final void Function(String) onChanged;
  final bool showClear;
  final VoidCallback onClear;
  final Widget? trailing;
  final List<dynamic> suggestions;
  final Widget Function(dynamic) buildRow;
  final void Function(dynamic) onSelect;

  const _AcField({
    required this.label, required this.hint, required this.controller,
    required this.onChanged, required this.showClear, required this.onClear,
    this.trailing, required this.suggestions,
    required this.buildRow, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: GoogleFonts.dmSans(
          color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 5),
      Stack(clipBehavior: Clip.none, children: [
        TextField(
          controller: controller, onChanged: onChanged,
          style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
            prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 18),
            suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
              if (showClear) IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMuted, size: 16),
                onPressed: onClear),
              if (trailing != null) trailing!,
            ]),
            filled: true, fillColor: const Color(0x0FFFFFFF),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
        if (suggestions.isNotEmpty)
          Positioned(top: 52, left: 0, right: 0, child: Material(
            color: const Color(0xFF1E2035),
            borderRadius: BorderRadius.circular(10),
            elevation: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView(
                  padding: EdgeInsets.zero, shrinkWrap: true,
                  children: suggestions.map((s) => InkWell(
                    onTap: () => onSelect(s),
                    child: buildRow(s),
                  )).toList(),
                ),
              ),
            ),
          )),
      ]),
    ]);
  }
}

// ─── Suggestion row ───────────────────────────────────────────────────────────
class _SuggRow extends StatelessWidget {
  final String main;
  final String? sub, code, price;
  final Color? subColor;
  const _SuggRow({required this.main, this.sub, this.code, this.price, this.subColor});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border))),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(main, style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis)),
          if (code != null) ...[
            const SizedBox(width: 4),
            Text(code!, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10)),
          ],
        ]),
        if (sub != null)
          Text(sub!, style: GoogleFonts.dmSans(
              color: subColor ?? AppColors.textMuted, fontSize: 11)),
      ])),
      if (price != null) Text(price!, style: GoogleFonts.dmSans(
          color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w700)),
    ]),
  );
}

// ─── Qty stepper ──────────────────────────────────────────────────────────────
class _QtyStepper extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement, onIncrement;
  final bool compact;
  const _QtyStepper({required this.value, required this.onDecrement,
      required this.onIncrement, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 34.0;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _Btn(Icons.remove, onDecrement, size),
        SizedBox(
          width: compact ? 28 : 36,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                  fontSize: compact ? 13 : 15, fontWeight: FontWeight.w700)),
        ),
        _Btn(Icons.add, onIncrement, size),
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const _Btn(this.icon, this.onTap, this.size);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.45),
    ),
  );
}

// ─── Cart item model ───────────────────────────────────────────────────────────
class _CartItem {
  final String productId, name;
  final double price;
  final int quantity;

  const _CartItem({required this.productId, required this.name,
      required this.price, required this.quantity});

  double get subtotal => price * quantity;

  _CartItem copyWith({int? quantity}) => _CartItem(
    productId: productId, name: name, price: price,
    quantity: quantity ?? this.quantity,
  );
}

class _ReceiptData {
  final Customer customer;
  final List<_CartItem> items;
  final double totalAmount;
  final DateTime date;
  const _ReceiptData({required this.customer, required this.items,
      required this.totalAmount, required this.date});
}

// ─── Receipt overlay ───────────────────────────────────────────────────────────
class _ReceiptOverlay extends StatelessWidget {
  final _ReceiptData receipt;
  final VoidCallback onClose;
  const _ReceiptOverlay({required this.receipt, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.88),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, color: AppColors.green, size: 56),
                  const SizedBox(height: 10),
                  Text('Purchase Complete!', style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary, fontSize: 20,
                      fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Status: ', style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 13)),
                    Text('PENDING', style: GoogleFonts.dmSans(
                        color: AppColors.yellow, fontSize: 13, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const Icon(Icons.person, color: AppColors.textSecondary, size: 14),
                        const SizedBox(width: 6),
                        Expanded(child: Text(receipt.customer.name,
                            style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                                fontSize: 13, fontWeight: FontWeight.w600))),
                      ]),
                      const SizedBox(height: 10),
                      ...receipt.items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Expanded(child: Text('${item.name} × ${item.quantity}',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                          Text('₱${item.subtotal.toStringAsFixed(2)}',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ]),
                      )),
                      const Divider(color: AppColors.border, height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('TOTAL', style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary, fontSize: 14,
                            fontWeight: FontWeight.w800)),
                        Text('₱${receipt.totalAmount.toStringAsFixed(2)}',
                            style: GoogleFonts.dmSans(color: AppColors.green,
                                fontSize: 18, fontWeight: FontWeight.w800)),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onClose,
                      icon: const Icon(Icons.close, size: 15),
                      label: const Text('Close & New Sale'),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
