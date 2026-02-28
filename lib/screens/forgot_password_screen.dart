import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

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

  // --- LOGIC REMAINS COMPLETELY UNTOUCHED ---
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

    // --- NEW PREMIUM UI APPLIED HERE ---
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D14), // Deep dark gamified background matching the screenshot
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar matching the screenshot
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        _emailSent ? 'PASSWORD RESET' : '', 
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the row to keep title centered
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _emailSent ? _buildSuccessState() : _buildInputState(authState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputState(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Stylized Rounded Icon Container (matching first screenshot)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF131B24), 
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF8A2BE2).withValues(alpha: 0.2)),
          ),
          child: const Icon(Icons.restart_alt, color: Color(0xFF8A2BE2), size: 24),
        ),
        const SizedBox(height: 24),
        const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text(
          'Enter your email address and we\'ll send you a link to get back into your account.', 
          style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5)
        ),
        const SizedBox(height: 40),
        
        // Premium Input Field exactly like the Figma design
        _buildPremiumTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'example@learning.com',
          icon: Icons.email_outlined,
        ),
        
        const Spacer(),
        
        // Glowing Purple Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [Color(0xFF8A2BE2), Color(0xFF5D3FD3)], // Vibrant Purple Gradient
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A2BE2).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: ElevatedButton(
            onPressed: authState is AuthLoading ? null : () {
               ref.read(authProvider.notifier).resetPassword(_emailController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: authState is AuthLoading 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Send Reset Link', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20, color: Colors.white),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        
        Center(
          child: GestureDetector(
            onTap: () => context.pop(),
            child: RichText(
              text: const TextSpan(
                text: "Remember your password? ",
                style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                children: [
                  TextSpan(text: 'Log In', style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold))
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // Matches the second screenshot exactly
  Widget _buildSuccessState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFF131B24).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),       
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                // Glowing circular envelope background
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, 
                    color: const Color(0xFF8A2BE2).withValues(alpha: 0.1),
                    border: Border.all(color: const Color(0xFF8A2BE2).withValues(alpha: 0.3), width: 2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF8A2BE2).withValues(alpha: 0.2), blurRadius: 30)
                    ]
                  ),
                  child: const Icon(Icons.email_outlined, color: Color(0xFF8A2BE2), size: 48),
                ),
                // Green checkmark badge
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.greenAccent),
                  child: const Icon(Icons.check, color: Colors.black, size: 16, weight: 800),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Check your email', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "We've sent a magic link to your inbox. Tap it to securely reset your password.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            
            // Dark Pill Container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D14), // Darker inner pill 
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border.withValues(alpha: 0.2)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, color: Color(0xFF8A2BE2), size: 16), // Replacing bolt to match exact vibe if needed
                  SizedBox(width: 8),
                  Text('Almost back to your learning streak!', style: TextStyle(color: Color(0xFF8A2BE2), fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            // Purple Return Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFF5D3FD3)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Return to Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Didn\'t receive the email?', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () { /* Resend Logic */ },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8A2BE2),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Resend link in 45s', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to build the premium input field exactly matching the first screenshot
  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: const Color(0xFF8A2BE2)), // Purple icon
            filled: true,
            fillColor: const Color(0xFF131B24), // Dark background for the input
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8A2BE2), width: 1.5), // Purple border
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8A2BE2), width: 2.5), // Thicker purple on focus
            ),
          ),
        ),
      ],
    );
  }
}