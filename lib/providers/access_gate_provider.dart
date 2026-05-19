import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/access_config.dart';

class AccessGateStatus {
  final bool accessGranted;
  final bool accessExpired;
  final bool needsAccessCode;
  final String? accessPlan;
  final String? primaryGoal;
  final bool isAdmin;

  const AccessGateStatus({
    required this.accessGranted,
    required this.accessExpired,
    required this.needsAccessCode,
    required this.accessPlan,
    required this.primaryGoal,
    required this.isAdmin,
  });
}

final accessGateStatusProvider = FutureProvider<AccessGateStatus>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    return const AccessGateStatus(
      accessGranted: false,
      accessExpired: false,
      needsAccessCode: true,
      accessPlan: null,
      primaryGoal: null,
      isAdmin: false,
    );
  }

  final row = await supabase
      .from('profiles')
      .select('access_granted, access_expires_at, access_plan, primary_goal, is_admin')
      .eq('id', user.id)
      .maybeSingle();

  if (row == null) {
    return const AccessGateStatus(
      accessGranted: false,
      accessExpired: false,
      needsAccessCode: true,
      accessPlan: null,
      primaryGoal: null,
      isAdmin: false,
    );
  }

  final expiresAtRaw = row['access_expires_at'];
  final DateTime? expiresAt =
      expiresAtRaw == null ? null : DateTime.tryParse(expiresAtRaw.toString());
  final bool isExpired =
      expiresAt != null && !expiresAt.isAfter(DateTime.now());
  final bool granted = row['access_granted'] == true && !isExpired;
  final String? plan = row['access_plan'] as String?;

  return AccessGateStatus(
    accessGranted: granted,
    accessExpired: isExpired,
    needsAccessCode: !granted && !isExpired,
    accessPlan: plan,
    primaryGoal: row['primary_goal'] as String?,
    isAdmin: row['is_admin'] == true,
  );
});

bool isInstitutionPlan(String? plan) => plan == kAccessPlanInstitution;
