import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/food_image.dart';
import '../../../shared/widgets/meal_detail_modal.dart';
import '../../auth/state/auth_controller.dart';
import '../state/student_controllers.dart';
import '../models/menu_model.dart';

class StudentHomeScreen extends ConsumerWidget {
  final VoidCallback onNavigateToBooking;
  final VoidCallback? onNavigateToNotifications;

  const StudentHomeScreen({
    super.key,
    required this.onNavigateToBooking,
    this.onNavigateToNotifications,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final menuState = ref.watch(studentMenuProvider);
    final user = authState.user;

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () => ref.read(studentMenuProvider.notifier).loadMenus(),
        color: AppColors.primaryDark,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Personalized Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good morning,',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        Text(
                          user?.fullName ?? 'Arjun',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 13, color: AppColors.accentWarm),
                            const SizedBox(width: 4),
                            Text(
                              'Heritage Hostel • Room ${user?.roomNumber ?? "302"}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Notification bell with alert dot
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                              onPressed: onNavigateToNotifications,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: AppColors.accentWarm,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryTint, width: 2),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/hostel_food_hero.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 2. Dark Forest Green Hero Banner matching Reference 1 (Screen 4)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    children: [
                      // Subtle decorative background circle
                      Positioned(
                        right: -30,
                        bottom: -40,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.04),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            // Text & CTA
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.timer_outlined, size: 12, color: AppColors.saffronLight),
                                            const SizedBox(width: 4),
                                            Text(
                                              'CLOSES AT 12:00 AM',
                                              style: AppTypography.labelSmall.copyWith(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "Don't forget to book tomorrow's meals",
                                    style: AppTypography.titleLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      height: 1.25,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Lock in breakfast, lunch & dinner now',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    ),
                                    onPressed: onNavigateToBooking,
                                    icon: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    label: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Cut-out circular food image
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/lunch_thali.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // 3. Today's Menu Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's Menu",
                        style: AppTypography.titleLarge.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        todayFormatted,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.successSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.successDark),
                        const SizedBox(width: 4),
                        Text(
                          'PUBLISHED',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.successDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (menuState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  ),
                )
              else ...[
                // Breakfast Card
                _buildMealCard(
                  context: context,
                  mealSlot: 'Breakfast',
                  timeSlot: '7:30 AM – 9:30 AM',
                  badgeColor: AppColors.breakfast,
                  badgeBg: AppColors.breakfastBg,
                  menu: menuState.todayMeals?.breakfast,
                  price: menuState.prices.breakfast,
                  defaultTitle: 'South Indian Delight',
                  defaultDesc: 'Idli, medu vada, vegetable sambar, coconut chutney, filter coffee',
                  dietaryTag: 'High Protein • Vegetarian',
                ),
                const SizedBox(height: 14),

                // Lunch Card
                _buildMealCard(
                  context: context,
                  mealSlot: 'Lunch',
                  timeSlot: '12:30 PM – 2:30 PM',
                  badgeColor: AppColors.lunch,
                  badgeBg: AppColors.lunchBg,
                  menu: menuState.todayMeals?.lunch,
                  price: menuState.prices.lunch,
                  defaultTitle: 'Royal Thali Feast',
                  defaultDesc: 'Paneer butter masala, dal tadka, aromatic jeera rice, soft roti, salad',
                  dietaryTag: 'Wholesome • Vegetarian',
                ),
                const SizedBox(height: 14),

                // Dinner Card
                _buildMealCard(
                  context: context,
                  mealSlot: 'Dinner',
                  timeSlot: '7:30 PM – 9:30 PM',
                  badgeColor: AppColors.dinner,
                  badgeBg: AppColors.dinnerBg,
                  menu: menuState.todayMeals?.dinner,
                  price: menuState.prices.dinner,
                  defaultTitle: 'Comfort Biryani Dinner',
                  defaultDesc: 'Fragrant dum biryani, cucumber raita, crunchy papad, gulab jamun',
                  dietaryTag: 'Comfort • Wholesome',
                ),
              ],

              const SizedBox(height: 24),

              // 4. Pre-Book Tomorrow's Meals Persistent Bottom Strip
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primarySubtle,
                      AppColors.surfaceHighlight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primaryTint),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: onNavigateToBooking,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.bookmark_add_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pre-Book Tomorrow's Meals",
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Lock in your preference before 12:00 AM IST',
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryDark, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCard({
    required BuildContext context,
    required String mealSlot,
    required String timeSlot,
    required Color badgeColor,
    required Color badgeBg,
    required MenuModel? menu,
    required double price,
    required String defaultTitle,
    required String defaultDesc,
    required String dietaryTag,
  }) {
    final title = menu?.title.isNotEmpty == true ? menu!.title : defaultTitle;
    final desc = menu?.description?.isNotEmpty == true ? menu!.description! : defaultDesc;
    final tags = menu?.dietaryTags?.isNotEmpty == true ? menu!.dietaryTags! : dietaryTag;

    return CardContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 18,
      onTap: () {
        // Show rich meal detail modal on tap
        final modalMenu = menu ??
            MenuModel(
              id: 0,
              date: '',
              mealType: mealSlot.toLowerCase(),
              title: title,
              description: desc,
              dietaryTags: tags,
              isPublished: true,
              dishes: [
                DishModel(id: 1, name: 'Primary Course - Chef Special', category: 'Main'),
                DishModel(id: 2, name: 'Side Accompaniment & Salad', category: 'Side'),
                DishModel(id: 3, name: 'Hot Beverage / Dessert', category: 'Beverage'),
              ],
            );
        MealDetailModal.show(
          context,
          menu: modalMenu,
          price: price,
          onBookNow: onNavigateToBooking,
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Food Image Thumbnail (80x80 rounded)
          FoodImage(
            mealType: mealSlot,
            width: 82,
            height: 82,
            borderRadius: 14,
          ),
          const SizedBox(width: 14),
          // Right: Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$mealSlot • $timeSlot',
                        style: AppTypography.labelSmall.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tags,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: AppColors.primaryMedium,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
