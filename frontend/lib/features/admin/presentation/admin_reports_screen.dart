import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../state/admin_controllers.dart';
import '../models/admin_models.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Default tomorrow

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
            title: Text('CSV Export Generated', style: AppTypography.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('File: ${reportType}_$_dateStr.csv', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  height: 180,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
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
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetAsync = ref.watch(kitchenPrepSheetProvider(_dateStr));
    final dateDisplay = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kitchen Prep Sheet & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(kitchenPrepSheetProvider(_dateStr)),
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
                      const Icon(Icons.print_rounded, color: AppColors.primary, size: 20),
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

          // Export Actions Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined, size: 16),
                    label: const Text('Export Prep CSV'),
                    onPressed: () => _exportCsv('kitchen_prep'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.table_view_outlined, size: 16),
                    label: const Text('Export Charges CSV'),
                    onPressed: () => _exportCsv('consumption'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: sheetAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(child: Text('Error loading report: $err')),
              data: (sheet) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Print Header Banner
                      CardContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sheet.hostelName,
                                  style: AppTypography.titleLarge.copyWith(fontSize: 18),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${sheet.totalBookingsDay} Total Meals',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Daily Kitchen Preparation Sheet • Target Date: ${sheet.date}',
                              style: AppTypography.bodyMedium,
                            ),
                            Text(
                              'Active Students in Hostel: ${sheet.totalActiveStudents}',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text('Portions & Menu Breakdown', style: AppTypography.titleLarge),
                      const SizedBox(height: 10),

                      ...sheet.items.map((item) => _buildPrepCard(item)),

                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepCard(KitchenPrepItemModel item) {
    BadgeType bType = BadgeType.breakfast;
    if (item.mealType == 'LUNCH') bType = BadgeType.lunch;
    if (item.mealType == 'DINNER') bType = BadgeType.dinner;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: CardContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StatusBadge(label: item.mealType, type: bType),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_alt_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${item.totalPortions} Portions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.menuTitle ?? 'Menu Pending Publication',
              style: AppTypography.titleLarge.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 10),
            if (item.dishNames.isNotEmpty) ...[
              Text(
                'Kitchen Dish Preparation List:',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              ...item.dishNames.map(
                (dish) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        dish,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Text(
                'No dishes entered for this meal slot yet.',
                style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic, color: AppColors.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
