// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/data_provider.dart';
import '../utils/theme.dart';
import '../widgets/app_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dp        = context.watch<DataProvider>();
    final products  = dp.products;
    final customers = dp.customers;
    final purchases = dp.purchases;
    final now       = DateTime.now();

    final todayPurchases = purchases.where((p) {
      try {
        final d = DateTime.parse(p.purchaseDate);
        return d.year == now.year && d.month == now.month && d.day == now.day;
      } catch (_) { return false; }
    }).toList();

    final totalRevenue = purchases.fold(0.0, (s, p) => s + p.totalAmount);
    final todayRevenue = todayPurchases.fold(0.0, (s, p) => s + p.totalAmount);
    final pendingCount = purchases.where((p) => p.status != 'paid').length;
    final lowStock     = products.where((p) => p.stock <= p.lowStockThreshold).toList();
    final fmt          = NumberFormat('#,##0.00', 'en_PH');
    final dateFmt      = DateFormat('EEEE, MMM d, y');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Dashboard', style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
            Text(dateFmt.format(now), style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 12)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (dp.isOnline ? AppColors.green : AppColors.yellow).withOpacity(0.13),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Icon(Icons.circle,
                  color: dp.isOnline ? AppColors.green : AppColors.yellow, size: 8),
              const SizedBox(width: 5),
              Text(dp.isOnline ? 'LIVE' : 'OFFLINE',
                  style: GoogleFonts.dmSans(
                      color: dp.isOnline ? AppColors.green : AppColors.yellow,
                      fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 18),

        // Stats grid
        GridView.count(
          crossAxisCount: 2, shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            StatCard(label: "Today's Sales",
                value: '₱${fmt.format(todayRevenue)}',
                icon: Icons.today, color: AppColors.primary,
                subtext: '${todayPurchases.length} transactions'),
            StatCard(label: 'Total Revenue',
                value: '₱${fmt.format(totalRevenue)}',
                icon: Icons.trending_up, color: AppColors.green,
                subtext: '${purchases.length} total orders'),
            StatCard(label: 'Customers',
                value: '${customers.length}',
                icon: Icons.people, color: AppColors.cyan,
                subtext: 'registered'),
            StatCard(label: 'Products',
                value: '${products.length}',
                icon: Icons.inventory_2, color: AppColors.yellow,
                subtext: '${lowStock.length} low stock'),
          ],
        ),
        const SizedBox(height: 16),

        // Alert banners
        if (pendingCount > 0 || lowStock.isNotEmpty) ...[
          Row(children: [
            if (pendingCount > 0)
              Expanded(child: _AlertTile(
                icon: Icons.access_time,
                color: AppColors.yellow,
                title: '$pendingCount Pending',
                sub: 'unpaid orders',
              )),
            if (pendingCount > 0 && lowStock.isNotEmpty)
              const SizedBox(width: 10),
            if (lowStock.isNotEmpty)
              Expanded(child: _AlertTile(
                icon: Icons.warning_amber,
                color: AppColors.red,
                title: '${lowStock.length} Low Stock',
                sub: 'need restocking',
              )),
          ]),
          const SizedBox(height: 16),
        ],

        // Recent transactions
        AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Recent Transactions', style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            Text('${purchases.length} total', style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 11)),
          ]),
          const SizedBox(height: 12),
          if (purchases.isEmpty)
            const EmptyState(icon: Icons.receipt_long, message: 'No transactions yet')
          else
            ...purchases.take(8).map((p) => _TxRow(
              purchase: p,
              customer: customers.where((c) => c.id == p.customerId).firstOrNull,
            )),
        ])),
        const SizedBox(height: 16),

        // Low-stock list
        if (lowStock.isNotEmpty)
          AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Low Stock Items', style: GoogleFonts.dmSans(
                color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...lowStock.take(10).map((p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Text(p.name, style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 13),
                    overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (p.stock == 0 ? AppColors.red : AppColors.yellow).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${p.stock} left', style: GoogleFonts.dmSans(
                      color: p.stock == 0 ? AppColors.red : AppColors.yellow,
                      fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
            )),
          ])),
      ]),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub;
  const _AlertTile({required this.icon, required this.color,
      required this.title, required this.sub});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: GoogleFonts.dmSans(
            color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        Text(sub, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 10)),
      ]),
    ]),
  );
}

class _TxRow extends StatelessWidget {
  final Purchase purchase;
  final Customer? customer;
  const _TxRow({required this.purchase, this.customer});
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d');
    DateTime? date;
    try { date = DateTime.parse(purchase.purchaseDate); } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
          child: const Icon(Icons.person, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(customer?.name ?? purchase.customerName,
              style: GoogleFonts.dmSans(color: AppColors.textPrimary,
                  fontSize: 13, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          if (date != null)
            Text(fmt.format(date), style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 11)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('₱${purchase.totalAmount.toStringAsFixed(2)}',
              style: GoogleFonts.dmSans(color: AppColors.green,
                  fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          StatusBadge(purchase.status),
        ]),
      ]),
    );
  }
}
