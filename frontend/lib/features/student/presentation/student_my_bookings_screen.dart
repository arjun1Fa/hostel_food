import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/food_image.dart';
import '../state/student_controllers.dart';
import '../models/menu_model.dart';

class StudentMyBookingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToBooking;

  const StudentMyBookingsScreen({
    super.key,
    required this.onNavigateToBooking,
  });

  @override
  ConsumerState<StudentMyBookingsScreen> createState() => _StudentMyBookingsScreenState();
}

class _StudentMyBookingsScreenState extends ConsumerState<StudentMyBookingsScreen> with SingleTickerProviderStateMixin {
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
    final myBookingsAsync = ref.watch(myBookingsProvider);
    final bookingState = ref.watch(studentBookingProvider);
    final menuState = ref.watch(studentMenuProvider);

    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(tomorrow);
    final tomorrowFormatted = DateFormat('d MMM yyyy').format(tomorrow);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Bookings', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
            Text('Your meal plans and reservation history', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
          ],
        ),
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
                Tab(text: 'Upcoming'),
                Tab(text: 'Past History'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Upcoming Tab
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myBookingsProvider);
              await ref.read(studentBookingProvider.notifier).loadTomorrowBooking();
            },
            color: AppColors.primaryDark,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tomorrow's card
                  _buildTomorrowCard(
                    context: context,
                    dateText: tomorrowFormatted,
                    bookingState: bookingState,
                    prices: menuState.prices,
                  ),

                  const SizedBox(height: 18),

                  // Day after tomorrow preview
                  _buildFuturePlaceholderCard(
                    dateText: DateFormat('EEEE, d MMM yyyy').format(tomorrow.add(const Duration(days: 1))),
                  ),
                ],
              ),
            ),
          ),

          // 2. Past History Tab
          myBookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
            error: (err, stack) => Center(
              child: Text('Could not load past bookings.', style: AppTypography.bodyMedium),
            ),
            data: (bookings) {
              final past = bookings.where((b) => b.date != tomorrowStr).toList();
              if (past.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bookmark_border_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No Past Bookings Yet', style: AppTypography.titleMedium),
                        const SizedBox(height: 4),
                        Text('Your previous bookings and attendance will appear here.', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: past.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final b = past[index];
                  return CardContainer(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.calendar_month_rounded, color: AppColors.primaryDark, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.date,
                                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (b.breakfastBooked) 'Breakfast',
                                  if (b.lunchBooked) 'Lunch',
                                  if (b.dinnerBooked) 'Dinner',
                                ].join(' • '),
                                style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${b.estimatedCost.toStringAsFixed(0)}',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTomorrowCard({
    required BuildContext context,
    required String dateText,
    required StudentBookingState bookingState,
    required MealPricesModel prices,
  }) {
    final hasBookings = bookingState.draftBreakfast || bookingState.draftLunch || bookingState.draftDinner;
    final total = bookingState.calculateEstimatedCost(prices);

    return CardContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      border: Border.all(color: hasBookings ? AppColors.primaryMedium.withOpacity(0.4) : AppColors.cardBorder),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tomorrow', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                  Text(dateText, style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasBookings ? AppColors.successSubtle : AppColors.warningSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasBookings ? 'CONFIRMED' : 'NOT BOOKED',
                  style: AppTypography.labelSmall.copyWith(
                    color: hasBookings ? AppColors.successDark : AppColors.warning,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.cardBorder),
          if (hasBookings) ...[
            if (bookingState.draftBreakfast)
              _buildBookedRow('Breakfast', 'South Indian Delight', prices.breakfast, 'breakfast'),
            if (bookingState.draftLunch)
              _buildBookedRow('Lunch', 'Royal Thali Feast', prices.lunch, 'lunch'),
            if (bookingState.draftDinner)
              _buildBookedRow('Dinner', 'Comfort Biryani Dinner', prices.dinner, 'dinner'),
            const Divider(height: 20, color: AppColors.cardBorder),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Estimated Cost', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text('₹${total.toStringAsFixed(0)}', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
              ],
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'You have not pre-booked any meals for tomorrow yet.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                side: const BorderSide(color: AppColors.accent),
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: widget.onNavigateToBooking,
              icon: const Icon(Icons.edit_calendar_rounded, size: 16),
              label: Text(
                hasBookings ? 'Modify before 12:00 AM' : 'Book Meals for Tomorrow',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedRow(String slot, String title, double price, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          FoodImage(mealType: type, width: 44, height: 44, borderRadius: 10),
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

  Widget _buildFuturePlaceholderCard({required String dateText}) {
    return CardContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateText, style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('UPCOMING', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bookings for this date will open tomorrow.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
