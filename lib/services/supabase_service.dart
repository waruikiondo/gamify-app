import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // --- AUTHENTICATION ---
  Future<AuthResponse> signUp({required String email, required String password}) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({required String email, required String password}) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  // --- USER DATA ---
  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      final response = await _client.from('profiles').select().eq('id', user.id).single();
      return response;
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return {'full_name': 'Agent', 'rank': 'Novice'}; 
    }
  }

  // --- STREAK ENGINE (NEW) ---
  Future<int> updateAndGetStreak() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    try {
      final userData = await _client.from('users').select('current_streak, last_active_date').eq('id', user.id).single();
      
      final now = DateTime.now();
      // Strip time to just compare the calendar days
      final today = DateTime(now.year, now.month, now.day); 
      
      int currentStreak = userData['current_streak'] ?? 0;
      final lastActiveStr = userData['last_active_date'];
      
      // If they have never logged a streak before
      if (lastActiveStr == null) {
        currentStreak = 1;
        await _client.from('users').update({
          'current_streak': currentStreak,
          'last_active_date': today.toIso8601String(),
        }).eq('id', user.id);
        return currentStreak;
      }

      final lastActive = DateTime.parse(lastActiveStr);
      final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
      final difference = today.difference(lastActiveDay).inDays;

      if (difference == 1) {
        // Logged in exactly 1 day later (Consecutive!)
        currentStreak += 1;
        await _client.from('users').update({
          'current_streak': currentStreak,
          'last_active_date': today.toIso8601String(),
        }).eq('id', user.id);
      } else if (difference > 1) {
        // Missed a day. Streak broken.
        currentStreak = 1;
        await _client.from('users').update({
          'current_streak': currentStreak,
          'last_active_date': today.toIso8601String(),
        }).eq('id', user.id);
      }
      // If difference == 0, they already logged in today, so we just return the current streak.

      return currentStreak;
    } catch (e) {
      debugPrint('Error handling streak: $e');
      return 0;
    }
  }

  // --- PROFILE MANAGEMENT ---
  Future<void> updateUserName(String newName) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('profiles').update({'full_name': newName}).eq('id', user.id);
      await _client.auth.updateUser(UserAttributes(data: {'full_name': newName}));
    } catch (e) {
      debugPrint('Error updating name: $e');
      rethrow; 
    }
  }

  // --- GAMIFIED ENGINE (LEVELS & PROGRESS) ---
  Future<List<Map<String, dynamic>>> getLevels() async {
    final response = await _client.from('levels').select().order('level_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getUserProgress(String levelId) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('user_level_progress')
          .select()
          .eq('user_id', user.id)
          .eq('level_id', levelId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getQuestionsForLevel(String levelId) async {
    final response = await _client.from('questions').select().eq('level_id', levelId);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> saveLevelProgress({
    required String levelId,
    required double scorePercentage,
    required bool passed,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('user_level_progress').upsert({
      'user_id': user.id,
      'level_id': levelId,
      'highest_score_percentage': scorePercentage,
      'completed': passed,
      'last_attempted_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id, level_id');
  }

  Future<void> saveQuestionAttempts(List<Map<String, dynamic>> attempts) async {
    final user = _client.auth.currentUser;
    if (user == null || attempts.isEmpty) return;

    try {
      final dataToInsert = attempts.map((attempt) => {
        'user_id': user.id,
        'question_id': attempt['question_id'],
        'skill_area_id': attempt['skill_area_id'],
        'passed': attempt['passed'],
      }).toList();

      await _client.from('user_question_attempts').insert(dataToInsert);
    } catch (e) {
      debugPrint('Error saving question attempts: $e');
    }
  }

  // --- SKILL MASTERY (RPC) ---
  Future<List<Map<String, dynamic>>> getSkillMastery() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client.rpc('get_user_skill_mastery', params: {'user_uuid': user.id});
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching skill mastery: $e');
      return [];
    }
  }

  // --- PHASE 3: MOCK EXAM LOGIC ---
  Future<List<Map<String, dynamic>>> getMockExamQuestions({int limit = 20}) async {
    try {
      final response = await _client
          .from('questions')
          .select('*, skill_areas(title)') 
          .limit(100); 
      
      final List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(response);
      questions.shuffle();
      return questions.take(limit).toList();
    } catch (e) {
      debugPrint('Error fetching mock exam questions: $e');
      return [];
    }
  }

  Future<void> saveMockExamResult({
    required int score,
    required int totalQuestions,
    required bool passed,
    required int timeTakenSeconds,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('exam_results').insert({
        'user_id': user.id,
        'score': score,
        'total_questions': totalQuestions,
        'passed': passed,
        'time_taken_seconds': timeTakenSeconds,
      });
    } catch (e) {
      debugPrint('Error saving exam result: $e');
    }
  }

  Future<bool> hasPassedFinalExam() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('exam_results')
          .select('passed')
          .eq('user_id', user.id)
          .eq('passed', true)
          .limit(1);
          
      return response.isNotEmpty; 
    } catch (e) {
      debugPrint('Error checking final exam status: $e');
      return false;
    }
  }

  Future<DateTime?> getLastFailedExamTime() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('exam_results')
          .select('created_at')
          .eq('user_id', user.id)
          .eq('passed', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
          
      if (response != null && response['created_at'] != null) {
        return DateTime.parse(response['created_at']);
      }
      return null;
    } catch (e) {
      debugPrint('Error checking exam cooldown: $e');
      return null;
    }
  }

  // --- LEADERBOARD ---
  Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await _client.rpc('get_leaderboard');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      return [];
    }
  }

  // --- ADMIN & CONTENT MANAGEMENT ---
  Future<bool> isUserAdmin() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      final response = await _client.from('users').select('is_admin').eq('id', user.id).single();
      return response['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addLevel({required String title, required String description, required int levelOrder, required int passingPercentage}) async {
    await _client.from('levels').insert({
      'title': title,
      'description': description,
      'level_order': levelOrder,
      'passing_percentage': passingPercentage,
    });
  }

  Future<void> addQuestion({
    required String levelId,
    required String skillAreaId,
    required String questionText,
    required List<String> answerOptions, 
    required String correctAnswer,
  }) async {
    await _client.from('questions').insert({
      'level_id': levelId,
      'skill_area_id': skillAreaId,
      'question_text': questionText,
      'answer_options': answerOptions, 
      'correct_answer': correctAnswer,
    });
  }
  
  Future<List<Map<String, dynamic>>> getAllSkillAreas() async {
    final response = await _client.from('skill_areas').select();
    return List<Map<String, dynamic>>.from(response);
  }
}