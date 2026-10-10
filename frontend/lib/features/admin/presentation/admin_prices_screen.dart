import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../state/admin_controllers.dart';

class AdminPricesScreen extends ConsumerStatefulWidget {
  const AdminPricesScreen({super.key});

  @override
  ConsumerState<AdminPricesScreen> createState() => _AdminPricesScreenState();
}

class _AdminPricesScreenState extends ConsumerState<AdminPricesScreen> {
  final _bPriceController = TextEditingController();
  final _lPriceController = TextEditingController();
  final _dPriceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final prices = ref.read(adminPricesProvider).value;
    if (prices != null) {
      _bPriceController.text = prices.breakfast.toStringAsFixed(0);
      _lPriceController.text = prices.lunch.toStringAsFixed(0);
      _dPriceController.text = prices.dinner.toStringAsFixed(0);
    }
  }

  Future<void> _handleSave() async {
    final b = double.tryParse(_bPriceController.text.trim());
    final l = double.tryParse(_lPriceController.text.trim());
    final d = double.tryParse(_dPriceController.text.trim());

    if (b == null || l == null || d == null || b < 0 || l < 0 || d < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid non-negative meal prices.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final success = await ref.read(adminPricesProvider.notifier).updatePrices(b, l, d);
    setState(() => _isSaving = false);

    if (mounted) {
      ref.invalidate(priceHistoryProvider);
      ref.invalidate(adminDashboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Meal prices updated successfully!' : 'Failed to update prices.'),
          backgroundColor: success ? AppColors.primaryDark : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(adminPricesProvider);
    final historyAsync = ref.watch(priceHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pricesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
        error: (err, _) => Center(child: Text('Error loading prices: $err')),
        data: (prices) {
          if (_bPriceController.text.isEmpty) {
            _bPriceController.text = prices.breakfast.toStringAsFixed(0);
            _lPriceController.text = prices.lunch.toStringAsFixed(0);
            _dPriceController.text = prices.dinner.toStringAsFixed(0);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header matching Reference 2 (Image 11)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meal Prices',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Configure operational rates and audit price revisions',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Current Prices Card
                CardContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Meal Rates',
                        style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Updates will apply to all subsequent bookings and consumption calculations.',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),

                      _buildPriceRow(
                        label: 'Breakfast Rate',
                        icon: Icons.wb_sunny_rounded,
                        color: AppColors.breakfast,
                        bg: AppColors.breakfastBg,
                        controller: _bPriceController,
                      ),
                      const Divider(height: 22, color: AppColors.cardBorder),
                      _buildPriceRow(
                        label: 'Lunch Rate',
                        icon: Icons.lunch_dining_rounded,
                        color: AppColors.lunch,
                        bg: AppColors.lunchBg,
                        controller: _lPriceController,
                      ),
                      const Divider(height: 22, color: AppColors.cardBorder),
                      _buildPriceRow(
                        label: 'Dinner Rate',
                        icon: Icons.nightlight_round,
                        color: AppColors.dinner,
                        bg: AppColors.dinnerBg,
                        controller: _dPriceController,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Price History Audit Trail matching Reference 2 (Image 11)
                Text(
                  'Price History & Audit Trail',
                  style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 12),

                historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
                  error: (e, _) => Text('Could not load price history: $e'),
                  data: (history) {
                    if (history.isEmpty) {
                      return CardContainer(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No price modification logs found.',
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return CardContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: 18,
                      child: Column(
                        children: history.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySubtle,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.history_rounded, size: 16, color: AppColors.primaryDark),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item.mealType.toUpperCase()} updated from ₹${item.oldPrice.toInt()} to ₹${item.newPrice.toInt()}',
                                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        'Changed by Admin • ${item.changedAt.length > 10 ? item.changedAt.substring(0, 10) : item.changedAt}',
                                        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required IconData icon,
    required Color color,
    required Color bg,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Container(
          width: 110,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 10.0),
                child: Text('₹', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark)),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
