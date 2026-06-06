// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/data_provider.dart';
import '../utils/theme.dart';
import 'dashboard_screen.dart';
import 'products_screen.dart';
import 'new_purchase_screen.dart';
import 'customers_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  static const _screens = <Widget>[
    DashboardScreen(),
    ProductsScreen(),
    NewPurchaseScreen(),
    CustomersScreen(),
    SettingsScreen(),
  ];

  static const _tabs = [
    _TabInfo(label: 'Dashboard', icon: Icons.dashboard_rounded),
    _TabInfo(label: 'Products',  icon: Icons.inventory_2_rounded),
    _TabInfo(label: 'New Sale',  icon: Icons.shopping_cart_rounded),
    _TabInfo(label: 'Customers', icon: Icons.people_rounded),
    _TabInfo(label: 'Settings',  icon: Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final dp   = context.watch<DataProvider>();
    final now  = DateTime.now();
    final date = '${_wd(now.weekday)} ${_mo(now.month)} ${now.day}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xF21A1A2E),
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(children: [
          // Logo mark
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.green],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 10),
          Text('Marnie Store', style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          _StatusPill(online: dp.isOnline),
        ]),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Text(date, style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 11)),
          )),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(42),
          child: Container(
            color: const Color(0xF01E1E38),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final active = _idx == i;
                  return GestureDetector(
                    onTap: () => setState(() => _idx = i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(
                          color: active ? AppColors.primary : Colors.transparent,
                          width: 2,
                        )),
                      ),
                      child: Row(children: [
                        Icon(_tabs[i].icon, size: 13,
                            color: active ? AppColors.primary : AppColors.textMuted),
                        const SizedBox(width: 6),
                        Text(_tabs[i].label, style: GoogleFonts.dmSans(
                            color: active ? AppColors.primary : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(index: _idx, children: _screens),
      bottomNavigationBar: MediaQuery.of(context).size.width < 600
          ? _BottomNav(idx: _idx, tabs: _tabs, onTap: (i) => setState(() => _idx = i))
          : null,
    );
  }

  String _wd(int d) => const ['','Mon','Tue','Wed','Thu','Fri','Sat','Sun'][d];
  String _mo(int m) => const ['','Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'][m];
}

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo({required this.label, required this.icon});
}

class _StatusPill extends StatelessWidget {
  final bool online;
  const _StatusPill({required this.online});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: (online ? AppColors.green : AppColors.yellow).withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.circle, color: online ? AppColors.green : AppColors.yellow, size: 7),
      const SizedBox(width: 4),
      Text(online ? 'LIVE' : 'OFFLINE', style: GoogleFonts.dmSans(
          color: online ? AppColors.green : AppColors.yellow,
          fontSize: 9, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _BottomNav extends StatelessWidget {
  final int idx;
  final List<_TabInfo> tabs;
  final void Function(int) onTap;
  const _BottomNav({required this.idx, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF5121220),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = idx == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(tabs[i].icon,
                        size: active ? 22 : 20,
                        color: active ? AppColors.primary : AppColors.textMuted),
                    const SizedBox(height: 3),
                    Text(tabs[i].label.split(' ').first, style: GoogleFonts.dmSans(
                        color: active ? AppColors.primary : AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                    if (active) ...[
                      const SizedBox(height: 3),
                      Container(width: 4, height: 4,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle)),
                    ],
                  ]),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
