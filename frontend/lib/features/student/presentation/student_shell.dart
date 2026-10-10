import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/state/auth_controller.dart';
import 'student_home_screen.dart';
import 'student_booking_screen.dart';
import 'student_expenses_screen.dart';
import 'student_notifications_screen.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});

  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      StudentHomeScreen(
        onNavigateToBooking: () => setState(() => _currentIndex = 1),
      ),
      const StudentBookingScreen(),
      const StudentExpensesScreen(),
      const StudentNotificationsScreen(),
    ];

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
              child: const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Hostel Dining'),
          ],
        ),
        actions: [
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
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu_rounded),
            label: "Today's Menu",
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_add_outlined),
            selectedIcon: Icon(Icons.bookmark_added_rounded),
            label: 'Book Tomorrow',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'My Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none_rounded),
            selectedIcon: Icon(Icons.notifications_active_rounded),
            label: 'Reminders',
          ),
        ],
      ),
    );
  }
}
