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
          SnackBar(content: Text('Student account ${!currentStatus ? "activated" : "deactivated"}.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update student status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(adminStudentsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(adminStudentsProvider),
          ),
        ],
      ),
      body: studentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, _) => Center(child: Text('Error loading students: $err')),
        data: (students) {
          final filtered = students.where((s) {
            final query = _searchQuery.toLowerCase();
            return s.fullName.toLowerCase().contains(query) ||
                (s.roomNumber ?? '').toLowerCase().contains(query) ||
                s.email.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by student name, room or email...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No Students Found',
                        description: 'Try adjusting your search query.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final s = filtered[idx];
                          return CardContainer(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: s.isActive ? AppColors.primarySubtle : Colors.grey.shade200,
                                  foregroundColor: s.isActive ? AppColors.primary : Colors.grey,
                                  child: Text(
                                    s.fullName.isNotEmpty ? s.fullName[0].toUpperCase() : 'S',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
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
                                            style: AppTypography.titleMedium.copyWith(fontSize: 15),
                                          ),
                                          const SizedBox(width: 6),
                                          if (s.roomNumber != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.surfaceMuted,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Room ${s.roomNumber}',
                                                style: AppTypography.labelSmall.copyWith(fontSize: 10),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${s.email} • ${s.phoneNumber ?? "No phone"}',
                                        style: AppTypography.bodyMedium.copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Switch(
                                      value: s.isActive,
                                      activeColor: AppColors.primary,
                                      onChanged: (_) => _toggleStudentActive(s.id, s.isActive),
                                    ),
                                    Text(
                                      s.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: s.isActive ? AppColors.success : AppColors.danger,
                                      ),
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
          );
        },
      ),
    );
  }
}
