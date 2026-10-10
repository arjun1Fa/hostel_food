import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/card_container.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../state/admin_controllers.dart';

class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  String _searchQuery = '';

  Future<void> _toggleStudentActive(int id, bool currentStatus) async {
    try {
      await apiClient.dio.patch(
        '${ApiConstants.users}$id',
        data: {'is_active': !currentStatus},
      );
      ref.invalidate(adminStudentsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student account ${!currentStatus ? "activated" : "deactivated"}.'),
            backgroundColor: AppColors.primaryDark,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update student status: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryDark)),
        error: (err, _) => Center(child: Text('Error loading students: $err')),
        data: (students) {
          final filtered = students.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.fullName.toLowerCase().contains(query) ||
                (s.roomNumber ?? '').toLowerCase().contains(query) ||
                s.email.toLowerCase().contains(query);
          }).toList();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Directory',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          'Manage hostel residents, room allocations, and dining access',
                          style: AppTypography.bodyMedium.copyWith(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref.invalidate(adminStudentsProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by student name, room or college email...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.cardBorder)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No Students Found',
                          description: 'Try adjusting your search criteria.',
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, idx) {
                            final s = filtered[idx];
                            return CardContainer(
                              padding: const EdgeInsets.all(14),
                              borderRadius: 16,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: s.isActive ? AppColors.primarySubtle : Colors.grey.shade200,
                                    child: Text(
                                      s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                                      style: TextStyle(
                                        color: s.isActive ? AppColors.primaryDark : Colors.grey,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              s.fullName,
                                              style: AppTypography.titleMedium.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                                            ),
                                            if (s.isAdmin) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryDark,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Room ${s.roomNumber ?? "Not Set"} • ${s.email}',
                                          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: s.isActive ? AppColors.successSubtle : AppColors.dangerSubtle,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          s.isActive ? 'ACTIVE' : 'INACTIVE',
                                          style: TextStyle(
                                            color: s.isActive ? AppColors.successDark : AppColors.danger,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          s.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                                          color: s.isActive ? AppColors.danger : AppColors.successDark,
                                          size: 20,
                                        ),
                                        tooltip: s.isActive ? 'Deactivate Student' : 'Activate Student',
                                        onPressed: () => _toggleStudentActive(s.id, s.isActive),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
