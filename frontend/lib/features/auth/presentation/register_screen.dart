import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../state/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roomController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose;
    _emailController.dispose;
    _roomController.dispose;
    _phoneController.dispose;
    _passwordController.dispose;
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all mandatory fields')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          roomNumber: _roomController.text,
          phoneNumber: _phoneController.text,
        );

    if (success && mounted) {
      context.go('/student');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Student Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join Heritage Hostel Dining',
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create your account to view menus and pre-book meals',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSubtle,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.danger),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomTextField(
                    label: 'Full Name *',
                    hint: 'e.g. Ramesh Kumar',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Email Address *',
                    hint: 'student@hostel.edu',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Room Number',
                          hint: 'e.g. A-204',
                          controller: _roomController,
                          prefixIcon: Icons.meeting_room_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: CustomTextField(
                          label: 'Phone Number',
                          hint: '9876543210',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Password *',
                    hint: 'Minimum 6 characters',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  const SizedBox(height: 28),
                  CustomButton(
                    text: 'Register Account',
                    isLoading: authState.isLoading,
                    onPressed: _handleRegister,
                    height: 50,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Already have an account? Sign In',
                        style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
