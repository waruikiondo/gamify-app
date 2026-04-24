import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../providers/access_gate_provider.dart';

class AccessCodeScreen extends ConsumerStatefulWidget {
  const AccessCodeScreen({super.key});

  @override
  ConsumerState<AccessCodeScreen> createState() => _AccessCodeScreenState();
}

class _AccessCodeScreenState extends ConsumerState<AccessCodeScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final supabase = Supabase.instance.client;
      final result = await supabase.rpc(
        'redeem_access_code',
        params: {'p_code': code},
      );

      if (kDebugMode) {
        debugPrint('[access-code] redeem_access_code result: $result');
      }

      final Map<String, dynamic>? payload = (result is Map)
          ? result.map((k, v) => MapEntry(k.toString(), v))
          : null;
      final ok = payload?['ok'] == true;
      final error = payload?['error']?.toString();

      if (!ok) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error == null
                  ? 'Invalid access code. Contact 2FLYDRONES administration for the correct code.'
                  : 'Access denied ($error). Contact 2FLYDRONES administration for the correct code.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      ref.invalidate(accessGateStatusProvider);
      final status = await ref.read(accessGateStatusProvider.future);

      if (!mounted) return;
      if (status.primaryGoal == null || status.primaryGoal!.trim().isEmpty) {
        context.go('/goal-selection');
      } else {
        context.go('/dashboard');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[access-code] redeem_access_code exception: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to verify access code. Please try again or contact 2FLYDRONES administration.'),
          backgroundColor: Colors.redAccent,
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
                    'This platform is restricted to approved learners. If you do not have a code, contact 2FLYDRONES administration.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.9), height: 1.5),
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
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

