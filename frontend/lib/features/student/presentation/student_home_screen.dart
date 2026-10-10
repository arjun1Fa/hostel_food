import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/state/auth_controller.dart';
import '../state/student_controllers.dart';
import '../models/menu_model.dart';

class StudentHomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToBooking;

  const StudentHomeScreen({
    super.key,
    required this.onNavigateToBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final menuState = ref.watch(studentMenuProvider);
    final user = authState.user;

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(studentMenuProvider.notifier).loadMenus(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Personalized Student Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${user?.fullName ?? "Student"}! 👋',
                          style: AppTypography.displayMedium.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heritage Hostel • Room ${user?.roomNumber ?? "Assigned"}',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Hero Food Banner
              Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/hostel_food_hero.jpg',
                        fit: BoxFit.cover,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'FRESH & NUTRITIOUS',
                                      style: AppTypography.labelSmall.copyWith(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Pre-Book Tomorrow's Meals",
                                    style: AppTypography.titleLarge.copyWith(color: Colors.white, fontSize: 17),
                                  ),
                                  Text(
                                    'Lock in your preference before 12:00 AM IST',
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primarySubtle,
                                foregroundColor: AppColors.primaryDark,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: onNavigateToBooking,
                              child: const Text('Book Now →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Today's Date Heading
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Dining Menu",
                        style: AppTypography.titleLarge,
                      ),
                      Text(
                        todayFormatted,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successSubtle,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'PUBLISHED',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (menuState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else ...[
                // Breakfast Card
                _buildMealCard(
                  title: 'Breakfast',
                  time: '7:30 AM – 9:30 AM',
                  type: BadgeType.breakfast,
                  icon: Icons.wb_sunny_outlined,
                  menu: menuState.todayMeals?.breakfast,
                  price: menuState.prices.breakfast,
                ),
                const SizedBox(height: 14),

                // Lunch Card
                _buildMealCard(
                  title: 'Lunch',
                  time: '12:30 PM – 2:30 PM',
                  type: BadgeType.lunch,
                  icon: Icons.wb_twilight_rounded,
                  menu: menuState.todayMeals?.lunch,
                  price: menuState.prices.lunch,
                ),
                const SizedBox(height: 14),

                // Dinner Card
                _buildMealCard(
                  title: 'Dinner',
                  time: '7:30 PM – 9:30 PM',
                  type: BadgeType.dinner,
                  icon: Icons.nightlight_round,
                  menu: menuState.todayMeals?.dinner,
                  price: menuState.prices.dinner,
                ),
              ],

              const SizedBox(height: 24),

              // Bottom Banner to Book Tomorrow
              CardContainer(
                backgroundColor: AppColors.primarySubtle.withOpacity(0.4),
                border: Border.all(color: AppColors.primaryMedium.withOpacity(0.3)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready for tomorrow?',
                            style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
                          ),
                          Text(
                            'Make your breakfast, lunch & dinner choices before midnight.',
                            style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 18),
                      onPressed: onNavigateToBooking,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard({
    required String title,
    required String time,
    required BadgeType type,
    required IconData icon,
    required MenuModel? menu,
    required double price,
  }) {
    final hasMenu = menu != null && menu.isPublished;

    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  StatusBadge(label: title.toUpperCase(), type: type, icon: icon),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                  ),
                ],
              ),
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: AppTypography.priceHighlight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasMenu) ...[
            Text(
              menu.title,
              style: AppTypography.titleLarge.copyWith(fontSize: 16),
            ),
            if (menu.description != null && menu.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                menu.description!,
                style: AppTypography.bodyMedium.copyWith(fontSize: 13),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: menu.dishes.map((dish) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        dish.name,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (menu.dietaryTags != null && menu.dietaryTags!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    menu.dietaryTags!,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Menu not yet published by kitchen administrator.',
                    style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
