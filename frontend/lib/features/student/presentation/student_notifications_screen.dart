import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../state/student_controllers.dart';

class StudentNotificationsScreen extends ConsumerWidget {
  const StudentNotificationsScreen({super.key});

  Future<void> _triggerTestReminder(BuildContext context, WidgetRef ref, bool isFinal) async {
    try {
      final res = await apiClient.dio.post(
        '${ApiConstants.triggerReminders}?is_final=$isFinal',
      );
      if (res.statusCode == 200) {
        ref.read(studentNotificationsProvider.notifier).loadNotifications();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Triggered ${isFinal ? "10 PM Final" : "8 PM First"} reminder! Sent to ${res.data["sent_count"]} students.'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to trigger reminder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(studentNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications & Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(studentNotificationsProvider.notifier).loadNotifications(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading notifications: $err'),
        ),
        data: (notifications) {
          return RefreshIndicator(
            onRefresh: () => ref.read(studentNotificationsProvider.notifier).loadNotifications(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Developer / Demonstration Mode Card
                  CardContainer(
                    backgroundColor: AppColors.accentSubtle.withOpacity(0.4),
                    border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, size: 20, color: AppColors.accent),
                            const SizedBox(width: 8),
                            Text(
                              'AUTOMATED REMINDER SCHEDULER',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF78350F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'The backend scheduler automatically dispatches notifications daily at 8:00 PM IST (First Call) and 10:00 PM IST (Final Cutoff Call). Test them instantly below:',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                text: 'Trigger 8 PM Call',
                                variant: ButtonVariant.secondary,
                                height: 38,
                                onPressed: () => _triggerTestReminder(context, ref, false),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CustomButton(
                                text: 'Trigger 10 PM Call',
                                variant: ButtonVariant.accent,
                                height: 38,
                                onPressed: () => _triggerTestReminder(context, ref, true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text('Recent Notices', style: AppTypography.titleLarge),
                  const SizedBox(height: 10),

                  if (notifications.isEmpty)
                    const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No Notifications',
                      description: 'You are all caught up! Automated reminders and booking alerts will appear here.',
                    )
                  else
                    ...notifications.map((n) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: CardContainer(
                          padding: const EdgeInsets.all(14),
                          backgroundColor: n.isRead ? AppColors.surface : AppColors.primarySubtle.withOpacity(0.3),
                          border: Border.all(
                            color: n.isRead ? AppColors.cardBorder : AppColors.primaryMedium.withOpacity(0.4),
                          ),
                          onTap: n.isRead ? null : () => ref.read(studentNotificationsProvider.notifier).markAsRead(n.id),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: n.isRead ? AppColors.surfaceMuted : AppColors.primary.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_active_rounded,
                                  size: 18,
                                  color: n.isRead ? AppColors.textMuted : AppColors.primary,
                                ),
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
                                            ),
                                          ),
                                        ),
                                        if (!n.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.message,
                                      style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
