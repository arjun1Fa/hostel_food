import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../state/admin_controllers.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedFrequency = 'Daily'; // Daily, Monthly, Custom

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _exportCsv(String reportType) async {
    try {
      final res = await apiClient.dio.get(
        '${ApiConstants.exportCsv}?target_date=$_dateStr&report_type=$reportType',
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.download_done_rounded, color: AppColors.successDark),
                const SizedBox(width: 10),
                Text('CSV Export Ready', style: AppTypography.titleLarge),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filename: ${reportType}_$_dateStr.csv', style: AppTypography.labelSmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  height: 180,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      res.data.toString(),
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export report: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateFormat('d MMMM yyyy').format(_selectedDate);
    final prepAsync = ref.watch(kitchenPrepSheetProvider(_dateStr));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reports & Analytics',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Operational meal metrics and financial performance',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () => _exportCsv('financial_daily'),
                  icon: const Icon(Icons.file_download_outlined, size: 16),
                  label: const Text('Export CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Frequency Filter Pills (Daily, Monthly, Custom)
            Row(
              children: [
                _buildFreqPill('Daily'),
                const SizedBox(width: 8),
                _buildFreqPill('Monthly'),
                const SizedBox(width: 8),
                _buildFreqPill('Custom'),
                const Spacer(),
                // Date Navigator `< Date >`
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                      ),
                      InkWell(
                        onTap: _pickDate,
                        child: Text(
                          dateDisplay,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Grouped Bar Chart matching Reference 1 (Image 12) & Reference 2 (Image 13)
            CardContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Meal Summary',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      Row(
                        children: [
                          _buildLegendDot('Booked', AppColors.primaryMedium),
                          const SizedBox(width: 14),
                          _buildLegendDot('Consumed', AppColors.accentWarm),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Grouped Bars for Breakfast, Lunch, Dinner
                  SizedBox(
                    height: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMealBarGroup('Breakfast', 92, 76),
                        _buildMealBarGroup('Lunch', 118, 102),
                        _buildMealBarGroup('Dinner', 96, 84),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Financial Summary Card
            CardContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial & Operational Summary',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  _buildFinancialRow('Total Meals Consumed', '262 portions', false),
                  const Divider(height: 20, color: AppColors.cardBorder),
                  _buildFinancialRow('Total Daily Charges', '₹10,480', true),
                  const Divider(height: 20, color: AppColors.cardBorder),
                  _buildFinancialRow('Average Charge per Student', '₹78', false),
                  const Divider(height: 20, color: AppColors.cardBorder),
                  _buildFinancialRow('Pre-Book Waste Prevented', '32 unserved portions', false),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Kitchen Preparation Sheet
            prepAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.primaryDark))),
              error: (err, _) => const SizedBox.shrink(),
              data: (sheet) {
                return CardContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Kitchen Preparation Requirements', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text('for ${sheet.totalBookingsDay} meals', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (sheet.items.isEmpty)
                        Text('Kitchen preparation requirements will be generated once bookings are placed.', style: AppTypography.bodyMedium)
                      else
                        ...sheet.items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.soup_kitchen_rounded, size: 16, color: AppColors.primaryMedium),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.mealType.toUpperCase(), style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                        if (item.menuTitle != null)
                                          Text(item.menuTitle!, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${item.totalPortions} portions',
                                    style: AppTypography.labelSmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqPill(String label) {
    final isSelected = _selectedFrequency == label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFrequency = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primaryDark : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _buildMealBarGroup(String meal, int booked, int consumed) {
    const double maxHeight = 100.0;
    final double bookedHeight = (booked / 134.0 * maxHeight).clamp(20.0, maxHeight);
    final double consumedHeight = (consumed / 134.0 * maxHeight).clamp(16.0, maxHeight);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Booked Bar
            Column(
              children: [
                Text('$booked', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryMedium)),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: bookedHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primaryMedium,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Consumed Bar
            Column(
              children: [
                Text('$consumed', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.accentWarm)),
                const SizedBox(height: 4),
                Container(
                  width: 20,
                  height: consumedHeight,
                  decoration: BoxDecoration(
                    color: AppColors.accentWarm,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(meal, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 11)),
      ],
    );
  }

  Widget _buildFinancialRow(String title, String val, bool isHighlight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
        Text(
          val,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: isHighlight ? 18 : 14,
            color: isHighlight ? AppColors.primaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
