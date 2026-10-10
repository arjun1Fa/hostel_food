import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../../student/models/menu_model.dart';
import '../state/admin_controllers.dart';

class AdminMenusScreen extends ConsumerStatefulWidget {
  const AdminMenusScreen({super.key});

  @override
  ConsumerState<AdminMenusScreen> createState() => _AdminMenusScreenState();
}

class _AdminMenusScreenState extends ConsumerState<AdminMenusScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); // Default tomorrow
  int _selectedMealIndex = 0; // 0: Breakfast, 1: Lunch, 2: Dinner

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();
  final _newDishController = TextEditingController();
  bool _isPublished = true;

  final List<Map<String, dynamic>> _dishes = [];

  String get _dateStr => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _currentMealType => ['BREAKFAST', 'LUNCH', 'DINNER'][_selectedMealIndex];

  @override
  void initState() {
    super.initState();
    _syncFormWithState();
  }

  void _syncFormWithState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(adminMenuDateProvider(_dateStr));
      state.whenData((meals) {
        MenuModel? menu;
        if (_selectedMealIndex == 0) menu = meals.breakfast;
        if (_selectedMealIndex == 1) menu = meals.lunch;
        if (_selectedMealIndex == 2) menu = meals.dinner;

        if (menu != null) {
          _titleController.text = menu.title;
          _descController.text = menu.description ?? '';
          _tagsController.text = menu.dietaryTags ?? '';
          _isPublished = menu.isPublished;
          _dishes.clear();
          for (var d in menu.dishes) {
            _dishes.add({
              'name': d.name,
              'category': d.category ?? 'Main',
              'is_vegetarian': d.isVegetarian,
            });
          }
        } else {
          _titleController.text = '';
          _descController.text = '';
          _tagsController.text = '';
          _isPublished = false;
          _dishes.clear();
        }
        if (mounted) setState(() {});
      });
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _syncFormWithState();
    }
  }

  void _addDish() {
    final text = _newDishController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _dishes.add({'name': text, 'category': 'Main', 'is_vegetarian': true});
      _newDishController.clear();
    });
  }

  Future<void> _handleSave() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a menu title.')),
      );
      return;
    }

    final success = await ref.read(adminMenuDateProvider(_dateStr).notifier).saveMenu(
          mealType: _currentMealType,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          dietaryTags: _tagsController.text.trim(),
          isPublished: _isPublished,
          dishes: _dishes,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Menu saved successfully!' : 'Failed to save menu.'),
          backgroundColor: success ? AppColors.primary : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateDisplay = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Pick Date',
            onPressed: _pickDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Selector Bar
            CardContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, color: AppColors.primary, size: 20),
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

            const SizedBox(height: 16),

            // Meal Type Segmented Selector
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Breakfast'), icon: Icon(Icons.wb_sunny_outlined, size: 16)),
                ButtonSegment(value: 1, label: Text('Lunch'), icon: Icon(Icons.wb_twilight_rounded, size: 16)),
                ButtonSegment(value: 2, label: Text('Dinner'), icon: Icon(Icons.nightlight_round, size: 16)),
              ],
              selected: {_selectedMealIndex},
              onSelectionChanged: (set) {
                setState(() => _selectedMealIndex = set.first);
                _syncFormWithState();
              },
            ),

            const SizedBox(height: 20),

            // Menu Editor Card
            CardContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Editing $_currentMealType',
                        style: AppTypography.titleLarge.copyWith(fontSize: 16),
                      ),
                      Row(
                        children: [
                          Text(
                            _isPublished ? 'Published (Live)' : 'Draft (Hidden)',
                            style: AppTypography.labelSmall.copyWith(
                              color: _isPublished ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Switch(
                            value: _isPublished,
                            activeColor: AppColors.primary,
                            onChanged: (val) => setState(() => _isPublished = val),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Menu Title *',
                    hint: 'e.g. Punjabi Rajma Chawal Special',
                    controller: _titleController,
                  ),

                  const SizedBox(height: 14),

                  CustomTextField(
                    label: 'Description',
                    hint: 'Aromatic basmati rice with slow cooked rajma and raita...',
                    controller: _descController,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 14),

                  CustomTextField(
                    label: 'Dietary & Allergen Tags',
                    hint: 'e.g. Vegetarian, High Protein, Contains Dairy',
                    controller: _tagsController,
                  ),

                  const SizedBox(height: 20),

                  // Dishes Section
                  Text(
                    'Dishes in this Menu',
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newDishController,
                          decoration: InputDecoration(
                            hintText: 'Add a dish (e.g. Dal Makhani, Paneer Tikka)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onSubmitted: (_) => _addDish(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _addDish,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_dishes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'No dishes added yet. Type a dish name above and click Add.',
                        style: AppTypography.bodyMedium.copyWith(fontStyle: FontStyle.italic, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._dishes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final d = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco_rounded, size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d['name'],
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
                              onPressed: () => setState(() => _dishes.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 24),

                  CustomButton(
                    text: 'Save Menu ($_currentMealType)',
                    onPressed: _handleSave,
                    height: 48,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
