import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../state/student_controllers.dart';
import '../models/notification_model.dart';

class StudentNotificationsScreen extends ConsumerStatefulWidget {
  const StudentNotificationsScreen({super.key});

  @override
  ConsumerState<StudentNotificationsScreen> createState() => _StudentNotificationsScreenState();
}

class _StudentNotificationsScreenState extends ConsumerState<StudentNotificationsScreen> {
  String _selectedCategory = 'All';
  bool _enable8Pm = true;
  bool _enable10Pm = true;

  Future<void> _triggerTestReminder(bool isFinal) async {
    try {
      final res = await apiClient.dio.post(
        '${ApiConstants.triggerReminders}?is_final=$isFinal',
      );
      if (res.statusCode == 200) {
        ref.read(studentNotificationsProvider.notifier).loadNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Triggered ${isFinal ? "10 PM Final" : "8 PM First"} reminder! Sent to ${res.data["sent_count"]} students.'),
              backgroundColor: AppColors.primaryDark,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger reminder: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(studentNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminders & Alerts', style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w800)),
            Text('Automated meal cutoffs and daily announcements', style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(studentNotificationsProvider.notifier).loadNotifications(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
        error: (err, _) => Center(child: Text('Error: $err', style: AppTypography.bodyMedium)),
        data: (notifications) {
          final filtered = notifications.where((n) {
            if (_selectedCategory == 'Booking') return n.type.toLowerCase().contains('booking') || n.title.toLowerCase().contains('booking');
            if (_selectedCategory == 'Menu') return n.type.toLowerCase().contains('menu') || n.title.toLowerCase().contains('menu');
            if (_selectedCategory == 'Other') return !n.type.toLowerCase().contains('booking') && !n.type.toLowerCase().contains('menu');
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(studentNotificationsProvider.notifier).loadNotifications(),
            color: AppColors.primaryDark,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Filter Chips (All, Booking, Menu, Other)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Booking', 'Menu', 'Other'].map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedCategory = cat),
                            selectedColor: AppColors.primaryDark,
                            backgroundColor: AppColors.surface,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(color: isSelected ? AppColors.primaryDark : AppColors.cardBorder),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Reminder Notification Settings Cards
                  CardContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notifications_active_rounded, color: AppColors.accentWarm, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Automated Reminders',
                              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // 8:00 PM Reminder Row
                        _buildReminderToggleRow(
                          title: '8:00 PM Reminder',
                          subtitle: "We'll notify you if you haven't booked tomorrow's meals.",
                          value: _enable8Pm,
                          color: AppColors.saffron,
                          onChanged: (val) => setState(() => _enable8Pm = val),
                          onTest: () => _triggerTestReminder(false),
                        ),

                        const Divider(height: 20, color: AppColors.cardBorder),

                        // 10:00 PM Reminder Row
                        _buildReminderToggleRow(
                          title: '10:00 PM Reminder',
                          subtitle: 'Final reminder before the midnight 12:00 AM cutoff.',
                          value: _enable10Pm,
                          color: AppColors.accentWarm,
                          onChanged: (val) => setState(() => _enable10Pm = val),
                          onTest: () => _triggerTestReminder(true),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Notification Stream Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Notifications',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${filtered.length} updates',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (filtered.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.textMuted),
                            const SizedBox(height: 10),
                            Text('No notifications found in this category.', style: AppTypography.bodyMedium),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filtered.map((n) => _buildNotificationTile(n)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReminderToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTest,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.alarm_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: value,
                      onChanged: onChanged,
                      activeColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              InkWell(
                onTap: onTest,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Text(
                    '⚡ Trigger Test Push',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.primaryMedium, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    Color iconColor = AppColors.primary;
    IconData iconData = Icons.notifications_rounded;

    if (n.type.toLowerCase().contains('reminder')) {
      iconColor = AppColors.accentWarm;
      iconData = Icons.alarm_rounded;
    } else if (n.type.toLowerCase().contains('menu')) {
      iconColor = AppColors.breakfast;
      iconData = Icons.restaurant_menu_rounded;
    } else if (n.type.toLowerCase().contains('booking')) {
      iconColor = AppColors.successDark;
      iconData = Icons.check_circle_rounded;
    }

    final dateStr = n.createdAt.length > 16 ? n.createdAt.substring(0, 16).replaceAll('T', ' • ') : n.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: CardContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 16,
        backgroundColor: n.isRead ? AppColors.surface : AppColors.surfaceHighlight,
        border: Border.all(
          color: n.isRead ? AppColors.cardBorder : AppColors.primaryTint,
          width: n.isRead ? 1 : 1.5,
        ),
        onTap: () {
          if (!n.isRead) {
            ref.read(studentNotificationsProvider.notifier).markAsRead(n.id);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: AppTypography.titleMedium.copyWith(
                            fontSize: 14,
                            fontWeight: n.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentWarm,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n.message,
                    style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateStr,
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
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
