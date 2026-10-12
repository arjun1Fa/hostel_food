import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/state/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/student/presentation/student_shell.dart';
import '../../features/admin/presentation/admin_shell.dart';
import '../theme/app_animations.dart';


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
        pageBuilder: (context, state) => AppAnimations.pageTransition(
          context: context,
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => AppAnimations.pageTransition(
          context: context,
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/student',
        pageBuilder: (context, state) => AppAnimations.pageTransition(
          context: context,
          state: state,
          child: const StudentShell(),
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => AppAnimations.pageTransition(
          context: context,
          state: state,
          child: const AdminShell(),
        ),
      ),
    ],
  );
});

