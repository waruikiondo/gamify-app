import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- LOGIC REMAINS COMPLETELY UNTOUCHED ---
  void _submitNewPassword() {
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (newPass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.redAccent));
      return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent));
      return;
    }

    ref.read(authProvider.notifier).updatePassword(newPass);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.message), backgroundColor: Colors.redAccent));
      } else if (next is AuthAuthenticated) {
        // Password updated successfully! Show a success message and route to dashboard
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.greenAccent));
        context.go('/dashboard');
      }
    });

    // --- NEW PREMIUM UI APPLIED HERE ---
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D14), // Deep dark gamified background matching the Forgot Password screen
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'SECURE ACCOUNT', 
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Stylized Rounded Icon Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B24), 
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF8A2BE2).withValues(alpha: 0.2)),
                        ),
                        child: const Icon(Icons.lock_reset, color: Color(0xFF8A2BE2), size: 28),
                      ),
                      const SizedBox(height: 24),
                      const Text('Set New Password', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text(
                        'Your identity has been verified. Please create a new, strong password to secure your account.', 
                        style: TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.5)
                      ),
                      const SizedBox(height: 40),
                      
                      // Premium Input Field for New Password
                      _buildPremiumTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: '••••••••••••',
                        icon: Icons.lock_outline,
                        isPassword: _obscureNew,
                        trailing: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Premium Input Field for Confirm Password
                      _buildPremiumTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: '••••••••••••',
                        icon: Icons.lock_outline,
                        isPassword: _obscureConfirm,
                        trailing: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
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
                          onPressed: authState is AuthLoading ? null : _submitNewPassword,
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
                                    Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                    SizedBox(width: 8),
                                    Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
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

  // Helper widget to build the premium input field exactly matching the aesthetic
  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: const Color(0xFF8A2BE2)), // Purple icon
            suffixIcon: trailing,
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