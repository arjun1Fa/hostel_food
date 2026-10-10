import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/custom_button.dart';
import '../state/student_controllers.dart';
import '../models/menu_model.dart';

class StudentBookingScreen extends ConsumerWidget {
  const StudentBookingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(studentMenuProvider);
    final bookingState = ref.watch(studentBookingProvider);
    final bookingNotifier = ref.read(studentBookingProvider.notifier);

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowFormatted = DateFormat('EEEE, d MMMM yyyy').format(tomorrow);

    final estimatedCost = bookingState.calculateEstimatedCost(menuState.prices);

    int selectedCount = 0;
    if (bookingState.draftBreakfast) selectedCount++;
    if (bookingState.draftLunch) selectedCount++;
    if (bookingState.draftDinner) selectedCount++;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Book Tomorrow’s Meals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(studentMenuProvider.notifier).loadMenus();
              bookingNotifier.loadTomorrowBooking();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Cutoff Information Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: bookingState.isLocked ? AppColors.dangerSubtle : AppColors.accentSubtle,
            child: Row(
              children: [
                Icon(
                  bookingState.isLocked ? Icons.lock_clock_rounded : Icons.timer_outlined,
                  size: 18,
                  color: bookingState.isLocked ? AppColors.danger : AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bookingState.isLocked
                        ? 'Bookings Locked: Midnight (12:00 AM IST) cutoff has passed for tomorrow.'
                        : 'Booking Deadline: Tonight at 12:00 AM IST. Changes lock authoritatively at midnight.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: bookingState.isLocked ? AppColors.danger : const Color(0xFF78350F),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Meal Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tomorrow Date Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Meal Selection', style: AppTypography.titleLarge),
                          Text(tomorrowFormatted, style: AppTypography.bodyMedium),
                        ],
                      ),
                      if (bookingState.committedBooking != null)
                        StatusBadge(
                          label: bookingState.hasUnsavedChanges ? 'UNSAVED CHANGES' : 'BOOKING SAVED',
                          type: bookingState.hasUnsavedChanges ? BadgeType.warning : BadgeType.success,
                          icon: bookingState.hasUnsavedChanges ? Icons.edit_outlined : Icons.check_circle_outline_rounded,
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (bookingState.successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              bookingState.successMessage!,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (bookingState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bookingState.errorMessage!,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 1. Breakfast Option
                  _buildInteractiveMealCard(
                    title: 'Breakfast',
                    time: '7:30 AM – 9:30 AM',
                    type: BadgeType.breakfast,
                    icon: Icons.wb_sunny_outlined,
                    price: menuState.prices.breakfast,
                    isSelected: bookingState.draftBreakfast,
                    isLocked: bookingState.isLocked,
                    menu: menuState.tomorrowMeals?.breakfast,
                    onToggle: () => bookingNotifier.toggleBreakfast(),
                  ),

                  const SizedBox(height: 14),

                  // 2. Lunch Option
                  _buildInteractiveMealCard(
                    title: 'Lunch',
                    time: '12:30 PM – 2:30 PM',
                    type: BadgeType.lunch,
                    icon: Icons.wb_twilight_rounded,
                    price: menuState.prices.lunch,
                    isSelected: bookingState.draftLunch,
                    isLocked: bookingState.isLocked,
                    menu: menuState.tomorrowMeals?.lunch,
                    onToggle: () => bookingNotifier.toggleLunch(),
                  ),

                  const SizedBox(height: 14),

                  // 3. Dinner Option
                  _buildInteractiveMealCard(
                    title: 'Dinner',
                    time: '7:30 PM – 9:30 PM',
                    type: BadgeType.dinner,
                    icon: Icons.nightlight_round,
                    price: menuState.prices.dinner,
                    isSelected: bookingState.draftDinner,
                    isLocked: bookingState.isLocked,
                    menu: menuState.tomorrowMeals?.dinner,
                    onToggle: () => bookingNotifier.toggleDinner(),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Persistent Bottom Booking Summary Sheet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedCount of 3 meals selected',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '₹${estimatedCost.toStringAsFixed(0)}',
                              style: AppTypography.displayLarge.copyWith(fontSize: 22, color: AppColors.primary),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'est. charge',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  CustomButton(
                    text: bookingState.isLocked
                        ? 'Locked'
                        : (bookingState.committedBooking == null ? 'Confirm Booking' : 'Update Booking'),
                    isLoading: bookingState.isSaving,
                    icon: bookingState.isLocked ? Icons.lock_rounded : Icons.check_circle_rounded,
                    variant: bookingState.isLocked ? ButtonVariant.secondary : ButtonVariant.primary,
                    width: 170,
                    onPressed: bookingState.isLocked ? null : () => bookingNotifier.saveBooking(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveMealCard({
    required String title,
    required String time,
    required BadgeType type,
    required IconData icon,
    required double price,
    required bool isSelected,
    required bool isLocked,
    required MenuModel? menu,
    required VoidCallback onToggle,
  }) {
    final hasMenu = menu != null && menu.isPublished;

    return GestureDetector(
      onTap: isLocked ? null : onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surface.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Selection Checkbox Pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                StatusBadge(label: title.toUpperCase(), type: type, icon: icon),
                const SizedBox(width: 8),
                Text(time, style: AppTypography.bodyMedium.copyWith(fontSize: 11)),
                const Spacer(),
                Text('₹${price.toStringAsFixed(0)}', style: AppTypography.priceHighlight),
              ],
            ),
            const SizedBox(height: 12),
            if (hasMenu) ...[
              Text(
                menu.title,
                style: AppTypography.titleLarge.copyWith(fontSize: 15),
              ),
              if (menu.description != null && menu.description!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(menu.description!, style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: menu.dishes.map((dish) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      dish.name,
                      style: AppTypography.bodyMedium.copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              Text(
                'Menu to be published by kitchen manager.',
                style: AppTypography.bodyMedium.copyWith(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
