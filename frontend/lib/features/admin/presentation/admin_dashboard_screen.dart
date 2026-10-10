import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/food_image.dart';
import '../state/admin_controllers.dart';
import '../../student/models/menu_model.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final Function(int) onNavigateTab;

  const AdminDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final tomorrowFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now().add(const Duration(days: 1)));

    final totalTomorrowPortions = state.tomorrowBreakfastPortions + state.tomorrowLunchPortions + state.tomorrowDinnerPortions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminDashboardProvider.notifier).loadDashboard(),
        color: AppColors.primaryDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header with Greeting & Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good evening,',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        'Admin Dashboard',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryDark),
                        const SizedBox(width: 8),
                        Text(
                          todayFormatted,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // KPI 4-Card Overview
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.6 : 1.35,
                    children: [
                      _buildKpiCard(
                        title: 'Total Students',
                        value: '${state.totalStudents}',
                        sub: 'Registered in hostel',
                        icon: Icons.people_alt_rounded,
                        color: AppColors.primaryDark,
                        bg: AppColors.primarySubtle,
                        onTap: () => onNavigateTab(3),
                      ),
                      _buildKpiCard(
                        title: 'Breakfast Booked',
                        value: '${state.tomorrowBreakfastPortions}',
                        sub: 'of ${state.totalStudents} students',
                        icon: Icons.wb_sunny_rounded,
                        color: AppColors.breakfast,
                        bg: AppColors.breakfastBg,
                        onTap: () => onNavigateTab(4),
                      ),
                      _buildKpiCard(
                        title: 'Lunch Booked',
                        value: '${state.tomorrowLunchPortions}',
                        sub: 'of ${state.totalStudents} students',
                        icon: Icons.lunch_dining_rounded,
                        color: AppColors.lunch,
                        bg: AppColors.lunchBg,
                        onTap: () => onNavigateTab(4),
                      ),
                      _buildKpiCard(
                        title: 'Dinner Booked',
                        value: '${state.tomorrowDinnerPortions}',
                        sub: 'of ${state.totalStudents} students',
                        icon: Icons.nightlight_round,
                        color: AppColors.dinner,
                        bg: AppColors.dinnerBg,
                        onTap: () => onNavigateTab(4),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Tomorrow's Preparation Count Card matching Reference 1 (Image 9)
              CardContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tomorrow's Preparation Count",
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            Text(
                              tomorrowFormatted,
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () => onNavigateTab(6),
                          icon: const Icon(Icons.print_rounded, size: 14, color: AppColors.primaryDark),
                          label: const Text('Kitchen Sheet', style: TextStyle(color: AppColors.primaryDark, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        // Breakfast Peach Box
                        Expanded(
                          child: _buildPrepBox(
                            count: state.tomorrowBreakfastPortions,
                            label: 'Breakfast',
                            textColor: AppColors.breakfast,
                            bgColor: AppColors.breakfastBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Lunch Mint Box
                        Expanded(
                          child: _buildPrepBox(
                            count: state.tomorrowLunchPortions,
                            label: 'Lunch',
                            textColor: AppColors.lunch,
                            bgColor: AppColors.lunchBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Dinner Lilac Box
                        Expanded(
                          child: _buildPrepBox(
                            count: state.tomorrowDinnerPortions,
                            label: 'Dinner',
                            textColor: AppColors.dinner,
                            bgColor: AppColors.dinnerBg,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Total Dark Forest Box
                        Expanded(
                          child: _buildPrepBox(
                            count: totalTomorrowPortions,
                            label: 'Total Meals',
                            textColor: Colors.white,
                            bgColor: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Today's Menu Section (3 side-by-side cards)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Today's Menu",
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () => onNavigateTab(1),
                    child: const Text('Manage Menus →', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentWarm)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(
                          child: _buildAdminMealCard(
                            slot: 'Breakfast',
                            time: '7:30 AM – 9:30 AM',
                            menu: state.todayMeals?.breakfast,
                            price: state.prices.breakfast,
                            defaultTitle: 'South Indian Delight',
                            type: 'breakfast',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAdminMealCard(
                            slot: 'Lunch',
                            time: '12:30 PM – 2:30 PM',
                            menu: state.todayMeals?.lunch,
                            price: state.prices.lunch,
                            defaultTitle: 'Royal Thali Feast',
                            type: 'lunch',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildAdminMealCard(
                            slot: 'Dinner',
                            time: '7:30 PM – 9:30 PM',
                            menu: state.todayMeals?.dinner,
                            price: state.prices.dinner,
                            defaultTitle: 'Comfort Biryani Dinner',
                            type: 'dinner',
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      _buildAdminMealCard(
                        slot: 'Breakfast',
                        time: '7:30 AM – 9:30 AM',
                        menu: state.todayMeals?.breakfast,
                        price: state.prices.breakfast,
                        defaultTitle: 'South Indian Delight',
                        type: 'breakfast',
                      ),
                      const SizedBox(height: 12),
                      _buildAdminMealCard(
                        slot: 'Lunch',
                        time: '12:30 PM – 2:30 PM',
                        menu: state.todayMeals?.lunch,
                        price: state.prices.lunch,
                        defaultTitle: 'Royal Thali Feast',
                        type: 'lunch',
                      ),
                      const SizedBox(height: 12),
                      _buildAdminMealCard(
                        slot: 'Dinner',
                        time: '7:30 PM – 9:30 PM',
                        menu: state.todayMeals?.dinner,
                        price: state.prices.dinner,
                        defaultTitle: 'Comfort Biryani Dinner',
                        type: 'dinner',
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),

              // Quick Actions Grid
              Text(
                'Quick Actions',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionBtn(
                      icon: Icons.edit_note_rounded,
                      label: 'Edit Menu',
                      color: AppColors.accentWarm,
                      bg: AppColors.accentSubtle,
                      onTap: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionBtn(
                      icon: Icons.checklist_rtl_rounded,
                      label: 'Record Consumption',
                      color: AppColors.successDark,
                      bg: AppColors.successSubtle,
                      onTap: () => onNavigateTab(5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionBtn(
                      icon: Icons.bar_chart_rounded,
                      label: 'View Reports',
                      color: AppColors.info,
                      bg: AppColors.infoSubtle,
                      onTap: () => onNavigateTab(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionBtn(
                      icon: Icons.people_outline_rounded,
                      label: 'Manage Students',
                      color: AppColors.primaryMedium,
                      bg: AppColors.primarySubtle,
                      onTap: () => onNavigateTab(3),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return CardContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.labelSmall.copyWith(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
              ),
              Text(
                sub,
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrepBox({
    required int count,
    required String label,
    required Color textColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMealCard({
    required String slot,
    required String time,
    required MenuModel? menu,
    required double price,
    required String defaultTitle,
    required String type,
  }) {
    final title = menu?.title.isNotEmpty == true ? menu!.title : defaultTitle;
    final isPub = menu?.isPublished ?? true;

    return CardContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FoodImage(
              mealType: type,
              width: double.infinity,
              height: 100,
              borderRadius: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                slot,
                style: AppTypography.labelSmall.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPub ? AppColors.successSubtle : AppColors.warningSubtle,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPub ? 'PUBLISHED' : 'DRAFT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isPub ? AppColors.successDark : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(time, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
              Text('₹${price.toStringAsFixed(0)}', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return CardContainer(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      borderRadius: 16,
      backgroundColor: AppColors.surface,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
