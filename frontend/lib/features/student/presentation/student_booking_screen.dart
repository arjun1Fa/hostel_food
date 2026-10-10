import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/countdown_timer_badge.dart';
import '../../../shared/widgets/food_image.dart';
import '../../../shared/widgets/booking_confirmation_dialog.dart';
import '../state/student_controllers.dart';

class StudentBookingScreen extends ConsumerWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToBookings;

  const StudentBookingScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToBookings,
  });

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
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    onPressed: () {
                      if (onNavigateToHome != null) {
                        onNavigateToHome!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Book Tomorrow's Meals",
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          tomorrowFormatted,
                          style: AppTypography.bodyMedium.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      ref.read(studentMenuProvider.notifier).loadMenus();
                      bookingNotifier.loadTomorrowBooking();
                    },
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: bookingState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryDark),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Live Countdown Timer Card
                          const CountdownTimerBadge(),

                          const SizedBox(height: 18),

                          // 2. Section Heading
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Tomorrow's Menu & Selection",
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (bookingState.committedBooking != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: bookingState.hasUnsavedChanges
                                        ? AppColors.warningSubtle
                                        : AppColors.successSubtle,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        bookingState.hasUnsavedChanges ? Icons.edit_note_rounded : Icons.check_circle_rounded,
                                        size: 13,
                                        color: bookingState.hasUnsavedChanges ? AppColors.warning : AppColors.successDark,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        bookingState.hasUnsavedChanges ? 'UNSAVED' : 'CONFIRMED',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: bookingState.hasUnsavedChanges ? AppColors.warning : AppColors.successDark,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Breakfast Selection Card
                          _buildMealSelectionCard(
                            slot: 'Breakfast',
                            timeSlot: '7:30 AM – 9:30 AM',
                            title: menuState.tomorrowMeals?.breakfast?.title ?? 'South Indian Delight',
                            desc: menuState.tomorrowMeals?.breakfast?.description ?? 'Steamed rice idlis, crispy medu vada, vegetable sambar & fresh coconut chutney',
                            dietary: menuState.tomorrowMeals?.breakfast?.dietaryTags ?? 'Vegetarian • High Protein',
                            price: menuState.prices.breakfast,
                            isSelected: bookingState.draftBreakfast,
                            isLocked: bookingState.isLocked,
                            onToggle: bookingNotifier.toggleBreakfast,
                            mealType: 'breakfast',
                          ),

                          const SizedBox(height: 12),

                          // Lunch Selection Card
                          _buildMealSelectionCard(
                            slot: 'Lunch',
                            timeSlot: '12:30 PM – 2:30 PM',
                            title: menuState.tomorrowMeals?.lunch?.title ?? 'Royal Thali Feast',
                            desc: menuState.tomorrowMeals?.lunch?.description ?? 'Paneer butter masala, dal tadka, aromatic jeera rice, soft roti & garden salad',
                            dietary: menuState.tomorrowMeals?.lunch?.dietaryTags ?? 'Vegetarian • Wholesome',
                            price: menuState.prices.lunch,
                            isSelected: bookingState.draftLunch,
                            isLocked: bookingState.isLocked,
                            onToggle: bookingNotifier.toggleLunch,
                            mealType: 'lunch',
                          ),

                          const SizedBox(height: 12),

                          // Dinner Selection Card
                          _buildMealSelectionCard(
                            slot: 'Dinner',
                            timeSlot: '7:30 PM – 9:30 PM',
                            title: menuState.tomorrowMeals?.dinner?.title ?? 'Comfort Biryani Dinner',
                            desc: menuState.tomorrowMeals?.dinner?.description ?? 'Fragrant Dum biryani, creamy cucumber raita, crisp roasted papad & dessert',
                            dietary: menuState.tomorrowMeals?.dinner?.dietaryTags ?? 'Comfort • Wholesome',
                            price: menuState.prices.dinner,
                            isSelected: bookingState.draftDinner,
                            isLocked: bookingState.isLocked,
                            onToggle: bookingNotifier.toggleDinner,
                            mealType: 'dinner',
                          ),

                          const SizedBox(height: 16),

                          // Policy card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceHighlight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, size: 20, color: AppColors.primaryMedium),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Hostel Dining Policy: Only pre-booked meals are prepared to prevent kitchen waste. Charges apply based on recorded consumption.',
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),

            // Persistent Bottom Sticky Summary & Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Estimated Total',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$selectedCount ${selectedCount == 1 ? "meal" : "meals"}',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primaryDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${estimatedCost.toStringAsFixed(0)}',
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        // Confirm button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: bookingState.isLocked ? AppColors.textMuted : AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: bookingState.isLocked || bookingState.isSaving
                                ? null
                                : () async {
                                    final success = await bookingNotifier.saveBooking();
                                    if (success && context.mounted) {
                                      // Invalidate bookings provider to update records
                                      ref.invalidate(myBookingsProvider);
                                      // Show confirmation dialog!
                                      BookingConfirmationDialog.show(
                                        context,
                                        dateText: tomorrowFormatted,
                                        bookedBreakfast: bookingState.draftBreakfast,
                                        bookedLunch: bookingState.draftLunch,
                                        bookedDinner: bookingState.draftDinner,
                                        breakfastPrice: menuState.prices.breakfast,
                                        lunchPrice: menuState.prices.lunch,
                                        dinnerPrice: menuState.prices.dinner,
                                        onViewBookings: () {
                                          if (onNavigateToBookings != null) {
                                            onNavigateToBookings!();
                                          }
                                        },
                                        onBackToHome: () {
                                          if (onNavigateToHome != null) {
                                            onNavigateToHome!();
                                          }
                                        },
                                      );
                                    } else if (!success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(bookingState.errorMessage ?? 'Failed to save booking.'),
                                          backgroundColor: AppColors.danger,
                                        ),
                                      );
                                    }
                                  },
                            icon: bookingState.isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            label: const Icon(Icons.arrow_forward_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSelectionCard({
    required String slot,
    required String timeSlot,
    required String title,
    required String desc,
    required String dietary,
    required double price,
    required bool isSelected,
    required bool isLocked,
    required VoidCallback onToggle,
    required String mealType,
  }) {
    return CardContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      backgroundColor: isSelected ? AppColors.surface : AppColors.surfaceMuted.withOpacity(0.6),
      border: Border.all(
        color: isSelected ? AppColors.primaryMedium : AppColors.cardBorder,
        width: isSelected ? 1.5 : 1,
      ),
      onTap: isLocked ? null : onToggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Thumbnail
          FoodImage(
            mealType: mealType,
            width: 76,
            height: 76,
            borderRadius: 14,
          ),
          const SizedBox(width: 14),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: mealType == 'breakfast'
                            ? AppColors.breakfastBg
                            : mealType == 'lunch'
                                ? AppColors.lunchBg
                                : AppColors.dinnerBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$slot • $timeSlot',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: mealType == 'breakfast'
                              ? AppColors.breakfast
                              : mealType == 'lunch'
                                  ? AppColors.lunch
                                  : AppColors.dinner,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Checkbox toggle
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppColors.primaryDark : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primaryDark : AppColors.cardBorder,
                width: 2,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
