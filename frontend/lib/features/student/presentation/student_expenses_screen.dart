import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/empty_state.dart';
import '../state/student_controllers.dart';
import '../models/expense_model.dart';

class StudentExpensesScreen extends ConsumerWidget {
  const StudentExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(studentExpensesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Meal Expenses & Charges'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(studentExpensesProvider.notifier).loadExpenses(),
          ),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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

          return RefreshIndicator(
            onRefresh: () => ref.read(studentExpensesProvider.notifier).loadExpenses(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Month Total Card
                  CardContainer(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              monthName.toUpperCase(),
                              style: AppTypography.labelSmall.copyWith(color: Colors.white70, letterSpacing: 1),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${summary.totalConsumedCount} meals consumed',
                                style: AppTypography.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₹${summary.totalCharges.toStringAsFixed(0)}',
                          style: AppTypography.displayLarge.copyWith(color: Colors.white, fontSize: 34),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total Recorded Meal Charges',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Transparency Notice Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryMedium.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hostel Policy: Charges are billed solely on recorded consumption. Unconsumed bookings are never charged.',
                            style: AppTypography.bodyMedium.copyWith(
                              fontSize: 12,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Itemized Consumption History',
                    style: AppTypography.titleLarge,
                  ),
                  const SizedBox(height: 10),

                  if (summary.days.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No Recorded Charges Yet',
                      description: 'Meal consumption marked by the administrator will appear itemized here.',
                    )
                  else
                    ...summary.days.map((day) => _buildDayExpenseRow(day)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayExpenseRow(StudentDayExpenseModel day) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(day.date);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(parsedDate);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: CardContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: AppTypography.titleMedium.copyWith(fontSize: 14),
                ),
                Text(
                  day.totalCharge > 0 ? '₹${day.totalCharge.toStringAsFixed(0)}' : '₹0',
                  style: AppTypography.titleLarge.copyWith(
                    color: day.totalCharge > 0 ? AppColors.primary : AppColors.textMuted,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.cardBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMealStatusChip('Breakfast', day.breakfast),
                _buildMealStatusChip('Lunch', day.lunch),
                _buildMealStatusChip('Dinner', day.dinner),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealStatusChip(String name, MealStatusModel status) {
    Color color;
    IconData icon;

    if (status.consumed) {
      color = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (status.booked) {
      color = AppColors.warning;
      icon = Icons.cancel_outlined;
    } else {
      color = AppColors.textMuted;
      icon = Icons.remove_circle_outline_rounded;
    }

    return Column(
      children: [
        Text(
          name,
          style: AppTypography.labelSmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              status.consumed ? '₹${status.priceCharged.toStringAsFixed(0)}' : (status.booked ? 'Skipped' : '—'),
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
