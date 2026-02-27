import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import the Splash Screen
import '../screens/splash_screen.dart';

// Import the new individual auth screens
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/update_password_screen.dart'; 
import '../screens/goal_selection_screen.dart'; // newly added

// Existing screens
import '../screens/dashboard_screen.dart';
import '../screens/level_screen.dart';
import '../screens/mock_exam_screen.dart';

// Import the Admin Dashboard Screen
import '../screens/admin_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/', 
    
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      
      final isSplashScreen = state.matchedLocation == '/';
      final authRoutes = ['/login', '/signup', '/forgot-password', '/update-password'];
      final isAccessingAuthRoute = authRoutes.contains(state.matchedLocation);

      if (isSplashScreen) {
        return null;
      }

      // If no session and trying to access a protected route (like dashboard), force login
      if (session == null && !isAccessingAuthRoute) {
        return '/login'; 
      }
      
      // If user has a session but tries to go to login/signup, push them to the app
      if (session != null && isAccessingAuthRoute) {
        return '/dashboard'; 
      }
      
      return null; 
    },

    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(), 
      ),
      // NEW ROUTE HERE
      GoRoute(
        path: '/goal-selection',
        builder: (context, state) => const GoalSelectionScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/level/:levelId',
        builder: (context, state) {
          final levelId = state.pathParameters['levelId']!;
          return LevelScreen(levelId: levelId);
        },
      ),
      GoRoute(
        path: '/mock-exam',
        builder: (context, state) => const MockExamScreen(),
      ),
      // ADMIN ROUTE HERE
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});