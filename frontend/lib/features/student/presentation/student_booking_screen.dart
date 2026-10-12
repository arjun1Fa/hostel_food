import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';
import '../../../features/auth/state/auth_controller.dart';
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
    final authState = ref.watch(authProvider);
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

            // Offline Notification Banner
            if (authState.isOffline)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.warningSubtle,
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Offline Mode: You can review menus, but live bookings require active internet.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Midnight Cutoff Notice
                          CardContainer(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            backgroundColor: bookingState.isLocked ? AppColors.dangerSubtle : AppColors.primarySubtle,
                            border: Border.all(
                              color: bookingState.isLocked ? AppColors.danger.withOpacity(0.3) : AppColors.primaryTint,
                            ),
                            borderRadius: 16,
                            child: Row(
                              children: [
                                Icon(
                                  bookingState.isLocked ? Icons.lock_clock_rounded : Icons.schedule_rounded,
                                  color: bookingState.isLocked ? AppColors.danger : AppColors.primaryMedium,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bookingState.isLocked ? 'Booking Window Locked' : 'Authoritative Cutoff: 12:00 AM IST',
                                        style: AppTypography.titleMedium.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: bookingState.isLocked ? AppColors.danger : AppColors.primaryDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        bookingState.isLocked
                                            ? 'The deadline has passed. Contact the hostel admin office for overrides.'
                                            : 'Tomorrow’s portions will be calculated for kitchen preparation at midnight.',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!bookingState.isLocked) const CountdownTimerBadge(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Header instruction
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Your Meals',
                                style: AppTypography.titleLarge.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '$selectedCount / 3 selected',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryMedium,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 1. Breakfast Card
                          _buildMealSelectionCard(
                            slot: 'Breakfast',
                            timeSlot: '7:30 AM – 9:30 AM',
                            title: menuState.tomorrowMeals?.breakfast?.title ?? 'South Indian Delight',
                            desc: menuState.tomorrowMeals?.breakfast?.description ?? 'Fresh idlis, crispy vada, and rich sambar',
                            dietary: menuState.tomorrowMeals?.breakfast?.dietaryTags ?? 'Vegetarian',
                            price: menuState.prices.breakfast,
                            isSelected: bookingState.draftBreakfast,
                            isLocked: bookingState.isLocked,
                            onToggle: () => bookingNotifier.toggleBreakfast(),
                            mealType: 'breakfast',
                          ),
                          const SizedBox(height: 12),

                          // 2. Lunch Card
                          _buildMealSelectionCard(
                            slot: 'Lunch',
                            timeSlot: '12:30 PM – 2:30 PM',
                            title: menuState.tomorrowMeals?.lunch?.title ?? 'Royal Thali Feast',
                            desc: menuState.tomorrowMeals?.lunch?.description ?? 'Paneer butter masala, dal tadka, jeera rice, fresh rotis',
                            dietary: menuState.tomorrowMeals?.lunch?.dietaryTags ?? 'Balanced Diet',
                            price: menuState.prices.lunch,
                            isSelected: bookingState.draftLunch,
                            isLocked: bookingState.isLocked,
                            onToggle: () => bookingNotifier.toggleLunch(),
                            mealType: 'lunch',
                          ),
                          const SizedBox(height: 12),

                          // 3. Dinner Card
                          _buildMealSelectionCard(
                            slot: 'Dinner',
                            timeSlot: '7:30 PM – 9:30 PM',
                            title: menuState.tomorrowMeals?.dinner?.title ?? 'Hyderabadi Veg Biryani Special',
                            desc: menuState.tomorrowMeals?.dinner?.description ?? 'Dum biryani with rich gravy, mirchi ka salan, and kheer',
                            dietary: menuState.tomorrowMeals?.dinner?.dietaryTags ?? 'Special Dinner',
                            price: menuState.prices.dinner,
                            isSelected: bookingState.draftDinner,
                            isLocked: bookingState.isLocked,
                            onToggle: () => bookingNotifier.toggleDinner(),
                            mealType: 'dinner',
                          ),
                          const SizedBox(height: 18),

                          // Billing Rule Info Callout
                          CardContainer(
                            padding: const EdgeInsets.all(12),
                            backgroundColor: AppColors.surfaceHighlight,
                            border: Border.all(color: AppColors.cardBorderLight),
                            borderRadius: 14,
                            child: Row(
                              children: [
                                const Icon(Icons.verified_user_outlined, size: 20, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Pre-booking confirms kitchen portions. Charges are applied only when your actual consumption is recorded.',
                                    style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),

            // Bottom Sticky Bar (Live Total + Action)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Live Total Price with Animated Counter
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Estimated Total',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedPriceCounter(
                              amount: estimatedCost,
                              style: AppTypography.titleLarge.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Confirm button
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: (bookingState.isLocked || authState.isOffline)
                                  ? AppColors.textMuted
                                  : AppColors.accent,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            ),
                            onPressed: (bookingState.isLocked || bookingState.isSaving || authState.isOffline)
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
    return AnimatedContainer(
      duration: AppAnimations.fast,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.surface : AppColors.surfaceMuted.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primaryMedium : AppColors.cardBorder,
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryDark.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: isLocked ? null : onToggle,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                // Checkbox toggle with AnimatedSwitcher
                AnimatedContainer(
                  duration: AppAnimations.fast,
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: isSelected
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18, key: ValueKey('checked'))
                        : const SizedBox.shrink(key: ValueKey('empty')),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
