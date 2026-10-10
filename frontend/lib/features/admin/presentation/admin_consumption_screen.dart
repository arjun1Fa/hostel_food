import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../state/admin_controllers.dart';

class AdminConsumptionScreen extends ConsumerStatefulWidget {
  const AdminConsumptionScreen({super.key});

  @override
  ConsumerState<AdminConsumptionScreen> createState() => _AdminConsumptionScreenState();
}

class _AdminConsumptionScreenState extends ConsumerState<AdminConsumptionScreen> {
  DateTime _selectedDate = DateTime.now(); // Default today
  int _selectedMealIndex = 1; // 0: Breakfast, 1: Lunch, 2: Dinner
  String _searchQuery = '';

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _currentMealType => ['BREAKFAST', 'LUNCH', 'DINNER'][_selectedMealIndex];

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

  Future<void> _toggleConsumption(int userId, bool markConsumed) async {
    final success = await ref.read(adminConsumptionProvider(_dateStr).notifier).recordSingle(
          userId: userId,
          mealType: _currentMealType,
          consumed: markConsumed,
          reason: 'Recorded via consumption manager',
        );

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update consumption status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final consumptionAsync = ref.watch(adminConsumptionProvider(_dateStr));
    final dateDisplay = DateFormat('d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header & Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark Consumption',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Record attendance and freeze consumption-based dining charges',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref.read(adminConsumptionProvider(_dateStr).notifier).loadConsumption(),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Date & Meal Switcher Row
                Row(
                  children: [
                    // Date button
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primaryDark),
                      label: Text(
                        dateDisplay,
                        style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Meal Tabs (Breakfast, Lunch, Dinner)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            _buildMealTab(0, 'Breakfast'),
                            _buildMealTab(1, 'Lunch'),
                            _buildMealTab(2, 'Dinner'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search students by name or room number...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                ),
              ],
            ),
          ),

          // Content List
          Expanded(
            child: consumptionAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (data) {
                final List<dynamic> allStudents = data['students'] ?? [];
                final mealKey = _currentMealType.toLowerCase();

                final filtered = allStudents.where((s) {
                  final name = (s['full_name'] as String? ?? '').toLowerCase();
                  final room = (s['room_number'] as String? ?? '').toLowerCase();
                  if (_searchQuery.isEmpty) return true;
                  return name.contains(_searchQuery) || room.contains(_searchQuery);
                }).toList();

                int totalBooked = 0;
                int totalConsumed = 0;
                double totalAmount = 0.0;

                for (var s in allStudents) {
                  final m = s[mealKey];
                  if (m != null) {
                    if (m['booked'] == true) totalBooked++;
                    if (m['consumed'] == true) {
                      totalConsumed++;
                      totalAmount += (m['price'] as num? ?? 0.0).toDouble();
                    }
                  }
                }

                final pending = totalBooked - totalConsumed;

                return Column(
                  children: [
                    // Metrics Strip matching Reference 3 (Image 8)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildMetricBadge('$totalBooked', 'Booked', AppColors.primaryDark, AppColors.primarySubtle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricBadge('$totalConsumed', 'Consumed', AppColors.successDark, AppColors.successSubtle),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricBadge('${pending.clamp(0, 9999)}', 'Pending', AppColors.accentWarm, AppColors.accentSubtle),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Student List
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text('No students match your query.', style: AppTypography.bodyMedium),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final s = filtered[idx];
                                final int userId = s['user_id'];
                                final String name = s['full_name'] ?? 'Student';
                                final String room = s['room_number'] ?? '-';
                                final mealInfo = s[mealKey] ?? {};

                                final bool isBooked = mealInfo['booked'] ?? false;
                                final bool isConsumed = mealInfo['consumed'] ?? false;
                                final double price = (mealInfo['price'] as num? ?? 40.0).toDouble();

                                return CardContainer(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  borderRadius: 14,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppColors.primarySubtle,
                                        child: Text(
                                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                          style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(name, style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                                            Text('Room $room', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 11)),
                                          ],
                                        ),
                                      ),
                                      // Booked indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isBooked ? AppColors.successSubtle : AppColors.surfaceMuted,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          isBooked ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                                          size: 16,
                                          color: isBooked ? AppColors.successDark : AppColors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Ate / Not Ate buttons
                                      Row(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () => _toggleConsumption(userId, true),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                              decoration: BoxDecoration(
                                                color: isConsumed ? AppColors.successDark : AppColors.surfaceMuted,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'Ate',
                                                style: TextStyle(
                                                  color: isConsumed ? Colors.white : AppColors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: () => _toggleConsumption(userId, false),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                              decoration: BoxDecoration(
                                                color: !isConsumed ? AppColors.accentWarm.withOpacity(0.2) : AppColors.surfaceMuted,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                'Not Ate',
                                                style: TextStyle(
                                                  color: !isConsumed ? AppColors.accentDark : AppColors.textMuted,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '₹${price.toStringAsFixed(0)}',
                                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primaryDark),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Sticky Bottom Summary Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        border: Border(top: BorderSide(color: AppColors.cardBorder)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text('Total Booked: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                              Text('$totalBooked', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                              const SizedBox(width: 16),
                              Text('Consumed: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                              Text('$totalConsumed', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.successDark)),
                            ],
                          ),
                          Row(
                            children: [
                              Text('Amount: ', style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary)),
                              Text('₹${totalAmount.toStringAsFixed(0)}', style: AppTypography.titleLarge.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.w800, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTab(int index, String label) {
    final isSelected = _selectedMealIndex == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _selectedMealIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricBadge(String value, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 11)),
        ],
      ),
    );
  }
}
