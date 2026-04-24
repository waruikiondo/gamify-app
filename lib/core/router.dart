import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/update_password_screen.dart'; 
import '../screens/goal_selection_screen.dart'; 
import '../screens/dashboard_screen.dart';
import '../screens/level_overview_screen.dart'; 
import '../screens/level_screen.dart';
import '../screens/admin_question_preview_screen.dart';
import '../screens/mock_exam_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/access_code_screen.dart';
import '../providers/access_gate_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/', 
    
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      
      final path = state.uri.path;
      final isSplashScreen = path == '/';
      
      final authRoutes = ['/login', '/signup', '/forgot-password'];
      final isAccessingAuthRoute = authRoutes.contains(path);
      final isUpdatePasswordRoute = path == '/update-password';
      final isAccessCodeRoute = path == '/access-code';

      if (isSplashScreen) {
        return null;
      }

      if (session == null && !isAccessingAuthRoute && !isUpdatePasswordRoute) {
        return '/login'; 
      }
      
      if (session != null && isAccessingAuthRoute) {
        return '/dashboard'; 
      }

      // Access-code gate: authenticated users must redeem before accessing the app.
      if (session != null && !isUpdatePasswordRoute) {
        final status = await ref.read(accessGateStatusProvider.future);
        if (!status.accessGranted && !isAccessCodeRoute) {
          return '/access-code';
        }
        if (status.accessGranted && isAccessCodeRoute) {
          // If they're granted, keep them moving to the right place.
          if (status.primaryGoal == null || status.primaryGoal!.trim().isEmpty) {
            return '/goal-selection';
          }
          return '/dashboard';
        }
      }
      
      return null; 
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/update-password', builder: (context, state) => const UpdatePasswordScreen()),
      GoRoute(path: '/access-code', builder: (context, state) => const AccessCodeScreen()),
      GoRoute(path: '/goal-selection', builder: (context, state) => const GoalSelectionScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      
      GoRoute(
        path: '/level/:levelId',
        builder: (context, state) {
          final levelId = state.pathParameters['levelId']!;
          return LevelOverviewScreen(levelId: levelId); 
        },
      ),
      
      GoRoute(
        path: '/level/:levelId/assessment',
        builder: (context, state) {
          final levelId = state.pathParameters['levelId']!;
          return LevelScreen(levelId: levelId); 
        },
      ),

      GoRoute(
        path: '/level/:levelId/questions',
        builder: (context, state) {
          final levelId = state.pathParameters['levelId']!;
          return AdminQuestionPreviewScreen(levelId: levelId);
        },
      ),
      
      GoRoute(path: '/mock-exam', builder: (context, state) => const MockExamScreen()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminDashboardScreen()),
    ],
  );
});