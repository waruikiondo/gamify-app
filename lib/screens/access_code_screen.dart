import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/access_config.dart';
import '../core/theme.dart';
import '../providers/access_gate_provider.dart';
import '../services/access_provisioning_service.dart';

class AccessCodeScreen extends ConsumerStatefulWidget {
  const AccessCodeScreen({super.key});

  @override
  ConsumerState<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends ConsumerState<AccessCodeScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _provisionAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryProvisionIndividual());
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _tryProvisionIndividual() async {
    if (_provisionAttempted) return;
    _provisionAttempted = true;

    final status = await ref.read(accessGateStatusProvider.future);
    if (!mounted) return;

    if (status.accessGranted || status.accessExpired) return;
    if (isInstitutionPlan(status.accessPlan)) return;

    if (await emailDomainHasActiveInstitutionCode()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await provisionIndividualAccess();
      if (!mounted) return;

      if (result.error == 'institution_domain' ||
          result.error == 'institution_user') {
        return;
      }

      if (result.ok && (result.alreadyActive || result.code != null)) {
        ref.invalidate(accessGateStatusProvider);
        if (!mounted) return;
        context.go(
          buildAccessWelcomePath(
            plan: result.planType ?? kAccessPlanIndividual,
            code: result.code,
            expiresAt: result.expiresAt,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await redeemAccessCode(code);

      if (!result.ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(redeemErrorMessage(result.error)),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      ref.invalidate(accessGateStatusProvider);
      if (!mounted) return;

      final plan = result.planType ?? kAccessPlanIndividual;
      context.go(
        buildAccessWelcomePath(
          plan: plan,
          expiresAt: result.expiresAt,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      context.go('/login');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(accessGateStatusProvider);
    final isInstitution = statusAsync.maybeWhen(
      data: (s) => isInstitutionPlan(s.accessPlan),
      orElse: () => false,
    );

    final helperText = isInstitution
        ? 'Enter the access code provided by your school or institution.'
        : 'Enter your school access code if you signed up with an institution email. '
            'Individual learners are set up automatically when possible.';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter Access Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    helperText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textGrey.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Access Code',
                      labelStyle: TextStyle(color: AppTheme.textGrey),
                      hintText: 'e.g. LEARNERS2026',
                    ),
                    onSubmitted: (_) => _redeem(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _redeem,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Unlock Access'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isSubmitting ? null : _signOut,
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
