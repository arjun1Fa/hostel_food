import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/food_image.dart';
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
  String get _currentMealType => ['breakfast', 'lunch', 'dinner'][_selectedMealIndex];

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
              'category': 'Main',
              'is_vegetarian': true,
            });
          }
        } else {
          // Defaults for demo
          if (_selectedMealIndex == 0) {
            _titleController.text = 'South Indian Delight';
            _descController.text = 'Steamed rice idli, crispy medu vada, sambar, chutney & filter coffee';
            _tagsController.text = 'High Protein, Vegetarian';
            _dishes.clear();
            _dishes.addAll([
              {'name': 'Steamed Rice Idli', 'category': 'Main', 'is_vegetarian': true},
              {'name': 'Crispy Medu Vada', 'category': 'Main', 'is_vegetarian': true},
              {'name': 'Vegetable Sambar', 'category': 'Side', 'is_vegetarian': true},
              {'name': 'Coconut Chutney', 'category': 'Side', 'is_vegetarian': true},
            ]);
          } else if (_selectedMealIndex == 1) {
            _titleController.text = 'Royal Thali Feast';
            _descController.text = 'Paneer butter masala, dal tadka, jeera rice, soft roti & salad';
            _tagsController.text = 'Vegetarian, Wholesome';
            _dishes.clear();
            _dishes.addAll([
              {'name': 'Paneer Butter Masala', 'category': 'Main', 'is_vegetarian': true},
              {'name': 'Yellow Dal Tadka', 'category': 'Side', 'is_vegetarian': true},
              {'name': 'Jeera Rice', 'category': 'Main', 'is_vegetarian': true},
              {'name': 'Tawa Roti', 'category': 'Bread', 'is_vegetarian': true},
            ]);
          } else {
            _titleController.text = 'Comfort Biryani Dinner';
            _descController.text = 'Fragrant veg dum biryani, cucumber raita, crunchy roasted papad & dessert';
            _tagsController.text = 'Comfort, Wholesome';
            _dishes.clear();
            _dishes.addAll([
              {'name': 'Vegetable Dum Biryani', 'category': 'Main', 'is_vegetarian': true},
              {'name': 'Cucumber Raita', 'category': 'Side', 'is_vegetarian': true},
              {'name': 'Roasted Papad', 'category': 'Side', 'is_vegetarian': true},
              {'name': 'Gulab Jamun', 'category': 'Dessert', 'is_vegetarian': true},
            ]);
          }
          _isPublished = true;
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
      ref.invalidate(adminDashboardProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Menu published successfully for $_dateStr!' : 'Failed to save menu.'),
          backgroundColor: success ? AppColors.primaryDark : AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfter = today.add(const Duration(days: 2));

    final dateDisplay = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menu Management',
                      style: AppTypography.displayMedium.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Curate and publish nutritious meals for hostel students',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: _handleSave,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Save & Publish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Date Navigation Pills matching Reference 1 (Image 10) & Reference 3 (Image 7)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDatePill(
                    label: 'Today (${DateFormat('d MMM').format(today)})',
                    date: today,
                  ),
                  const SizedBox(width: 8),
                  _buildDatePill(
                    label: 'Tomorrow (${DateFormat('d MMM').format(tomorrow)})',
                    date: tomorrow,
                  ),
                  const SizedBox(width: 8),
                  _buildDatePill(
                    label: DateFormat('EEE, d MMM').format(dayAfter),
                    date: dayAfter,
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primaryDark),
                    label: Text(
                      DateFormat('d MMM yyyy').format(_selectedDate),
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Meal Slot Toggle Pills (Breakfast, Lunch, Dinner)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  _buildMealSlotTab(0, 'Breakfast', '7:30 – 9:30 AM', Icons.wb_sunny_rounded, AppColors.breakfast),
                  _buildMealSlotTab(1, 'Lunch', '12:30 – 2:30 PM', Icons.lunch_dining_rounded, AppColors.lunch),
                  _buildMealSlotTab(2, 'Dinner', '7:30 – 9:30 PM', Icons.nightlight_round, AppColors.dinner),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Visual Food Header & Live Preview Card
            CardContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FoodImage(
                        mealType: _currentMealType,
                        width: 100,
                        height: 100,
                        borderRadius: 16,
                      ),
                      const SizedBox(width: 16),
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
                                    color: _isPublished ? AppColors.successSubtle : AppColors.warningSubtle,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _isPublished ? 'PUBLISHED' : 'DRAFT',
                                    style: TextStyle(
                                      color: _isPublished ? AppColors.successDark : AppColors.warning,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text('Publish', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 6),
                                    Switch(
                                      value: _isPublished,
                                      activeColor: AppColors.primaryDark,
                                      onChanged: (val) => setState(() => _isPublished = val),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _titleController.text.isNotEmpty ? _titleController.text : 'New Menu',
                              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateDisplay,
                              style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24, color: AppColors.cardBorder),

                  // Menu Form Fields
                  Text('Menu Title', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _titleController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. South Indian Delight, Royal Thali Feast',
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text('Description / Chef Note', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Wholesome steamed idli with slow-simmered drumstick sambar and fresh chutney.',
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text('Dietary Tags (comma separated)', style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _tagsController,
                    decoration: const InputDecoration(
                      hintText: 'Vegetarian, High Protein, Gluten Free',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Dish List Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Included Dishes & Items (${_dishes.length})',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newDishController,
                          onSubmitted: (_) => _addDish(),
                          decoration: const InputDecoration(
                            hintText: 'Type dish name (e.g. Crispy Medu Vada)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: _addDish,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add Dish'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _dishes.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final dish = entry.value;
                      return Chip(
                        backgroundColor: AppColors.surfaceMuted,
                        side: const BorderSide(color: AppColors.cardBorder),
                        avatar: const Icon(Icons.restaurant_rounded, size: 14, color: AppColors.primaryDark),
                        label: Text(
                          dish['name'] as String,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 14),
                        onDeleted: () => setState(() => _dishes.removeAt(idx)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePill({required String label, required DateTime date}) {
    final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(date);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() => _selectedDate = date);
        _syncFormWithState();
      },
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

  Widget _buildMealSlotTab(int index, String title, String time, IconData icon, Color color) {
    final isSelected = _selectedMealIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          setState(() => _selectedMealIndex = index);
          _syncFormWithState();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 14, color: isSelected ? color : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
