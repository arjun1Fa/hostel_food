import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../state/admin_controllers.dart';

class AdminBookingsScreen extends ConsumerStatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  ConsumerState<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends ConsumerState<AdminBookingsScreen> {
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

  void _showAdminOverrideDialog(Map<String, dynamic> studentBooking) {
    bool b = studentBooking['breakfast_booked'] ?? false;
    bool l = studentBooking['lunch_booked'] ?? false;
    bool d = studentBooking['dinner_booked'] ?? false;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Admin Booking Override', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student: ${studentBooking["user_name"] ?? "Student #${studentBooking["user_id"]}"} (Room ${studentBooking["room_number"] ?? "-"})',
                      style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Admins can override meal selections even past the midnight cutoff. All adjustments are logged in the audit trail.',
                      style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Breakfast', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: b,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) => setModalState(() => b = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Lunch', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: l,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) => setModalState(() => l = val ?? false),
                    ),
                    CheckboxListTile(
                      title: const Text('Dinner', style: TextStyle(fontWeight: FontWeight.bold)),
                      value: d,
                      activeColor: AppColors.primaryDark,
                      onChanged: (val) => setModalState(() => d = val ?? false),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Override Audit Reason *',
                        hintText: 'e.g. Authorized by hostel warden',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reason is mandatory for admin overrides.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    await _executeOverride(studentBooking['user_id'], b, l, d, reason);
                  },
                  child: const Text('Apply Override', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _executeOverride(int userId, bool b, bool l, bool d, String reason) async {
    try {
      await apiClient.dio.post(
        ApiConstants.adminBookingOverride,
        data: {
          'user_id': userId,
          'date': _dateStr,
          'breakfast_booked': b,
          'lunch_booked': l,
          'dinner_booked': d,
          'override_reason': reason,
        },
      );
      ref.invalidate(adminBookingsForDateProvider(_dateStr));
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking override applied & recorded in audit trail.'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to override booking: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(adminBookingsForDateProvider(_dateStr));
    final dateDisplay = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
        error: (err, _) => Center(child: Text('Error loading bookings: $err')),
        data: (data) {
          final int totalStudents = data['total_students'] ?? 0;
          final int bCount = data['breakfast_count'] ?? 0;
          final int lCount = data['lunch_count'] ?? 0;
          final int dCount = data['dinner_count'] ?? 0;
          final List<dynamic> studentsBooked = data['students_booked'] ?? [];

          return SingleChildScrollView(
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
                          'Bookings Oversight',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Track reservations, audit portion totals, and apply manager overrides',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref.invalidate(adminBookingsForDateProvider(_dateStr)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Date Picker Card
                CardContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  borderRadius: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, color: AppColors.primaryDark, size: 20),
                          const SizedBox(width: 10),
                          Text(dateDisplay, style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.accentWarm),
                        label: const Text('Change Date', style: TextStyle(color: AppColors.accentWarm, fontWeight: FontWeight.bold)),
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Portions Summary 3-Pills Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryPill('Breakfast', bCount, totalStudents, BadgeType.breakfast),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryPill('Lunch', lCount, totalStudents, BadgeType.lunch),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryPill('Dinner', dCount, totalStudents, BadgeType.dinner),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                Text('Student Selections (${studentsBooked.length})', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 12),

                if (studentsBooked.isEmpty)
                  const EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No Bookings for this Date',
                    description: 'No students have pre-booked meals for this date yet.',
                  )
                else
                  ...studentsBooked.map((b) {
                    final bool hasB = b['breakfast_booked'] ?? false;
                    final bool hasL = b['lunch_booked'] ?? false;
                    final bool hasD = b['dinner_booked'] ?? false;
                    final bool isOverridden = b['admin_override'] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: CardContainer(
                        padding: const EdgeInsets.all(14),
                        borderRadius: 16,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.primarySubtle,
                              foregroundColor: AppColors.primaryDark,
                              child: Text(
                                (b['user_name'] ?? 'S')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        b['user_name'] ?? 'Student #${b["user_id"]}',
                                        style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      if (b['room_number'] != null) ...[
                                        const SizedBox(width: 6),
                                        Text('• Room ${b["room_number"]}', style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted)),
                                      ],
                                      if (isOverridden) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.accentSubtle,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('OVERRIDDEN', style: TextStyle(fontSize: 9, color: AppColors.accentWarm, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _buildMealTag('Breakfast', hasB),
                                      _buildMealTag('Lunch', hasL),
                                      _buildMealTag('Dinner', hasD),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded, color: AppColors.primaryDark),
                              tooltip: 'Admin Override',
                              onPressed: () => _showAdminOverrideDialog(b as Map<String, dynamic>),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryPill(String name, int count, int total, BadgeType type) {
    return CardContainer(
      padding: const EdgeInsets.all(14),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusBadge(label: name, type: type),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: AppTypography.displayLarge.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
          ),
          Text(
            'of $total students',
            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMealTag(String name, bool isBooked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: isBooked ? AppColors.successSubtle : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isBooked ? AppColors.success.withOpacity(0.3) : AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBooked ? Icons.check_rounded : Icons.close_rounded,
            size: 12,
            color: isBooked ? AppColors.successDark : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isBooked ? AppColors.successDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
