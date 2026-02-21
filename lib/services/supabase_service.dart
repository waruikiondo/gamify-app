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
      final response = await _client.from('users').select().eq('id', user.id).single();
      return response;
    } catch (e) {
      print('Error fetching profile: $e');
      return {'full_name': 'Agent', 'rank': 'Novice'}; 
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

  // --- SKILL MASTERY (RPC) ---
  Future<List<Map<String, dynamic>>> getSkillMastery() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _client.rpc('get_user_skill_mastery', params: {'user_uuid': user.id});
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching skill mastery: $e');
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
      print('Error fetching mock exam questions: $e');
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
      print('Error saving exam result: $e');
    }
  }

  // Check if the user has successfully passed the Mock Exam
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
      print('Error checking final exam status: $e');
      return false;
    }
  }
}