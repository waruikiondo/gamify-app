import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccessGateStatus {
  final bool accessGranted;
  final String? primaryGoal;

  const AccessGateStatus({
    required this.accessGranted,
    required this.primaryGoal,
  });
}

final accessGateStatusProvider = FutureProvider<AccessGateStatus>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    return const AccessGateStatus(accessGranted: false, primaryGoal: null);
  }

  final row = await supabase
      .from('profiles')
      .select('access_granted, primary_goal')
      .eq('id', user.id)
      .maybeSingle();

  if (row == null) {
    // Profiles can be created async (trigger) or not yet inserted. Treat as locked.
    return const AccessGateStatus(accessGranted: false, primaryGoal: null);
  }

  return AccessGateStatus(
    accessGranted: row['access_granted'] == true,
    primaryGoal: row['primary_goal'] as String?,
  );
});

