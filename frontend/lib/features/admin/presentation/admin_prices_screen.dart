import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Meal prices updated successfully!' : 'Failed to update prices.'),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
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
      appBar: AppBar(
        title: const Text('Meal Price Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(adminPricesProvider.notifier).loadPrices();
              ref.invalidate(priceHistoryProvider);
            },
          ),
        ],
      ),
      body: pricesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading prices: $err')),
        data: (prices) {
          if (_bPriceController.text.isEmpty) {
            _bPriceController.text = prices.breakfast.toStringAsFixed(0);
            _lPriceController.text = prices.lunch.toStringAsFixed(0);
            _dPriceController.text = prices.dinner.toStringAsFixed(0);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Price Update Form
                CardContainer(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text('Configure Active Rates (INR)', style: AppTypography.titleLarge.copyWith(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Changes take effect immediately for future consumption. Existing recorded charges will retain their frozen historical price snapshots.',
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Breakfast (₹)',
                              hint: '40',
                              controller: _bPriceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Lunch (₹)',
                              hint: '80',
                              controller: _lPriceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              label: 'Dinner (₹)',
                              hint: '70',
                              controller: _dPriceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      CustomButton(
                        text: 'Update Active Prices',
                        isLoading: _isSaving,
                        onPressed: _handleSave,
                        height: 48,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Price Audit History Table
                Text('Price Change Audit Trail', style: AppTypography.titleLarge),
                const SizedBox(height: 10),

                historyAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  error: (err, _) => Text('Could not load history: $err'),
                  data: (history) {
                    if (history.isEmpty) {
                      return CardContainer(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No price changes recorded yet. Initial rates active.',
                            style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      );
                    }

                    return CardContainer(
                      padding: EdgeInsets.zero,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.cardBorder),
                        itemBuilder: (context, idx) {
                          final h = history[idx];
                          DateTime dt;
                          try {
                            dt = DateTime.parse(h.changedAt);
                          } catch (_) {
                            dt = DateTime.now();
                          }
                          final dateStr = DateFormat('d MMM yyyy, h:mm a').format(dt);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                            ),
                            title: Text(
                              '${h.mealType}: ₹${h.oldPrice.toInt()} → ₹${h.newPrice.toInt()}',
                              style: AppTypography.titleMedium.copyWith(fontSize: 14),
                            ),
                            subtitle: Text(
                              'By ${h.changedByName ?? "Admin"} • $dateStr',
                              style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
