import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/student/presentation/student_shell.dart';
import '../../features/admin/presentation/admin_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      if (!isAuth) {
        if (!isLoggingIn && !isRegistering) {
          return '/login';
        }
        return null;
      }

      // Authenticated users
      final user = authState.user;
      final isAdmin = user?.isAdmin ?? false;

      if (isLoggingIn || isRegistering || state.matchedLocation == '/') {
        return isAdmin ? '/admin' : '/student';
      }

      if (!isAdmin && state.matchedLocation.startsWith('/admin')) {
        return '/student';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentShell(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
      ),
    ],
  );
});
