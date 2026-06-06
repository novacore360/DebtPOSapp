// lib/screens/products_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/data_provider.dart';
import '../utils/theme.dart';
import '../widgets/app_widgets.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchCtrl   = TextEditingController();
  final _codeCtrl     = TextEditingController();
  final _nameCtrl     = TextEditingController();
  final _costCtrl     = TextEditingController();
  final _retailCtrl   = TextEditingController();
  final _stockCtrl    = TextEditingController(text: '0');
  final _threshCtrl   = TextEditingController(text: '5');
  final _categoryCtrl = TextEditingController();

  String _search   = '';
  bool   _showForm = false;
  String? _editingId;
  bool   _saving   = false;
  String? _error;

  void _clearForm() {
    _codeCtrl.clear(); _nameCtrl.clear(); _costCtrl.clear();
    _retailCtrl.clear(); _stockCtrl.text = '0'; _threshCtrl.text = '5';
    _categoryCtrl.clear(); _editingId = null; _error = null;
  }

  void _startEdit(Product p) {
    _editingId         = p.id;
    _codeCtrl.text     = p.productCode;
    _nameCtrl.text     = p.name;
    _costCtrl.text     = p.costPrice.toStringAsFixed(2);
    _retailCtrl.text   = p.retailPrice.toStringAsFixed(2);
    _stockCtrl.text    = p.stock.toString();
    _threshCtrl.text   = p.lowStockThreshold.toString();
    _categoryCtrl.text = p.category;
    setState(() { _showForm = true; _error = null; });
  }

  Future<void> _submit() async {
    final dp     = context.read<DataProvider>();
    final code   = _codeCtrl.text.trim();
    final name   = _nameCtrl.text.trim();
    final cost   = double.tryParse(_costCtrl.text.trim());
    final retail = double.tryParse(_retailCtrl.text.trim());

    if (code.isEmpty || name.isEmpty || cost == null || retail == null) {
      setState(() => _error = 'Fill all required fields (Code, Name, Cost Price, Retail Price).');
      return;
    }
    if (retail < cost) {
      setState(() => _error = 'Retail price must be ≥ cost price.');
      return;
    }
    final dup = dp.products.any((p) => p.productCode == code && p.id != _editingId);
    if (dup) {
      setState(() => _error = 'Product code already exists.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final data = {
        'productCode': code,
        'name': name,
        'costPrice': cost,
        'retailPrice': retail,
        'price': retail,
        'stock': int.tryParse(_stockCtrl.text.trim()) ?? 0,
        'lowStockThreshold': int.tryParse(_threshCtrl.text.trim()) ?? 5,
        'category': _categoryCtrl.text.trim(),
      };
      if (_editingId != null) {
        await dp.updateProduct(_editingId!, data);
        if (mounted) showToast(context, 'Product updated');
      } else {
        await dp.addProduct(data);
        if (mounted) showToast(context, 'Product added');
      }
      setState(() { _showForm = false; _clearForm(); });
    } catch (e) {
      setState(() => _error = 'Failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteProduct(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete Product',
        message: 'Delete "${p.name}"? This cannot be undone.',
      ),
    );
    if (ok == true && mounted) {
      await context.read<DataProvider>().deleteProduct(p.id);
      showToast(context, 'Product deleted');
    }
  }

  void _openScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScanPage()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _codeCtrl.text = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final q  = _search.toLowerCase();
    final filtered = dp.products.where((p) =>
        p.name.toLowerCase().contains(q) ||
        p.productCode.toLowerCase().contains(q) ||
        p.category.toLowerCase().contains(q)).toList();

    return Column(children: [
      if (!dp.isOnline) const OfflineBanner(),
      Expanded(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(
            title: 'Products',
            subtitle: '${dp.products.length} items in inventory',
            action: ElevatedButton.icon(
              onPressed: () {
                if (_showForm && _editingId == null) {
                  setState(() { _showForm = false; _clearForm(); });
                } else {
                  _clearForm();
                  setState(() => _showForm = true);
                }
              },
              icon: Icon(_showForm && _editingId == null ? Icons.close : Icons.add, size: 15),
              label: Text(_showForm && _editingId == null ? 'Cancel' : 'Add Product'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
            ),
          ),
          const SizedBox(height: 16),

          if (_showForm) ...[
            AppCard(padding: const EdgeInsets.all(18), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_editingId != null ? 'Edit Product' : 'New Product',
                      style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  if (_editingId != null)
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                      onPressed: () => setState(() { _showForm = false; _clearForm(); }),
                    ),
                ]),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  _ErrorBanner(_error!),
                ],
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: AppTextField(
                    label: 'Product Code *', hint: 'e.g. PRD-001',
                    controller: _codeCtrl,
                    textCapitalization: TextCapitalization.characters,
                  )),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _openScanner,
                    child: Container(
                      height: 48, width: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.qr_code_scanner,
                          color: AppColors.primary, size: 22),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                AppTextField(label: 'Product Name *', hint: 'e.g. Coca Cola 1.5L',
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: AppTextField(label: 'Cost Price *', hint: '0.00',
                      controller: _costCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: AppTextField(label: 'Retail Price *', hint: '0.00',
                      controller: _retailCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: AppTextField(label: 'Stock', hint: '0',
                      controller: _stockCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: AppTextField(label: 'Low-Stock Alert', hint: '5',
                      controller: _threshCtrl, keyboardType: TextInputType.number)),
                  const SizedBox(width: 10),
                  Expanded(child: AppTextField(label: 'Category', hint: 'e.g. Drinks',
                      controller: _categoryCtrl,
                      textCapitalization: TextCapitalization.words)),
                ]),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _editingId != null ? 'Save Changes' : 'Add Product',
                  icon: _editingId != null ? Icons.save : Icons.add,
                  loading: _saving,
                  onPressed: _submit,
                ),
              ],
            )),
            const SizedBox(height: 14),
          ],

          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.dmSans(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search by name, code, or category…',
              hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
                      onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); })
                  : null,
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
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            const EmptyState(icon: Icons.inventory_2, message: 'No products found')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisSpacing: 12, crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _ProductCard(
                product: filtered[i],
                onEdit: () => _startEdit(filtered[i]),
                onDelete: () => _deleteProduct(filtered[i]),
              ),
            ),
        ],
      )),
    ]);
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); _codeCtrl.dispose(); _nameCtrl.dispose();
    _costCtrl.dispose(); _retailCtrl.dispose(); _stockCtrl.dispose();
    _threshCtrl.dispose(); _categoryCtrl.dispose();
    super.dispose();
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ProductCard({required this.product, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p      = product;
    final isOut  = p.stock == 0;
    final isLow  = !isOut && p.stock <= p.lowStockThreshold;
    final border = isOut ? AppColors.red.withOpacity(0.4)
        : isLow  ? AppColors.yellow.withOpacity(0.3)
        : AppColors.border;
    final stockColor = isOut ? AppColors.red : isLow ? AppColors.yellow : AppColors.green;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                    fontSize: 13, fontWeight: FontWeight.w700),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            Text('${p.productCode}${p.category.isNotEmpty ? ' · ${p.category}' : ''}',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          Row(children: [
            _SmBtn(Icons.edit, AppColors.primary, onEdit),
            const SizedBox(width: 4),
            _SmBtn(Icons.delete_outline, AppColors.red, onDelete),
          ]),
        ]),
        const Spacer(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RETAIL', style: GoogleFonts.dmSans(color: AppColors.textMuted,
                fontSize: 9, letterSpacing: 0.5)),
            Text('₱${p.retailPrice.toStringAsFixed(2)}',
                style: GoogleFonts.dmSans(color: AppColors.green,
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('COST', style: GoogleFonts.dmSans(color: AppColors.textMuted,
                fontSize: 9, letterSpacing: 0.5)),
            Text('₱${p.costPrice.toStringAsFixed(2)}',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary,
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('${p.stock}',
                style: GoogleFonts.dmSans(
                    color: stockColor, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}

class _SmBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _SmBtn(this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
      child: Icon(icon, color: color, size: 13),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.red.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline, color: AppColors.red, size: 15),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: GoogleFonts.dmSans(color: AppColors.red, fontSize: 12))),
    ]),
  );
}

class BarcodeScanPage extends StatefulWidget {
  const BarcodeScanPage({super.key});
  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage> {
  late final MobileScannerController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController(detectionSpeed: DetectionSpeed.normal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('Scan Barcode',
            style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _ctrl,
          onDetect: (capture) {
            if (_done) return;
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null && code.isNotEmpty) {
              _done = true;
              Navigator.of(context).pop(code);
            }
          },
        ),
        Center(child: Container(
          width: 260, height: 180,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        )),
        ..._buildCornerOverlays(),
        Positioned(bottom: 40, left: 0, right: 0,
          child: Text('Point camera at a barcode or QR code',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13))),
      ]),
    );
  }

  List<Widget> _buildCornerOverlays() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final centerY = screenHeight / 2;
    final centerX = screenWidth / 2;
    final topY = centerY - 90;
    final bottomY = centerY + 90;
    final leftX = centerX - 130;
    final rightX = centerX + 130;
    
    return [
      // Top-left corner
      Positioned(
        top: topY,
        left: leftX,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: AppColors.primary, width: 3),
              left: const BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
      // Top-right corner
      Positioned(
        top: topY,
        right: screenWidth - rightX,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            border: Border(
              top: const BorderSide(color: AppColors.primary, width: 3),
              right: const BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
      // Bottom-left corner
      Positioned(
        bottom: screenHeight - bottomY,
        left: leftX,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: AppColors.primary, width: 3),
              left: const BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
      // Bottom-right corner
      Positioned(
        bottom: screenHeight - bottomY,
        right: screenWidth - rightX,
        child: Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: AppColors.primary, width: 3),
              right: const BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
