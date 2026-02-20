import 'package:supabase_flutter/supabase_flutter.dart';

class GamifyEngine {
  // Singleton instance of Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Evaluates if a user has passed the current level based on an 80% threshold.
  /// If successful, marks the current level as completed and unlocks the next level.
  Future<bool> evaluateAndUnlockNextLevel({
    required String userId,
    required String currentLevelId,
    required String nextLevelId,
  }) async {
    try {
      // 1. Fetch all questions (Gates) mapped to the current level [cite: 187, 188]
      final questionsResponse = await _supabase
          .from('questions')
          .select('id')
          .eq('level_id', currentLevelId);

      final List<dynamic> questions = questionsResponse as List<dynamic>;
      final int totalQuestions = questions.length;

      // Prevent division by zero if a level has no questions yet
      if (totalQuestions == 0) return false;

      // Extract just the question IDs to use in our next query
      final List<String> questionIds = questions.map((q) => q['id'].toString()).toList();

      // 2. Fetch the user's successful attempts for these specific questions [cite: 189, 190]
      final passedAttemptsResponse = await _supabase
          .from('user_question_attempts')
          .select('id')
          .eq('user_id', userId)
          .eq('passed', true)
          .inFilter('question_id', questionIds); 

      final int passedQuestionsCount = (passedAttemptsResponse as List).length;

      // 3. Calculate the percentage [cite: 216]
      final double passRate = passedQuestionsCount / totalQuestions;

      // 4. Check against the 80% unlock condition 
      if (passRate >= 0.8) {
        
        // Update user_progress: Mark current level as completed [cite: 152, 156, 191]
        await _supabase.from('user_progress').upsert({
          'user_id': userId,
          'level_id': currentLevelId,
          'completed': true,
          'unlocked': true, // Ensures it remains unlocked
        });

        // Update user_progress: Unlock the next level [cite: 152, 155, 191]
        await _supabase.from('user_progress').upsert({
          'user_id': userId,
          'level_id': nextLevelId,
          'unlocked': true,
          'completed': false,
        });

        return true; // Threshold met, level unlocked!
      }

      // User scored below 80%
      return false; 

    } catch (e) {
      // In a production app, route this to a logging service
      print('Error evaluating level progress: \$e');
      return false;
    }
  }
}