import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
// Note: Removed custom_text_field import as we are building custom premium inputs inline

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

  // --- LOGIC REMAINS COMPLETELY UNTOUCHED ---
  void _evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() => _passwordStrength = 0);
      return;
    }

    int strength = 0;
    if (password.length >= 6) strength += 1;
    if (RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password)) strength += 1;
    if (RegExp(r'(?=.*\d)|(?=.*[^a-zA-Z\d])').hasMatch(password)) strength += 1;

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

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 1:
        return 'WEAK';
      case 2:
        return 'GOOD';
      case 3:
        return 'STRONG';
      default:
        return '';
    }
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.amber;
      case 3:
        return Colors.greenAccent;
      default:
        return Colors.transparent;
    }
  }

  // --- NEW PREMIUM UI APPLIED HERE ---
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      } else if (next is AuthAuthenticated) {
        context.go('/goal-selection');
      }
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E1A3A),
              Color(0xFF0A0F14),
            ], // Deep dark gamified background
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar matching the screenshot
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF131B24),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Abstract Neon Header Card
                      Container(
                        width: double.infinity,
                        height: 140,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          // Simulating the neon wave graphic from the Figma design
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF3B1E54),
                              Color(0xFF00BFFF),
                              Color(0xFF1E1A3A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00BFFF,
                              ).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF8A2BE2,
                                ), // Vibrant Purple tag
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child:                               const Text(
                                'EXAM PREP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Train to Pass',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'We don\'t hand out certificates — we prepare you to earn them. Master the material, then go take the real exam.',
                        style: TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Form Container
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B24).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: AppTheme.border.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildPremiumTextField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Alex Rivers',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 20),
                            _buildPremiumTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'alex@example.com',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 20),
                            _buildPremiumTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              isPassword: _obscurePassword,
                              trailing: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textGrey,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // --- DYNAMIC PASSWORD STRENGTH UI ---
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PASSWORD STRENGTH',
                                  style: TextStyle(
                                    color: AppTheme.textGrey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  _strengthLabel,
                                  style: TextStyle(
                                    color: _strengthColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _passwordStrength >= 1
                                          ? Colors.redAccent
                                          : AppTheme.border.withValues(
                                              alpha: 0.3,
                                            ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _passwordStrength >= 2
                                          ? Colors.amber
                                          : AppTheme.border.withValues(
                                              alpha: 0.3,
                                            ),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: _passwordStrength == 3
                                          ? Colors.greenAccent
                                          : AppTheme.border.withValues(
                                              alpha: 0.3,
                                            ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: _passwordStrength == 3
                                          ? [
                                              BoxShadow(
                                                color: Colors.greenAccent
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 8,
                                              ),
                                            ]
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // ------------------------------------
                            const SizedBox(height: 32),

                            // Glowing Purple Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF8A2BE2),
                                    Color(0xFF5D3FD3),
                                  ], // Vibrant Purple
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF8A2BE2,
                                    ).withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: authState is AuthLoading
                                    ? null
                                    : () {
                                        ref
                                            .read(authProvider.notifier)
                                            .signUp(
                                              email: _emailController.text
                                                  .trim(),
                                              password: _passwordController.text
                                                  .trim(),
                                              fullName: _nameController.text
                                                  .trim(),
                                            );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size(double.infinity, 56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: authState is AuthLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.bolt,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Social Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: AppTheme.border.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR SIGN UP WITH',
                                    style: TextStyle(
                                      color: AppTheme.textGrey,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: AppTheme.border.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Social Circular Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildSocialIconButton(Icons.apple),
                                const SizedBox(width: 16),
                                _buildSocialIconButton(
                                  Icons.g_mobiledata,
                                  iconSize: 32,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: GestureDetector(
                          onTap: () => context.pop(),
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Log In',
                                  style: TextStyle(
                                    color: Color(0xFF8A2BE2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: Colors.cyanAccent.withValues(alpha: 0.7)),
            suffixIcon: trailing,
            filled: true,
            fillColor: const Color(0xFF131B24),
            contentPadding: const EdgeInsets.symmetric(vertical: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.border.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget for the circular social buttons
  Widget _buildSocialIconButton(IconData icon, {double iconSize = 24}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF131B24),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: iconSize),
        onPressed: () {},
      ),
    );
  }
}
