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
import 'admin_audit_screen.dart';

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
      const AdminAuditScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                // Deep Forest Green Desktop Sidebar matching Reference 1 (Image 9) & Reference 3 (Image 6)
                Container(
                  width: 240,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                  ),
                  child: Column(
                    children: [
                      // Sidebar Brand Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hostel Dining',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Admin Operations',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white60,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      const SizedBox(height: 12),

                      // Navigation Items
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          children: [
                            _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded),
                            _buildNavItem(1, 'Menus', Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded),
                            _buildNavItem(2, 'Meal Prices', Icons.sell_outlined, Icons.sell_rounded),
                            _buildNavItem(3, 'Students', Icons.people_outline_rounded, Icons.people_alt_rounded),
                            _buildNavItem(4, 'Bookings', Icons.bookmark_border_rounded, Icons.bookmark_rounded),
                            _buildNavItem(5, 'Consumption', Icons.fact_check_outlined, Icons.fact_check_rounded),
                            _buildNavItem(6, 'Reports & Analytics', Icons.bar_chart_rounded, Icons.bar_chart_rounded),
                            _buildNavItem(7, 'Security & Audit', Icons.security_outlined, Icons.security_rounded),
                          ],
                        ),
                      ),

                      // Admin Profile & Logout Footer
                      const Divider(color: Colors.white12, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withOpacity(0.15),
                              radius: 18,
                              child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.fullName ?? 'Admin',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Manager', style: TextStyle(color: Colors.white60, fontSize: 10)),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Sign Out',
                              icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 18),
                              onPressed: () async {
                                await ref.read(authProvider.notifier).logout();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Workspace
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile Layout with Drawer and Quick Bottom Nav
        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Hostel Dining Admin'),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Security Audit Logs',
                icon: Icon(
                  _currentIndex == 7 ? Icons.security_rounded : Icons.security_outlined,
                  color: _currentIndex == 7 ? AppColors.accentWarm : AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _currentIndex = 7),
              ),
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
          drawer: Drawer(
            backgroundColor: AppColors.primaryDark,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hostel Dining',
                              style: AppTypography.titleLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Admin Navigation',
                              style: AppTypography.labelSmall.copyWith(
                                color: Colors.white60,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      children: [
                        _buildNavItem(0, 'Dashboard', Icons.dashboard_outlined, Icons.dashboard_rounded, closeDrawer: true),
                        _buildNavItem(1, 'Menus', Icons.restaurant_menu_outlined, Icons.restaurant_menu_rounded, closeDrawer: true),
                        _buildNavItem(2, 'Meal Prices', Icons.sell_outlined, Icons.sell_rounded, closeDrawer: true),
                        _buildNavItem(3, 'Students', Icons.people_outline_rounded, Icons.people_alt_rounded, closeDrawer: true),
                        _buildNavItem(4, 'Bookings', Icons.bookmark_border_rounded, Icons.bookmark_rounded, closeDrawer: true),
                        _buildNavItem(5, 'Consumption', Icons.fact_check_outlined, Icons.fact_check_rounded, closeDrawer: true),
                        _buildNavItem(6, 'Reports & Analytics', Icons.bar_chart_rounded, Icons.bar_chart_rounded, closeDrawer: true),
                        _buildNavItem(7, 'Security & Audit Logs', Icons.security_outlined, Icons.security_rounded, closeDrawer: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex > 4 ? 0 : _currentIndex,
            onDestinationSelected: (idx) {
              if (idx == 4) {
                // Open drawer or jump to more
                Scaffold.of(context).openDrawer();
              } else {
                setState(() => _currentIndex = idx);
              }
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu_rounded), label: 'Menus'),
              NavigationDestination(icon: Icon(Icons.sell_outlined), selectedIcon: Icon(Icons.sell_rounded), label: 'Prices'),
              NavigationDestination(icon: Icon(Icons.bookmark_border_rounded), selectedIcon: Icon(Icons.bookmark_rounded), label: 'Bookings'),
              NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: Icon(Icons.more_horiz_rounded), label: 'More'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon, IconData activeIcon, {bool closeDrawer = false}) {
    final isSelected = _currentIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        onTap: () {
          setState(() => _currentIndex = index);
          if (closeDrawer && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
