import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Added Supabase import
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  void _checkAuthAndNavigate() async {
    // Add a slight delay just so the user can see the cool glowing logo
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    
    // Check current auth state
    final authState = ref.read(authProvider);
    
    if (authState is AuthAuthenticated) {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        
        // Fetch the user's public record
        final userData = await Supabase.instance.client
            .from('users')
            .select('primary_goal')
            .eq('id', userId)
            .maybeSingle();

        if (!mounted) return;

        // The Gate: If primary_goal is null, force onboarding. Otherwise, dashboard.
        if (userData == null || userData['primary_goal'] == null) {
          context.go('/goal-selection');
        } else {
          context.go('/dashboard');
        }
      } catch (e) {
        // Fallback to goal selection if something goes wrong
        if (mounted) context.go('/goal-selection');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha:0.5),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'G',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'GAMIFY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'LEVEL UP YOUR CAREER',
              style: TextStyle(
                color: Colors.lightBlueAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}