import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class FoodImage extends StatelessWidget {
  final String? mealType;
  final String? customAssetPath;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;

  const FoodImage({
    super.key,
    this.mealType,
    this.customAssetPath,
    this.width = 80,
    this.height = 80,
    this.borderRadius = 14,
    this.fit = BoxFit.cover,
  });

  String get _assetForMeal {
    if (customAssetPath != null && customAssetPath!.isNotEmpty) {
      return customAssetPath!;
    }
    final normalized = (mealType ?? '').toLowerCase();
    if (normalized.contains('break')) {
      return 'assets/images/breakfast_idli.jpg';
    } else if (normalized.contains('lunch')) {
      return 'assets/images/lunch_thali.jpg';
    } else if (normalized.contains('din')) {
      return 'assets/images/dinner_biryani.jpg';
    }
    return 'assets/images/hostel_food_hero.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetForMeal;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceMuted,
        child: Image.asset(
          assetPath,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: AppColors.primarySubtle,
              child: Center(
                child: Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.primaryMedium,
                  size: width * 0.4,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
