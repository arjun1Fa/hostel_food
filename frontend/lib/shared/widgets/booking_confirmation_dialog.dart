import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'food_image.dart';

class BookingConfirmationDialog extends StatelessWidget {
  final String dateText;
  final bool bookedBreakfast;
  final bool bookedLunch;
  final bool bookedDinner;
  final double breakfastPrice;
  final double lunchPrice;
  final double dinnerPrice;
  final VoidCallback onViewBookings;
  final VoidCallback onBackToHome;

  const BookingConfirmationDialog({
    super.key,
    required this.dateText,
    required this.bookedBreakfast,
    required this.bookedLunch,
    required this.bookedDinner,
    required this.breakfastPrice,
    required this.lunchPrice,
    required this.dinnerPrice,
    required this.onViewBookings,
    required this.onBackToHome,
  });

  static void show(
    BuildContext context, {
    required String dateText,
    required bool bookedBreakfast,
    required bool bookedLunch,
    required bool bookedDinner,
    required double breakfastPrice,
    required double lunchPrice,
    required double dinnerPrice,
    required VoidCallback onViewBookings,
    required VoidCallback onBackToHome,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BookingConfirmationDialog(
        dateText: dateText,
        bookedBreakfast: bookedBreakfast,
        bookedLunch: bookedLunch,
        bookedDinner: bookedDinner,
        breakfastPrice: breakfastPrice,
        lunchPrice: lunchPrice,
        dinnerPrice: dinnerPrice,
        onViewBookings: onViewBookings,
        onBackToHome: onBackToHome,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    if (bookedBreakfast) total += breakfastPrice;
    if (bookedLunch) total += lunchPrice;
    if (bookedDinner) total += dinnerPrice;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radiant checkmark circle
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.successSubtle,
                  border: Border.all(color: AppColors.success.withOpacity(0.3), width: 3),
                ),
                child: const Center(
                  child: Icon(Icons.check_rounded, color: AppColors.successDark, size: 44),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Booking Confirmed!',
                style: AppTypography.displayMedium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Your meals for $dateText have been successfully locked in.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Meal summary cards
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    if (bookedBreakfast)
                      _buildMealRow('Breakfast', 'South Indian Delight', breakfastPrice, 'breakfast'),
                    if (bookedLunch)
                      _buildMealRow('Lunch', 'Royal Thali Feast', lunchPrice, 'lunch'),
                    if (bookedDinner)
                      _buildMealRow('Dinner', 'Comfort Biryani Dinner', dinnerPrice, 'dinner'),
                    if (!bookedBreakfast && !bookedLunch && !bookedDinner)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No meals selected (Skipping meals tomorrow)',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    const Divider(color: AppColors.cardBorder, height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Estimated Cost',
                          style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₹${total.toStringAsFixed(0)}',
                          style: AppTypography.titleLarge.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Modification note
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can freely update your selection anytime before 12:00 AM tonight.',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primaryMedium,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onViewBookings();
                  },
                  child: const Text('View My Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onBackToHome();
                  },
                  child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealRow(String slot, String title, double price, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          FoodImage(mealType: type, width: 44, height: 44, borderRadius: 8),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot, style: AppTypography.labelSmall.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.bold)),
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
          Text(
            '₹${price.toStringAsFixed(0)}',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
