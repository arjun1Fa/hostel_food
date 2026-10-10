import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../state/student_controllers.dart';
import '../models/expense_model.dart';

class StudentExpensesScreen extends ConsumerStatefulWidget {
  const StudentExpensesScreen({super.key});

  @override
  ConsumerState<StudentExpensesScreen> createState() => _StudentExpensesScreenState();
}

class _StudentExpensesScreenState extends ConsumerState<StudentExpensesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(studentExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Expenses', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
            Text('Track your dining expenses & consumption', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(studentExpensesProvider.notifier).loadExpenses(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Detailed History'),
              ],
            ),
          ),
        ),
      ),
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Unable to load expenses: $err', style: AppTypography.bodyMedium),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(studentExpensesProvider.notifier).loadExpenses(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (summary) {
          final monthName = DateFormat('MMMM yyyy').format(DateTime(summary.year, summary.month));
          final avgPerMeal = summary.totalConsumedCount > 0
              ? (summary.totalCharges / summary.totalConsumedCount).round()
              : 0;

          return TabBarView(
            controller: _tabController,
            children: [
              // 1. Overview Tab
              RefreshIndicator(
                onRefresh: () => ref.read(studentExpensesProvider.notifier).loadExpenses(),
                color: AppColors.primaryDark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Forest Green Hero Spending Card with Bar Chart
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryDark.withOpacity(0.25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
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
                                      'This Month',
                                      style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                                    ),
                                    Text(
                                      monthName,
                                      style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        monthName,
                                        style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total Spent',
                              style: AppTypography.labelSmall.copyWith(color: Colors.white70),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${summary.totalCharges.toStringAsFixed(0)}',
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Weekly Bars Chart Visualization
                            _buildWeeklySpendingChart(summary.totalCharges),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Stat Metrics Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Meals Consumed',
                              value: '${summary.totalConsumedCount}',
                              icon: Icons.done_all_rounded,
                              color: AppColors.successDark,
                              bgColor: AppColors.successSubtle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Avg per Meal',
                              value: '₹$avgPerMeal',
                              icon: Icons.analytics_outlined,
                              color: AppColors.primary,
                              bgColor: AppColors.primarySubtle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Days Active',
                              value: '${summary.days.length}',
                              icon: Icons.calendar_today_rounded,
                              color: AppColors.accentWarm,
                              bgColor: AppColors.accentSubtle,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // Section: Recent Daily Expenses
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Daily Consumption Records',
                            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${summary.days.length} days recorded',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (summary.days.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Center(
                            child: Text(
                              'No consumption recorded yet this month.',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                        )
                      else
                        ...summary.days.take(6).map((day) => _buildDayExpenseItem(day)),
                    ],
                  ),
                ),
              ),

              // 2. Detailed History Tab
              ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: summary.days.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final day = summary.days[index];
                  return _buildDayExpenseItem(day);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeeklySpendingChart(double total) {
    // Generate 4 representative weekly bars
    final bars = [0.22, 0.28, 0.26, 0.24];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Distribution',
                style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 10),
              ),
              Text(
                '4 Weeks',
                style: AppTypography.labelSmall.copyWith(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('W1', bars[0]),
                _buildBar('W2', bars[1]),
                _buildBar('W3', bars[2]),
                _buildBar('W4', bars[3]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double ratio) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: (ratio * 150).clamp(16.0, 48.0),
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildDayExpenseItem(StudentDayExpenseModel day) {
    return CardContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_available_rounded, size: 18, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    day.date,
                    style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '₹${day.totalCharge.toStringAsFixed(0)}',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.cardBorder),
          Row(
            children: [
              _buildMiniMealTag('Breakfast', day.breakfast),
              const SizedBox(width: 8),
              _buildMiniMealTag('Lunch', day.lunch),
              const SizedBox(width: 8),
              _buildMiniMealTag('Dinner', day.dinner),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMealTag(String label, MealStatusModel status) {
    final bool isConsumed = status.consumed;
    final bool isBooked = status.booked;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isConsumed ? AppColors.successSubtle : (isBooked ? AppColors.warningSubtle : AppColors.surfaceMuted),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConsumed ? Icons.check_circle_rounded : (isBooked ? Icons.bookmark_added_rounded : Icons.remove_rounded),
            size: 11,
            color: isConsumed ? AppColors.successDark : (isBooked ? AppColors.warning : AppColors.textMuted),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isConsumed ? AppColors.successDark : (isBooked ? AppColors.warning : AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
