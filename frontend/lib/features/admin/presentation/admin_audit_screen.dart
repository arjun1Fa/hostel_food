import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/empty_state.dart';

final auditLogsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final response = await apiClient.dio.get('/audit/logs?limit=100');
  if (response.statusCode == 200) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security & Audit Logs',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Authoritative log of administrative actions, price edits, overrides, and security events.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryDark),
                    tooltip: 'Refresh Logs',
                    onPressed: () => ref.invalidate(auditLogsProvider),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Content
              Expanded(
                child: auditLogsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryDark),
                  ),
                  error: (err, _) => Center(
                    child: Text('Failed to load audit logs: $err', style: const TextStyle(color: AppColors.danger)),
                  ),
                  data: (logs) {
                    if (logs.isEmpty) {
                      return const EmptyState(
                        icon: Icons.security_rounded,
                        title: 'No Audit Events',
                        description: 'Audit events will appear here as administrative actions occur.',
                      );
                    }

                    return ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final action = log['action'] as String? ?? 'UNKNOWN';
                        final details = log['details'] as String? ?? '';
                        final userName = log['user_name'] as String? ?? 'System';
                        final rawTime = log['created_at'] as String?;
                        final formattedTime = rawTime != null
                            ? DateFormat('d MMM yyyy, h:mm a').format(DateTime.parse(rawTime).toLocal())
                            : '';

                        final isSecurityAlert = action.contains('REUSE') || action.contains('DENIED');
                        final isOverride = action.contains('OVERRIDE');
                        final isPrice = action.contains('PRICE');

                        final badgeColor = isSecurityAlert
                            ? AppColors.danger
                            : isOverride
                                ? AppColors.accent
                                : isPrice
                                    ? AppColors.saffron
                                    : AppColors.primaryDark;

                        return AnimatedEntrance(
                          index: index,
                          child: CardContainer(
                            padding: const EdgeInsets.all(14),
                            borderRadius: 14,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    action,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        details,
                                        style: AppTypography.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Actor: $userName',
                                            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                                          ),
                                          const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                                          Text(
                                            formattedTime,
                                            style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
