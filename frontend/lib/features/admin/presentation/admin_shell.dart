import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/state/auth_controller.dart';
import 'admin_dashboard_screen.dart';
import 'admin_menus_screen.dart';
import 'admin_prices_screen.dart';
import 'admin_students_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_consumption_screen.dart';
import 'admin_reports_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final screens = [
      AdminDashboardScreen(onNavigateTab: (idx) => setState(() => _currentIndex = idx)),
      const AdminMenusScreen(),
      const AdminPricesScreen(),
      const AdminStudentsScreen(),
      const AdminBookingsScreen(),
      const AdminConsumptionScreen(),
      const AdminReportsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 850;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Hostel Operations Admin'),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('PHASE 1 MVP', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            actions: [
              Text(
                user?.fullName ?? 'Administrator',
                style: AppTypography.titleMedium.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: isWide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: AppColors.surface,
                      indicatorColor: AppColors.primarySubtle,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.primary,
                              radius: 18,
                              child: Icon(Icons.shield_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(height: 4),
                            Text('Admin', style: AppTypography.labelSmall),
                          ],
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                        NavigationRailDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: Text('Menus')),
                        NavigationRailDestination(icon: Icon(Icons.currency_rupee_rounded), selectedIcon: Icon(Icons.sell_rounded), label: Text('Prices')),
                        NavigationRailDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: Text('Students')),
                        NavigationRailDestination(icon: Icon(Icons.bookmark_border_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: Text('Bookings')),
                        NavigationRailDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check_rounded), label: Text('Consumption')),
                        NavigationRailDestination(icon: Icon(Icons.print_outlined), selectedIcon: Icon(Icons.print_rounded), label: Text('Reports')),
                      ],
                    ),
                    const VerticalDivider(width: 1, thickness: 1, color: AppColors.cardBorder),
                    Expanded(
                      child: IndexedStack(
                        index: _currentIndex,
                        children: screens,
                      ),
                    ),
                  ],
                )
              : IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
                  destinations: const [
                    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
                    NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Menus'),
                    NavigationDestination(icon: Icon(Icons.sell_outlined), selectedIcon: Icon(Icons.sell_rounded), label: 'Prices'),
                    NavigationDestination(icon: Icon(Icons.people_outline_rounded), selectedIcon: Icon(Icons.people_rounded), label: 'Students'),
                    NavigationDestination(icon: Icon(Icons.bookmark_border_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: 'Bookings'),
                    NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check_rounded), label: 'Consumption'),
                    NavigationDestination(icon: Icon(Icons.print_outlined), selectedIcon: Icon(Icons.print_rounded), label: 'Reports'),
                  ],
                ),
        );
      },
    );
  }
}
