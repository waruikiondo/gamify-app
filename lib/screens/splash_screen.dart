import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minimumTimeElapsed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    // Guarantee the premium cyberpunk animation plays for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _minimumTimeElapsed = true;
      });
      // Check auth state immediately once the timer unlocks
      _checkAuthAndNavigate(ref.read(authProvider));
    }
  }

  void _checkAuthAndNavigate(AuthState authState) async {
    // 1. Block navigation if the animation hasn't finished
    if (!_minimumTimeElapsed) return;

    // 2. Block navigation if Supabase is still parsing the deep-link fragment
    if (authState is AuthLoading) return;

    // FIX: Using context.replace() bypasses the GoRouter crash on Web
    // by completely overriding the dirty URL history instead of pushing onto it.
    if (authState is AuthPasswordRecovery) {
      context.replace('/update-password');
      return;
    }
    
    if (authState is AuthAuthenticated) {
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        
        final userData = await Supabase.instance.client
            .from('users')
            .select('primary_goal')
            .eq('id', userId)
            .maybeSingle();

        if (!mounted) return;

        if (userData == null || userData['primary_goal'] == null) {
          context.replace('/goal-selection');
        } else {
          context.replace('/dashboard');
        }
      } catch (e) {
        if (mounted) context.replace('/goal-selection');
      }
    } else {
      context.replace('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL FIX 5: Reactively listen for Supabase auth state changes.
    // If parsing takes longer than 2s, we instantly route the moment it resolves.
    ref.listen<AuthState>(authProvider, (previous, next) {
      
      // Catch and display any hidden Supabase token/network errors
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SYSTEM ERROR: ${next.message}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: Colors.redAccent.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            duration: const Duration(seconds: 10), // Long duration for debugging
          ),
        );
      }
      
      _checkAuthAndNavigate(next);
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1A3A), Color(0xFF0A0F14)], 
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Colors.cyanAccent, AppTheme.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.6),
                              blurRadius: 50,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4), 
                          decoration: const BoxDecoration(
                            color: Color(0xFF0A0F14),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      const Text(
                        'GAMIFY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'LEVEL UP YOUR CAREER',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48.0, right: 48.0, bottom: 64.0),
                child: Column(
                  children: [
                    const Text(
                      'INITIALIZING SYSTEM...',
                      style: TextStyle(
                        color: AppTheme.textGrey, 
                        fontSize: 10, 
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 16),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 2), 
                      builder: (context, value, _) {
                        return Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.border.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                gradient: const LinearGradient(
                                  colors: [Colors.cyanAccent, AppTheme.primary],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  )
                                ]
                              ),
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}