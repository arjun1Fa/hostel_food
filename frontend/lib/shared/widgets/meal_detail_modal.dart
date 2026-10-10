import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/student/models/menu_model.dart';
import 'food_image.dart';

class MealDetailModal extends StatelessWidget {
  final MenuModel menu;
  final double price;
  final VoidCallback? onBookNow;

  const MealDetailModal({
    super.key,
    required this.menu,
    required this.price,
    this.onBookNow,
  });

  static void show(
    BuildContext context, {
    required MenuModel menu,
    required double price,
    VoidCallback? onBookNow,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MealDetailModal(
        menu: menu,
        price: price,
        onBookNow: onBookNow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealTag = menu.mealType.toUpperCase();
    final timeSlot = menu.mealType.toLowerCase() == 'breakfast'
        ? '7:30 AM – 9:30 AM'
        : menu.mealType.toLowerCase() == 'lunch'
            ? '12:30 PM – 2:30 PM'
            : '7:30 PM – 9:30 PM';

    final tags = (menu.dietaryTags ?? '')
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (tags.isEmpty) {
      tags.addAll(['Vegetarian', 'Fresh Daily']);
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  FoodImage(
                    mealType: menu.mealType,
                    width: double.infinity,
                    height: 200,
                    borderRadius: 20,
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: menu.mealType.toLowerCase() == 'breakfast'
                                  ? AppColors.breakfastBg
                                  : menu.mealType.toLowerCase() == 'lunch'
                                      ? AppColors.lunchBg
                                      : AppColors.dinnerBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              mealTag,
                              style: AppTypography.labelSmall.copyWith(
                                color: menu.mealType.toLowerCase() == 'breakfast'
                                    ? AppColors.breakfast
                                    : menu.mealType.toLowerCase() == 'lunch'
                                        ? AppColors.lunch
                                        : AppColors.dinner,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeSlot,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        menu.title,
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: AppTypography.titleLarge.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            if (menu.description != null && menu.description!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                menu.description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySubtle,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        t,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Menu Items',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (menu.dishes.isEmpty)
              Text('Dishes to be announced by kitchen manager.', style: AppTypography.bodyMedium)
            else
              ...menu.dishes.map((dish) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.restaurant_menu_rounded, size: 14, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dish.name,
                          style: AppTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (dish.category != null && dish.category!.isNotEmpty)
                        Text(
                          dish.category!,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 24),
            if (onBookNow != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onBookNow!();
                  },
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: const Text('Book for Tomorrow', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.cardBorder),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
