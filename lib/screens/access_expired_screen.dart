import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/access_config.dart';
import '../core/theme.dart';
import '../providers/access_gate_provider.dart';

class AccessExpiredScreen extends ConsumerWidget {
  const AccessExpiredScreen({super.key});

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: kSupportEmail,
      queryParameters: {
        'subject': '2FLYDRONES App Access Renewal',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(accessGateStatusProvider);
    final isInstitution = statusAsync.maybeWhen(
      data: (s) => isInstitutionPlan(s.accessPlan),
      orElse: () => false,
    );

    final title =
        isInstitution ? 'Institution access expired' : 'Access expired';
    final body = isInstitution
        ? 'Your school access period (${kInstitutionValidityDays} days) has ended. '
            'Contact your institution or 2FLYDRONES support to regain access.'
        : 'Your individual access period (${kIndividualValidityDays} days) has ended. '
            'Contact 2FLYDRONES support to regain access. '
            'If you received a new access code, enter it below.';

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
                  const Icon(
                    Icons.hourglass_disabled_outlined,
                    size: 64,
                    color: AppTheme.primary,
                  ),
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
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => context.go('/access-code'),
                    child: const Text('Enter new access code'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _contactSupport,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text('Contact support ($kSupportEmail)'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) context.go('/login');
                    },
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
