import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'widgets/custom_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.redAccent));
      } else if (next is AuthInitial && _emailController.text.isNotEmpty) {
        // Assuming AuthInitial is returned after successful password reset trigger
        setState(() {
          _emailSent = true;
        });
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
        title: Text(_emailSent ? 'PASSWORD RESET' : '', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _emailSent ? _buildSuccessState() : _buildInputState(authState),
      ),
    );
  }

  Widget _buildInputState(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.restart_alt, color: AppTheme.primary, size: 32),
        ),
        const SizedBox(height: 24),
        const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Enter your email address and we\'ll send you a link to get back into your account.', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'example@learning.com',
          icon: Icons.email_outlined,
        ),
        const Spacer(),
        ElevatedButton(
          onPressed: authState is AuthLoading ? null : () {
             ref.read(authProvider.notifier).resetPassword(_emailController.text.trim());
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
                    Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: RichText(
              text: const TextSpan(
                text: "Remember your password? ",
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                children: [TextSpan(text: 'Log In', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(32),
 border: Border.all(color: AppTheme.border.withOpacity(0.5)),       ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.2)),
                  child: const Icon(Icons.email, color: AppTheme.primary, size: 48),
                ),
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent),
                  child: const Icon(Icons.check, color: Colors.black, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Check your email', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "We've sent a magic link to your inbox. Tap it to securely reset your password.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.bolt, color: AppTheme.primary, size: 16),
                  SizedBox(width: 8),
                  Text('Almost back to your learning streak!', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Return to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            const SizedBox(height: 16),
            const Text('Didn\'t receive the email?', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            TextButton(
              onPressed: () { /* Resend Logic */ },
              child: const Text('Resend link in 45s', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}