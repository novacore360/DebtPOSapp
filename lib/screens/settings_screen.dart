// lib/screens/settings_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/data_provider.dart';
import '../utils/theme.dart';
import '../widgets/app_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _exportData(BuildContext context, DataProvider dp) async {
    try {
      final data = {
        'exportedAt': DateTime.now().toIso8601String(),
        'products': dp.products.map((p) => {...p.toFirestore(), 'id': p.id}).toList(),
        'customers': dp.customers.map((c) => {...c.toFirestore(), 'id': c.id}).toList(),
        'purchases': dp.purchases.map((p) => {...p.toFirestore(), 'id': p.id}).toList(),
      };
      final json = const JsonEncoder.withIndent('  ').convert(data);
      final bytes = utf8.encode(json);
      final date  = DateTime.now().toIso8601String().substring(0, 10);
      await Share.shareXFiles([
        XFile.fromData(bytes,
            mimeType: 'application/json',
            name: 'marnie_pos_$date.json'),
      ], subject: 'Marnie POS Export $date');
    } catch (e) {
      if (context.mounted) {
        showToast(context, 'Export failed: $e', error: true);
      }
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Sign Out',
        message: 'Are you sure you want to sign out?',
        confirmLabel: 'Sign Out',
        confirmColor: AppColors.red,
      ),
    );
    if (ok == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final dp   = context.watch<DataProvider>();
    final user = FirebaseAuth.instance.currentUser;

    final totalRevenue  = dp.purchases.fold(0.0, (s, p) => s + p.totalAmount);
    final paidRevenue   = dp.purchases
        .where((p) => p.status == 'paid')
        .fold(0.0, (s, p) => s + p.totalAmount);
    final pendingCount  = dp.purchases.where((p) => p.status != 'paid').length;
    final totalProfit   = dp.purchases.fold(0.0, (sum, p) {
      return sum + p.productData.fold(0.0, (s, item) {
        final prod = dp.products.where((pr) => pr.id == item.productId).firstOrNull;
        return s + (item.subtotal - (prod?.costPrice ?? 0) * item.quantity);
      });
    });
    final margin = totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0.0;
    final totalStock    = dp.products.fold(0, (s, p) => s + p.stock);
    final outOfStock    = dp.products.where((p) => p.stock == 0).length;
    final lowStockCount = dp.products.where((p) => p.stock <= p.lowStockThreshold).length;
    final categories    = dp.products.map((p) => p.category)
        .toSet().where((c) => c.isNotEmpty).length;

    return Column(children: [
      if (!dp.isOnline) const OfflineBanner(),
      Expanded(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'Settings'),
          const SizedBox(height: 16),

          // ── Account ──
          AppCard(padding: const EdgeInsets.all(18), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecTitle(icon: Icons.person_outline, title: 'Account & System'),
              const SizedBox(height: 12),
              _InfoRow('System',         'Marnie Store POS v2.1'),
              _InfoRow('Database',       'Firebase Firestore'),
              _InfoRow('Offline store',  'SQLite (sqflite)'),
              _InfoRow('Logged in as',   user?.email ?? 'Unknown',
                  color: AppColors.primary),
              _InfoRow('Connection',
                  dp.isOnline ? '● Connected' : '○ Offline',
                  color: dp.isOnline ? AppColors.green : AppColors.yellow),
              if (!dp.isOnline) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.yellow.withOpacity(0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: AppColors.yellow, size: 14),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Working offline. All changes are saved locally and will sync automatically when reconnected.',
                      style: GoogleFonts.dmSans(color: AppColors.yellow, fontSize: 11, height: 1.4),
                    )),
                  ]),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout, size: 15, color: AppColors.red),
                  label: Text('Sign Out', style: GoogleFonts.dmSans(
                      color: AppColors.red, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.red.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          )),
          const SizedBox(height: 14),

          // ── Data Management ──
          AppCard(padding: const EdgeInsets.all(18), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecTitle(icon: Icons.storage, title: 'Data Management'),
              const SizedBox(height: 10),
              Text('Export all your data as JSON for backup or migration.',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportData(context, dp),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export JSON Backup'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          )),
          const SizedBox(height: 14),

          // ── Financial Summary ──
          AppCard(padding: const EdgeInsets.all(18), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecTitle(icon: Icons.trending_up, title: 'Financial Summary',
                  iconColor: AppColors.green),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10, crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [
                  _SumTile('Total Revenue', '₱${totalRevenue.toStringAsFixed(2)}', AppColors.primary),
                  _SumTile('Paid Revenue',  '₱${paidRevenue.toStringAsFixed(2)}',  AppColors.green),
                  _SumTile('Total Profit',  '₱${totalProfit.toStringAsFixed(2)}',  AppColors.green),
                  _SumTile('Margin',        '${margin.toStringAsFixed(1)}%',        AppColors.yellow),
                  _SumTile('Total Orders',  '${dp.purchases.length}',              AppColors.cyan),
                  _SumTile('Pending',       '$pendingCount',                        AppColors.yellow),
                ],
              ),
            ],
          )),
          const SizedBox(height: 14),

          // ── Inventory ──
          AppCard(padding: const EdgeInsets.all(18), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecTitle(icon: Icons.inventory_2, title: 'Inventory'),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 3, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10, crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [
                  _SumTile('Products',   '${dp.products.length}',  AppColors.primary),
                  _SumTile('Customers',  '${dp.customers.length}', AppColors.cyan),
                  _SumTile('Low Stock',  '$lowStockCount',         AppColors.yellow),
                  _SumTile('Out of Stock','$outOfStock',           AppColors.red),
                  _SumTile('Total Units','$totalStock',            AppColors.green),
                  _SumTile('Categories', '$categories',            AppColors.cyan),
                ],
              ),
            ],
          )),
          const SizedBox(height: 20),

          Center(child: Text('Marnie Store POS v2.1 · Flutter',
              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 11))),
        ],
      )),
    ]);
  }
}

class _SecTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  const _SecTitle({required this.icon, required this.title,
      this.iconColor = AppColors.primary});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: iconColor, size: 16),
    const SizedBox(width: 8),
    Text(title, style: GoogleFonts.dmSans(
        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _InfoRow(this.label, this.value, {this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border))),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.dmSans(
          color: AppColors.textSecondary, fontSize: 13)),
      Flexible(child: Text(value,
          style: GoogleFonts.dmSans(
              color: color ?? AppColors.textPrimary,
              fontSize: 13, fontWeight: FontWeight.w500),
          textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class _SumTile extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SumTile(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0x08FFFFFF),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: GoogleFonts.dmSans(
          color: color, fontSize: 16, fontWeight: FontWeight.w800),
          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 3),
      Text(label, style: GoogleFonts.dmSans(
          color: AppColors.textMuted, fontSize: 9, letterSpacing: 0.3),
          textAlign: TextAlign.center, maxLines: 2),
    ]),
  );
}
