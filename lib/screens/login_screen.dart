import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'widgets/custom_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.redAccent));
      } else if (next is AuthAuthenticated) {
        context.go('/dashboard'); 
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 30, spreadRadius: 2)],
                ),
                child: const Center(child: Text('G', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(height: 24),
              const Text('Welcome Back', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Level up your professional journey', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
              const SizedBox(height: 48),
              
              CustomTextField(
                controller: _emailController,
                label: 'Work Email',
                hint: 'name@company.com',
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 24),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    isPassword: _obscurePassword,
                    trailing: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton(
                onPressed: authState is AuthLoading ? null : () {
                  ref.read(authProvider.notifier).signIn(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
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
                          Text('Enter Platform', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.bolt, size: 20, color: Colors.white),
                        ],
                      ),
              ),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.border)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR CONTINUE WITH', style: TextStyle(color: AppTheme.textGrey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(child: Divider(color: AppTheme.border)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.apple, color: Colors.white),
                      label: const Text('Apple', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata, color: Colors.white, size: 30), 
                      label: const Text('Google', style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.border),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              GestureDetector(
                onTap: () => context.push('/signup'),
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                    children: [
                      TextSpan(text: 'Join the Academy', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}