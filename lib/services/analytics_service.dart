import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {

  /// Central funnel for all tracking. All events route through here.
  void logEvent(String eventName, {Map<String, dynamic>? properties}) {
    final posthogProps = properties?.map((k, v) => MapEntry(k, v as Object));
    Posthog().capture(eventName: eventName, properties: posthogProps);
    debugPrint('📊 ANALYTICS: $eventName | $properties');
  }

  /// Call on sign-in/sign-up so all subsequent events are tied to this user.
  void identifyUser(String userId, {String? email, String? name}) {
    Posthog().identify(
      userId: userId,
      userProperties: {
        if (email != null) 'email': email,
        if (name != null) 'name': name,
      },
    );
  }

  /// Call on sign-out to disassociate events from the user.
  void resetUser() {
    Posthog().reset();
  }

  // --- PRE-DEFINED HOOKS ---

  void trackLevelStarted(String levelId) {
    logEvent('level_started', properties: {'level_id': levelId});
  }

  void trackLevelCompleted(String levelId, double scorePercentage, bool passed) {
    logEvent('level_completed', properties: {
      'level_id': levelId,
      'score': scorePercentage,
      'passed': passed,
    });
  }

  void trackMockExamStarted() {
    logEvent('mock_exam_started');
  }

  void trackExamCompleted(int score, bool passed, int timeTakenSeconds) {
    logEvent('mock_exam_completed', properties: {
      'score': score,
      'passed': passed,
      'time_taken_seconds': timeTakenSeconds,
    });
  }

  void trackAntiCheatTriggered() {
    logEvent('anti_cheat_triggered');
  }

  void trackCertificateDownloaded(String userName) {
    logEvent('certificate_downloaded', properties: {'user_name': userName});
  }
}
