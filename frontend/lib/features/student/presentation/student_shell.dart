import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/state/auth_controller.dart';
import 'student_home_screen.dart';
import 'student_booking_screen.dart';
import 'student_my_bookings_screen.dart';
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
        onNavigateToNotifications: () => setState(() => _currentIndex = 4),
      ),
      StudentBookingScreen(
        onNavigateToHome: () => setState(() => _currentIndex = 0),
        onNavigateToBookings: () => setState(() => _currentIndex = 2),
      ),
      StudentMyBookingsScreen(
        onNavigateToBooking: () => setState(() => _currentIndex = 1),
      ),
      const StudentExpensesScreen(),
      const StudentNotificationsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hostel Dining',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  'Good food. Better days.',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Sign Out',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primarySubtle,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppColors.primaryDark),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_add_outlined),
              selectedIcon: Icon(Icons.bookmark_added_rounded, color: AppColors.primaryDark),
              label: 'Book',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note_rounded, color: AppColors.primaryDark),
              label: 'My Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded, color: AppColors.primaryDark),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.notifications_none_rounded),
              selectedIcon: Icon(Icons.notifications_active_rounded, color: AppColors.primaryDark),
              label: 'Reminders',
            ),
          ],
        ),
      ),
    );
  }
}
