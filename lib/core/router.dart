import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import the Splash Screen
import '../screens/splash_screen.dart';

// Import the new individual auth screens
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/update_password_screen.dart'; // newly added

// Existing screens
import '../screens/dashboard_screen.dart';
import '../screens/level_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // 1. Set the initial location to the Splash Screen
    initialLocation: '/', 
    
    // 2. Updated redirect logic
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      
      final isSplashScreen = state.matchedLocation == '/';
      // Added /update-password to the allowed unauthenticated routes list
      final authRoutes = ['/login', '/signup', '/forgot-password', '/update-password'];
      final isAccessingAuthRoute = authRoutes.contains(state.matchedLocation);

      // CRITICAL: Let the Splash Screen render regardless of auth state!
      // Your splash_screen.dart handles the actual routing after 2 seconds.
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
      
      return null; // Let them proceed normally
    },

    routes: [
      // Splash Route
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      // Auth Flow Routes
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
        builder: (context, state) => const UpdatePasswordScreen(), // newly added
      ),

      // Protected App Routes
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
    ],
  );
});