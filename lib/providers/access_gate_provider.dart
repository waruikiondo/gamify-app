import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessGateStatus {
  final bool accessGranted;
  final String? primaryGoal;
  final bool isAdmin;

  const AccessGateStatus({
    required this.accessGranted,
    required this.primaryGoal,
    required this.isAdmin,
  });
}

final accessGateStatusProvider = FutureProvider<AccessGateStatus>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    return const AccessGateStatus(accessGranted: false, primaryGoal: null, isAdmin: false);
  }

  final row = await supabase
      .from('profiles')
      .select('access_granted, access_expires_at, primary_goal, is_admin')
      .eq('id', user.id)
      .maybeSingle();

  if (row == null) {
    // Profiles can be created async (trigger) or not yet inserted. Treat as locked.
    return const AccessGateStatus(accessGranted: false, primaryGoal: null, isAdmin: false);
  }

  final expiresAtRaw = row['access_expires_at'];
  final DateTime? expiresAt = expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw.toString());
  final bool isExpired = expiresAt != null && !expiresAt.isAfter(DateTime.now());

  return AccessGateStatus(
    accessGranted: row['access_granted'] == true && !isExpired,
    primaryGoal: row['primary_goal'] as String?,
    isAdmin: row['is_admin'] == true,
  );
});

