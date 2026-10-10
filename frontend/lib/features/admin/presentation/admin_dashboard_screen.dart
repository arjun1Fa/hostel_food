import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/status_badge.dart';
import '../state/admin_controllers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  final Function(int) onNavigateTab;

  const AdminDashboardScreen({
    super.key,
    required this.onNavigateTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardProvider);

    final todayFormatted = DateFormat('EEE, d MMMM yyyy').format(DateTime.now());
    final tomorrowFormatted = DateFormat('EEE, d MMMM yyyy').format(DateTime.now().add(const Duration(days: 1)));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminDashboardProvider.notifier).loadDashboard(),
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Operations Dashboard', style: AppTypography.displayMedium.copyWith(fontSize: 22)),
                      const SizedBox(height: 4),
                      Text('Today: $todayFormatted', style: AppTypography.bodyMedium),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                    onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboard(),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // KPI Metric Cards Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isWide ? 1.4 : 1.25,
                    children: [
                      StatCard(
                        title: 'REGISTERED STUDENTS',
                        value: '${state.totalStudents}',
                        subtitle: 'Single Hostel Active',
                        icon: Icons.people_alt_rounded,
                        iconColor: AppColors.primary,
                        onTap: () => onNavigateTab(3), // Students
                      ),
                      StatCard(
                        title: 'TOMORROW PORTIONS',
                        value: '${state.tomorrowBreakfastPortions + state.tomorrowLunchPortions + state.tomorrowDinnerPortions}',
                        subtitle: 'B:${state.tomorrowBreakfastPortions} L:${state.tomorrowLunchPortions} D:${state.tomorrowDinnerPortions}',
                        icon: Icons.soup_kitchen_rounded,
                        iconColor: AppColors.accent,
                        onTap: () => onNavigateTab(6), // Kitchen Reports
                      ),
                      StatCard(
                        title: "TODAY'S CHARGES",
                        value: '₹${state.todayRevenue.toStringAsFixed(0)}',
                        subtitle: 'From Recorded Consumption',
                        icon: Icons.currency_rupee_rounded,
                        iconColor: AppColors.success,
                        onTap: () => onNavigateTab(5), // Consumption
                      ),
                      StatCard(
                        title: 'ACTIVE PRICES',
                        value: '₹${state.prices.breakfast.toInt()} / ₹${state.prices.lunch.toInt()} / ₹${state.prices.dinner.toInt()}',
                        subtitle: 'Breakfast / Lunch / Dinner',
                        icon: Icons.sell_rounded,
                        iconColor: AppColors.dinner,
                        onTap: () => onNavigateTab(2), // Prices
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 22),

              // Kitchen Preparation Spotlight for Tomorrow
              CardContainer(
                padding: const EdgeInsets.all(18),
                backgroundColor: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.restaurant_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Tomorrow's Kitchen Prep Counts",
                              style: AppTypography.titleLarge.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                        Text(
                          tomorrowFormatted,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPortionBox(
                            mealName: 'BREAKFAST',
                            count: state.tomorrowBreakfastPortions,
                            type: BadgeType.breakfast,
                            price: state.prices.breakfast,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPortionBox(
                            mealName: 'LUNCH',
                            count: state.tomorrowLunchPortions,
                            type: BadgeType.lunch,
                            price: state.prices.lunch,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildPortionBox(
                            mealName: 'DINNER',
                            count: state.tomorrowDinnerPortions,
                            type: BadgeType.dinner,
                            price: state.prices.dinner,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.print_rounded, size: 16),
                          label: const Text('View Preparation Sheet'),
                          onPressed: () => onNavigateTab(6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Menu Status Spotlight
              Text('Menu Publication Status', style: AppTypography.titleLarge),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildDayMenuStatusCard(
                      label: "Today's Menus",
                      dateStr: todayFormatted,
                      bPublished: state.todayMeals?.breakfast?.isPublished ?? false,
                      lPublished: state.todayMeals?.lunch?.isPublished ?? false,
                      dPublished: state.todayMeals?.dinner?.isPublished ?? false,
                      onManage: () => onNavigateTab(1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDayMenuStatusCard(
                      label: "Tomorrow's Menus",
                      dateStr: tomorrowFormatted,
                      bPublished: state.tomorrowMeals?.breakfast?.isPublished ?? false,
                      lPublished: state.tomorrowMeals?.lunch?.isPublished ?? false,
                      dPublished: state.tomorrowMeals?.dinner?.isPublished ?? false,
                      onManage: () => onNavigateTab(1),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Quick Action Buttons
              Text('Quick Operations', style: AppTypography.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.primary),
                    label: const Text('Publish Menus'),
                    backgroundColor: AppColors.primarySubtle,
                    side: BorderSide.none,
                    onPressed: () => onNavigateTab(1),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.checklist_rounded, size: 16, color: AppColors.lunch),
                    label: const Text('Record Today Consumption'),
                    backgroundColor: AppColors.surfaceMuted,
                    side: BorderSide.none,
                    onPressed: () => onNavigateTab(5),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.price_change_rounded, size: 16, color: AppColors.dinner),
                    label: const Text('Configure Meal Prices'),
                    backgroundColor: AppColors.surfaceMuted,
                    side: BorderSide.none,
                    onPressed: () => onNavigateTab(2),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.people_outline_rounded, size: 16, color: AppColors.accent),
                    label: const Text('Student Directory'),
                    backgroundColor: AppColors.surfaceMuted,
                    side: BorderSide.none,
                    onPressed: () => onNavigateTab(3),
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

  Widget _buildPortionBox({
    required String mealName,
    required int count,
    required BadgeType type,
    required double price,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: mealName, type: type),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: AppTypography.displayLarge.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            'portions (₹${price.toInt()})',
            style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildDayMenuStatusCard({
    required String label,
    required String dateStr,
    required bool bPublished,
    required bool lPublished,
    required bool dPublished,
    required VoidCallback onManage,
  }) {
    return CardContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
          Text(dateStr, style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 10),
          _buildMenuPublishedRow('Breakfast', bPublished),
          const SizedBox(height: 4),
          _buildMenuPublishedRow('Lunch', lPublished),
          const SizedBox(height: 4),
          _buildMenuPublishedRow('Dinner', dPublished),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onManage,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              child: const Text('Manage Menu →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuPublishedRow(String name, bool isPub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isPub ? AppColors.successSubtle : AppColors.warningSubtle,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            isPub ? 'LIVE' : 'DRAFT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isPub ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
      ],
    );
  }
}
