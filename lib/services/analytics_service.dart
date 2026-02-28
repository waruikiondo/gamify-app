import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

class AnalyticsService {
  
  /// The central funnel for all tracking. 
  /// When you add PostHog or Firebase, you only need to put their tracking code inside this one function!
  void logEvent(String eventName, {Map<String, dynamic>? properties}) {
    // TODO: Add Posthog().capture(eventName: eventName, properties: properties); here later.
    debugPrint('📊 ANALYTICS EVENT FIRED: $eventName | Data: $properties');
  }

  // --- PRE-DEFINED HOOKS ---
  
  void trackLevelStarted(String levelId) {
    logEvent('level_started', properties: {'level_id': levelId});
  }

  void trackLevelCompleted(String levelId, double scorePercentage, bool passed) {
    logEvent('level_completed', properties: {
      'level_id': levelId, 
      'score': scorePercentage, 
      'passed': passed
    });
  }

  // FIX: Renamed from trackExamStarted to trackMockExamStarted
  void trackMockExamStarted() {
    logEvent('mock_exam_started');
  }

  void trackExamCompleted(int score, bool passed, int timeTakenSeconds) {
    logEvent('mock_exam_completed', properties: {
      'score': score, 
      'passed': passed, 
      'time_taken_seconds': timeTakenSeconds
    });
  }
  
  void trackAntiCheatTriggered() {
    logEvent('anti_cheat_triggered');
  }

  void trackCertificateDownloaded(String userName) {
    logEvent('certificate_downloaded', properties: {'user_name': userName});
  }
}