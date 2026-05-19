import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/access_config.dart';
import '../core/theme.dart';
import '../providers/access_gate_provider.dart';
import '../services/access_provisioning_service.dart';

class AccessWelcomeScreen extends ConsumerWidget {
  const AccessWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = GoRouterState.of(context).uri;
    final plan = uri.queryParameters['plan'] ?? kAccessPlanIndividual;
    final code = uri.queryParameters['code'];
    final expiresAtRaw = uri.queryParameters['expiresAt'];
    final expiresDisplay = formatExpiresAtForDisplay(expiresAtRaw);

    final isInstitution = isInstitutionPlanType(plan);

    final title = isInstitution ? 'School access active' : 'Your access is active';
    final body = isInstitution
        ? 'You can use 2FLYDRONES training until '
            '${expiresDisplay.isNotEmpty ? expiresDisplay : 'your school access period ends'}. '
            'Save this date — all students at your school share the same access window.'
        : 'Your $kIndividualValidityDays-day individual access is active. '
            'Save the code below for your records.';

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
                  const Icon(Icons.verified_outlined, size: 64, color: AppTheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textGrey.withValues(alpha: 0.9),
                      height: 1.5,
                    ),
                  ),
                  if (!isInstitution && code != null && code.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B24),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: SelectableText(
                        code,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                  if (expiresDisplay.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Access valid until: $expiresDisplay',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => _onContinue(context, ref),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue(BuildContext context, WidgetRef ref) async {
    ref.invalidate(accessGateStatusProvider);
    final status = await ref.read(accessGateStatusProvider.future);
    if (!context.mounted) return;

    if (status.primaryGoal == null || status.primaryGoal!.trim().isEmpty) {
      context.go('/goal-selection');
    } else {
      context.go('/dashboard');
    }
  }
}
