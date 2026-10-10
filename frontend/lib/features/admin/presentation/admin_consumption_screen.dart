import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/empty_state.dart';
import '../state/admin_controllers.dart';

class AdminConsumptionScreen extends ConsumerStatefulWidget {
  const AdminConsumptionScreen({super.key});

  @override
  ConsumerState<AdminConsumptionScreen> createState() => _AdminConsumptionScreenState();
}

class _AdminConsumptionScreenState extends ConsumerState<AdminConsumptionScreen> {
  DateTime _selectedDate = DateTime.now(); // Default today

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 5)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _toggleConsumption(int userId, String mealType, bool currentVal) async {
    final success = await ref.read(adminConsumptionProvider(_dateStr).notifier).recordSingle(
          userId: userId,
          mealType: mealType,
          consumed: !currentVal,
          reason: 'Recorded via consumption manager',
        );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to record consumption.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final consumptionAsync = ref.watch(adminConsumptionProvider(_dateStr));
    final dateDisplay = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Actual Consumption'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(adminConsumptionProvider(_dateStr).notifier).loadConsumption(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Selector Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CardContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(dateDisplay, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                    ],
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.edit_calendar_rounded, size: 16),
                    label: const Text('Change Date'),
                    onPressed: _pickDate,
                  ),
                ],
              ),
            ),
          ),

          // Operational Instruction Notice
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap meal checkboxes to mark actual consumption. Charges will freeze at applicable rates and reflect on student expenses.',
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: consumptionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (data) {
                final List<dynamic> students = data['students'] ?? [];

                if (students.isEmpty) {
                  return const EmptyState(
                    icon: Icons.group_off_rounded,
                    title: 'No Active Students',
                    description: 'No registered students found in this hostel.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final s = students[idx];
                    final int userId = s['user_id'];
                    final String name = s['full_name'] ?? 'Student #$userId';
                    final String room = s['room_number'] ?? '-';

                    final bData = s['breakfast'];
                    final lData = s['lunch'];
                    final dData = s['dinner'];

                    final bool bConsumed = bData['consumed'] ?? false;
                    final bool lConsumed = lData['consumed'] ?? false;
                    final bool dConsumed = dData['consumed'] ?? false;

                    final bool bBooked = bData['booked'] ?? false;
                    final bool lBooked = lData['booked'] ?? false;
                    final bool dBooked = dData['booked'] ?? false;

                    final double totalStudentCharge =
                        (bConsumed ? (bData['price'] as num).toDouble() : 0.0) +
                        (lConsumed ? (lData['price'] as num).toDouble() : 0.0) +
                        (dConsumed ? (dData['price'] as num).toDouble() : 0.0);

                    return CardContainer(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                                  Text('Room $room', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: totalStudentCharge > 0 ? AppColors.successSubtle : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Charged: ₹${totalStudentCharge.toStringAsFixed(0)}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: totalStudentCharge > 0 ? AppColors.success : AppColors.textMuted,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: AppColors.cardBorder),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildConsumptionToggle(
                                mealName: 'Breakfast',
                                booked: bBooked,
                                consumed: bConsumed,
                                price: (bData['price'] as num).toDouble(),
                                onTap: () => _toggleConsumption(userId, 'BREAKFAST', bConsumed),
                              ),
                              _buildConsumptionToggle(
                                mealName: 'Lunch',
                                booked: lBooked,
                                consumed: lConsumed,
                                price: (lData['price'] as num).toDouble(),
                                onTap: () => _toggleConsumption(userId, 'LUNCH', lConsumed),
                              ),
                              _buildConsumptionToggle(
                                mealName: 'Dinner',
                                booked: dBooked,
                                consumed: dConsumed,
                                price: (dData['price'] as num).toDouble(),
                                onTap: () => _toggleConsumption(userId, 'DINNER', dConsumed),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionToggle({
    required String mealName,
    required bool booked,
    required bool consumed,
    required double price,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: consumed ? AppColors.successSubtle : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: consumed ? AppColors.success : AppColors.cardBorder,
            width: consumed ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  consumed ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 18,
                  color: consumed ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  mealName,
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: consumed ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              booked ? 'Booked (₹${price.toInt()})' : 'Not Booked',
              style: TextStyle(
                fontSize: 10,
                color: booked ? AppColors.textSecondary : AppColors.textMuted,
                fontStyle: booked ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
