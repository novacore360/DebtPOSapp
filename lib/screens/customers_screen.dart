// lib/screens/customers_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/data_provider.dart';
import '../utils/theme.dart';
import '../widgets/app_widgets.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl    = TextEditingController();
  final _editNameCtrl  = TextEditingController();
  final _editPhoneCtrl = TextEditingController();
  final _editEmailCtrl = TextEditingController();

  String  _search     = '';
  String? _expandedId;
  bool    _editMode   = false;

  void _startEdit(Customer c) {
    _editNameCtrl.text  = c.name;
    _editPhoneCtrl.text = c.phone;
    _editEmailCtrl.text = c.email;
    setState(() => _editMode = true);
  }

  Future<void> _saveEdit() async {
    await context.read<DataProvider>().updateCustomer(_expandedId!, {
      'name':  _editNameCtrl.text.trim(),
      'phone': _editPhoneCtrl.text.trim(),
      'email': _editEmailCtrl.text.trim(),
    });
    setState(() => _editMode = false);
    if (mounted) showToast(context, 'Customer updated');
  }

  Future<void> _deleteCustomer(Customer c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete Customer',
        message: 'Delete "${c.name}" and all their purchases?',
      ),
    );
    if (ok == true && mounted) {
      await context.read<DataProvider>().deleteCustomer(c.id);
      setState(() { _expandedId = null; _editMode = false; });
      showToast(context, 'Customer deleted');
    }
  }

  Future<void> _togglePaid(Purchase p) async {
    final newStatus = p.status == 'paid' ? 'pending' : 'paid';
    await context.read<DataProvider>().updatePurchase(p.id, {'status': newStatus});
  }

  Future<void> _deletePurchase(Purchase p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete Purchase',
        message: 'Delete purchase of ₱${p.totalAmount.toStringAsFixed(2)}?',
      ),
    );
    if (ok == true && mounted) {
      await context.read<DataProvider>().deletePurchase(p.id);
      showToast(context, 'Purchase deleted');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final q  = _search.toLowerCase();
    final filtered = dp.customers
        .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList();

    return Column(children: [
      if (!dp.isOnline) const OfflineBanner(),
      Expanded(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionHeader(
            title: 'Customers',
            subtitle: '${dp.customers.length} registered customers',
          ),
          const SizedBox(height: 14),

          // Search
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.dmSans(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search name or phone…',
              hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted, size: 18),
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
            const EmptyState(icon: Icons.people, message: 'No customers found')
          else
            ...filtered.map((c) {
              final custPurchases = dp.purchases
                  .where((p) => p.customerId == c.id).toList();
              final spent  = custPurchases.fold(0.0, (s, p) => s + p.totalAmount);
              final isOpen = _expandedId == c.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CustomerTile(
                  customer: c,
                  purchases: custPurchases,
                  totalSpent: spent,
                  isOpen: isOpen,
                  editMode: isOpen ? _editMode : false,
                  editNameCtrl: _editNameCtrl,
                  editPhoneCtrl: _editPhoneCtrl,
                  editEmailCtrl: _editEmailCtrl,
                  onToggle: () => setState(() {
                    _expandedId = isOpen ? null : c.id;
                    _editMode = false;
                  }),
                  onEdit: () => _startEdit(c),
                  onSaveEdit: _saveEdit,
                  onCancelEdit: () => setState(() => _editMode = false),
                  onDelete: () => _deleteCustomer(c),
                  onTogglePaid: _togglePaid,
                  onDeletePurchase: _deletePurchase,
                ),
              );
            }),
        ],
      )),
    ]);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _editNameCtrl.dispose(); _editPhoneCtrl.dispose(); _editEmailCtrl.dispose();
    super.dispose();
  }
}

// ─── Customer tile ────────────────────────────────────────────────────────────
class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final List<Purchase> purchases;
  final double totalSpent;
  final bool isOpen, editMode;
  final TextEditingController editNameCtrl, editPhoneCtrl, editEmailCtrl;
  final VoidCallback onToggle, onEdit, onSaveEdit, onCancelEdit, onDelete;
  final Future<void> Function(Purchase) onTogglePaid;
  final Future<void> Function(Purchase) onDeletePurchase;

  const _CustomerTile({
    required this.customer, required this.purchases, required this.totalSpent,
    required this.isOpen, required this.editMode,
    required this.editNameCtrl, required this.editPhoneCtrl, required this.editEmailCtrl,
    required this.onToggle, required this.onEdit, required this.onSaveEdit,
    required this.onCancelEdit, required this.onDelete,
    required this.onTogglePaid, required this.onDeletePurchase,
  });

  @override
  Widget build(BuildContext context) {
    final c = customer;
    return AppCard(
      padding: EdgeInsets.zero, borderRadius: 14,
      child: Column(children: [
        // Header row
        InkWell(
          borderRadius: isOpen
              ? const BorderRadius.vertical(top: Radius.circular(14))
              : BorderRadius.circular(14),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Avatar
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [
                    AppColors.primary.withOpacity(0.3),
                    AppColors.green.withOpacity(0.3),
                  ]),
                ),
                child: Center(child: Text(
                  c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                  style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                      fontSize: 16, fontWeight: FontWeight.w800),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 14,
                    fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text(c.phone.isNotEmpty ? c.phone
                    : c.email.isNotEmpty ? c.email : 'No contact',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₱${totalSpent.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(color: AppColors.green,
                        fontSize: 13, fontWeight: FontWeight.w700)),
                Text('${purchases.length} orders',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11)),
              ]),
              const SizedBox(width: 8),
              Icon(isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted, size: 18),
            ]),
          ),
        ),

        // Expanded
        if (isOpen) ...[
          const Divider(color: AppColors.border, height: 1),
          Padding(padding: const EdgeInsets.all(14),
            child: editMode
                ? _EditForm(
                    nameCtrl: editNameCtrl,
                    phoneCtrl: editPhoneCtrl,
                    emailCtrl: editEmailCtrl,
                    onSave: onSaveEdit,
                    onCancel: onCancelEdit)
                : _Detail(
                    customer: c,
                    purchases: purchases,
                    totalSpent: totalSpent,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onTogglePaid: onTogglePaid,
                    onDeletePurchase: onDeletePurchase),
          ),
        ],
      ]),
    );
  }
}

// ─── Detail panel ─────────────────────────────────────────────────────────────
class _Detail extends StatelessWidget {
  final Customer customer;
  final List<Purchase> purchases;
  final double totalSpent;
  final VoidCallback onEdit, onDelete;
  final Future<void> Function(Purchase) onTogglePaid;
  final Future<void> Function(Purchase) onDeletePurchase;

  const _Detail({
    required this.customer, required this.purchases, required this.totalSpent,
    required this.onEdit, required this.onDelete,
    required this.onTogglePaid, required this.onDeletePurchase,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, y  HH:mm');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _ActBtn('Edit', Icons.edit, AppColors.primary, onEdit),
        const SizedBox(width: 8),
        _ActBtn('Delete', Icons.delete_outline, AppColors.red, onDelete),
      ]),
      const SizedBox(height: 14),
      Text('PURCHASE HISTORY', style: GoogleFonts.dmSans(
          color: AppColors.textSecondary, fontSize: 10,
          fontWeight: FontWeight.w600, letterSpacing: 0.8)),
      const SizedBox(height: 8),
      if (purchases.isEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(child: Text('No purchases yet.',
              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13)))),
      ...purchases.map((p) {
        DateTime? date;
        try { date = DateTime.parse(p.purchaseDate); } catch (_) {}
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0x08FFFFFF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (date != null)
                  Text(fmt.format(date), style: GoogleFonts.dmSans(
                      color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 3),
                Text(
                  p.productData.isNotEmpty
                      ? p.productData.map((i) => '${i.name} ×${i.quantity}').join(', ')
                      : 'No items',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 3, overflow: TextOverflow.ellipsis,
                ),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₱${p.totalAmount.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(color: AppColors.green,
                        fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                StatusBadge(p.status),
              ]),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _PillBtn(
                label: p.status == 'paid' ? 'Mark Pending' : 'Mark Paid',
                color: p.status == 'paid' ? AppColors.yellow : AppColors.green,
                onTap: () => onTogglePaid(p),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => onDeletePurchase(p),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(Icons.delete_outline, color: AppColors.red, size: 14),
                ),
              ),
            ]),
          ]),
        );
      }),
      if (purchases.isNotEmpty) ...[
        const Divider(color: AppColors.border, height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Total Spent', style: GoogleFonts.dmSans(
              color: AppColors.textSecondary, fontSize: 13)),
          Text('₱${totalSpent.toStringAsFixed(2)}',
              style: GoogleFonts.dmSans(color: AppColors.green,
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
      ],
    ]);
  }
}

class _ActBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActBtn(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.dmSans(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _PillBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PillBtn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: GoogleFonts.dmSans(
          color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    ),
  );
}

// ─── Edit form ────────────────────────────────────────────────────────────────
class _EditForm extends StatelessWidget {
  final TextEditingController nameCtrl, phoneCtrl, emailCtrl;
  final VoidCallback onSave, onCancel;
  const _EditForm({required this.nameCtrl, required this.phoneCtrl,
      required this.emailCtrl, required this.onSave, required this.onCancel});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text('Edit Customer', style: GoogleFonts.dmSans(
        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
    const SizedBox(height: 12),
    AppTextField(label: 'Name', controller: nameCtrl,
        textCapitalization: TextCapitalization.words),
    const SizedBox(height: 10),
    Row(children: [
      Expanded(child: AppTextField(label: 'Phone', controller: phoneCtrl,
          keyboardType: TextInputType.phone)),
      const SizedBox(width: 10),
      Expanded(child: AppTextField(label: 'Email', controller: emailCtrl,
          keyboardType: TextInputType.emailAddress)),
    ]),
    const SizedBox(height: 14),
    Row(children: [
      Expanded(child: ElevatedButton(onPressed: onSave, child: const Text('Save'))),
      const SizedBox(width: 10),
      OutlinedButton(onPressed: onCancel, child: const Text('Cancel')),
    ]),
  ]);
}
