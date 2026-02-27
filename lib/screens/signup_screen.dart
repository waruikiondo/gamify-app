import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'widgets/custom_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  int _passwordStrength = 0; // 0: None, 1: Weak, 2: Medium, 3: Strong

  @override
  void initState() {
    super.initState();
    // Listen to keystrokes to evaluate password strength in real-time
    _passwordController.addListener(() {
      _evaluatePasswordStrength(_passwordController.text);
    });
  }

  void _evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = 0);
      return;
    }

    int strength = 0;
    // 1. Basic length check
    if (password.length >= 6) strength += 1; 
    // 2. Contains both uppercase and lowercase letters
    if (RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password)) strength += 1; 
    // 3. Contains at least one number or special character
    if (RegExp(r'(?=.*\d)|(?=.*[^a-zA-Z\d])').hasMatch(password)) strength += 1; 

    // Ensure it shows at least "Weak" if they type something short
    if (password.isNotEmpty && strength == 0) strength = 1;

    setState(() => _passwordStrength = strength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Helper method to get the correct text label
  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1: return 'WEAK';
      case 2: return 'GOOD';
      case 3: return 'STRONG';
      default: return '';
    }
  }

  // Helper method to get the correct text color
  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return Colors.redAccent;
      case 2: return Colors.orangeAccent;
      case 3: return Colors.greenAccent;
      default: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.redAccent));
      } else if (next is AuthAuthenticated) {
        context.go('/goal-selection');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Step 1 of 3', style: TextStyle(color: Colors.white, fontSize: 16)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E3F), Color(0xFF3B1E54)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(8)),
                    child: const Text('NEW SEASON', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Join the Quest', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Start your professional certification journey today and unlock elite rewards.', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: AppTheme.border.withValues(alpha:0.5)),
              ),
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameController, 
                    label: 'Full Name', 
                    hint: 'Alex Rivers'
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _emailController, 
                    label: 'Email Address', 
                    hint: 'alex@quest.edu'
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••••••',
                    isPassword: _obscurePassword,
                    trailing: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // --- DYNAMIC PASSWORD STRENGTH UI ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('PASSWORD STRENGTH', style: TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                      Text(
                        _strengthLabel, 
                        style: TextStyle(color: _strengthColor, fontSize: 10, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4, 
                          decoration: BoxDecoration(
                            // Bar 1 lights up red if strength is >= 1
                            color: _passwordStrength >= 1 ? Colors.redAccent : AppTheme.border.withValues(alpha:0.3), 
                            borderRadius: BorderRadius.circular(2)
                          )
                        )
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4, 
                          decoration: BoxDecoration(
                            // Bar 2 lights up orange if strength is >= 2
                            color: _passwordStrength >= 2 ? Colors.orangeAccent : AppTheme.border.withValues(alpha:0.3), 
                            borderRadius: BorderRadius.circular(2)
                          )
                        )
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4, 
                          decoration: BoxDecoration(
                            // Bar 3 lights up green if strength is 3
                            color: _passwordStrength == 3 ? Colors.greenAccent : AppTheme.border.withValues(alpha:0.3), 
                            borderRadius: BorderRadius.circular(2)
                          )
                        )
                      ),
                    ],
                  ),
                  // ------------------------------------
                  
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: authState is AuthLoading ? null : () {
                      ref.read(authProvider.notifier).signUp(
                        email: _emailController.text.trim(),
                        password: _passwordController.text.trim(),
                        fullName: _nameController.text.trim(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: authState is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Create Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(width: 8),
                              Icon(Icons.bolt, size: 20, color: Colors.white),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () => context.pop(),
                child: RichText(
                  text: const TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                    children: [TextSpan(text: 'Log In', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}