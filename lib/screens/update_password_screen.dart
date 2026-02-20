import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import 'widgets/custom_text_field.dart';

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

    // Call the new method we just added to the provider
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green));
        context.go('/dashboard');
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't allow them to hit back here
        title: const Text('SECURE ACCOUNT', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, letterSpacing: 1)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.lock_reset, color: AppTheme.primary, size: 32),
            ),
            const SizedBox(height: 24),
            const Text('Set New Password', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Your identity has been verified. Please create a new, strong password to secure your account.', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _newPasswordController,
              label: 'New Password',
              hint: '••••••••••••',
              isPassword: _obscureNew,
              trailing: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
              ),
            ),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: '••••••••••••',
              isPassword: _obscureConfirm,
              trailing: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: AppTheme.textGrey),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: authState is AuthLoading ? null : _submitNewPassword,
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
                        Text('Update Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_outline, size: 20, color: Colors.white),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}