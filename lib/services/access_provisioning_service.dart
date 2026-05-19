import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/access_config.dart';

class ProvisionIndividualResult {
  final bool ok;
  final String? error;
  final bool alreadyActive;
  final bool needsRedeem;
  final String? code;
  final String? expiresAt;
  final String? planType;

  const ProvisionIndividualResult({
    required this.ok,
    this.error,
    this.alreadyActive = false,
    this.needsRedeem = false,
    this.code,
    this.expiresAt,
    this.planType,
  });
}

class RedeemAccessResult {
  final bool ok;
  final String? error;
  final bool alreadyActive;
  final String? planType;
  final String? expiresAt;

  const RedeemAccessResult({
    required this.ok,
    this.error,
    this.alreadyActive = false,
    this.planType,
    this.expiresAt,
  });
}

Future<bool> emailDomainHasActiveInstitutionCode() async {
  try {
    final email = Supabase.instance.client.auth.currentUser?.email;
    if (email == null) return false;

    final result = await Supabase.instance.client.rpc(
      'email_domain_has_active_institution_code',
      params: {'p_email': email.trim().toLowerCase()},
    );

    return result == true;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[access] email_domain_has_active_institution_code: $e');
    }
    return false;
  }
}

Future<ProvisionIndividualResult> provisionIndividualAccess() async {
  try {
    final result = await Supabase.instance.client.rpc('provision_individual_access');

    if (kDebugMode) {
      debugPrint('[access] provision_individual_access: $result');
    }

    final Map<String, dynamic>? payload = result is Map
        ? result.map((k, v) => MapEntry(k.toString(), v))
        : null;

    if (payload == null) {
      return const ProvisionIndividualResult(ok: false, error: 'unexpected_response');
    }

    return ProvisionIndividualResult(
      ok: payload['ok'] == true,
      error: payload['error']?.toString(),
      alreadyActive: payload['already_active'] == true,
      needsRedeem: payload['needs_redeem'] == true,
      code: payload['code']?.toString(),
      expiresAt: payload['expires_at']?.toString(),
      planType: payload['plan_type']?.toString(),
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[access] provision_individual_access exception: $e');
    }
    return ProvisionIndividualResult(ok: false, error: e.toString());
  }
}

Future<RedeemAccessResult> redeemAccessCode(String code) async {
  try {
    final result = await Supabase.instance.client.rpc(
      'redeem_access_code',
      params: {'p_code': code},
    );

    if (kDebugMode) {
      debugPrint('[access] redeem_access_code: $result');
    }

    final Map<String, dynamic>? payload = result is Map
        ? result.map((k, v) => MapEntry(k.toString(), v))
        : null;

    if (payload == null) {
      return const RedeemAccessResult(ok: false, error: 'unexpected_response');
    }

    return RedeemAccessResult(
      ok: payload['ok'] == true,
      error: payload['error']?.toString(),
      alreadyActive: payload['already_active'] == true,
      planType: payload['plan_type']?.toString(),
      expiresAt: payload['expires_at']?.toString(),
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[access] redeem_access_code exception: $e');
    }
    return RedeemAccessResult(ok: false, error: e.toString());
  }
}

/// Builds `/access-welcome` path with query params for Option A flow.
String buildAccessWelcomePath({
  required String plan,
  String? code,
  String? expiresAt,
}) {
  final params = <String, String>{'plan': plan};
  if (code != null && code.isNotEmpty) {
    params['code'] = code;
  }
  if (expiresAt != null && expiresAt.isNotEmpty) {
    params['expiresAt'] = expiresAt;
  }
  final query = params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
  return '/access-welcome?$query';
}

String formatExpiresAtForDisplay(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  final local = dt.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}

String redeemErrorMessage(String? error) {
  switch (error) {
    case 'domain_mismatch':
      return 'This code is only valid for your institution email domain.';
    case 'code_not_for_this_email':
      return 'This code was issued for a different email address.';
    case 'code_already_used':
      return 'This code has already been used by another account.';
    case 'code_inactive':
      return 'This code is no longer active.';
    case 'code_expired':
      return 'This school access code has expired. Contact your institution or 2FLYDRONES support.';
    case 'code_max_uses_reached':
      return 'This access code has reached its maximum number of uses.';
    case 'invalid_code':
      return 'Invalid access code.';
    case 'not_authenticated':
      return 'Please sign in again.';
    case 'institution_domain':
      return 'Sign up with your school email and enter the access code provided by your institution.';
    default:
      return error == null
          ? 'Invalid access code. Contact 2FLYDRONES administration.'
          : 'Access denied ($error). Contact 2FLYDRONES administration.';
  }
}

bool isInstitutionPlanType(String? plan) =>
    plan == kAccessPlanInstitution;
