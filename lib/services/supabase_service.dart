import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Provide the SupabaseService globally
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService(Supabase.instance.client);
});

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  /// Fetch all levels ordered by their sequence
  Future<List<Map<String, dynamic>>> getLevels() async {
    try {
      final response = await _client
          .from('levels')
          .select()
          .order('level_order', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching levels: $e');
      return [];
    }
  }

  /// Fetch user progress for all levels, merged with level details
  Future<List<Map<String, dynamic>>> getUserJourney() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      // 1. Fetch all levels
      final levels = await getLevels();
      
      // 2. Fetch progress from YOUR specific table name
      final progressResponse = await _client
          .from('user_level_progress')
          .select()
          .eq('user_id', user.id);
          
      final progressList = List<Map<String, dynamic>>.from(progressResponse);

      // 3. Merge the data
      return levels.map((level) {
        final progress = progressList.firstWhere(
          (p) => p['level_id'] == level['id'], 
          // Default state if no progress record exists yet
          orElse: () => {'unlocked': false, 'completed': false, 'score': 0},
        );

        String status = 'locked';
        if (progress['completed'] == true) {
          status = 'completed';
        } else if (progress['unlocked'] == true) {
          status = 'current';
        } else if (level['level_order'] == 1) {
          // Force Level 1 to always be unlocked for new users
          status = 'current'; 
        }

        return {
          'id': level['id'],
          'level': level['level_order'],
          'title': level['title'],
          'subtitle': level['description'] ?? 'No description', // Map your DB column to the UI
          'status': status,
          // Convert your numeric score into the text format the UI expects
          'score': status == 'locked' ? 'Locked' : 'Score: ${progress['score'] ?? 0}',
        };
      }).toList();

    } catch (e) {
      print('Error fetching journey: $e');
      return [];
    }
  }

  /// Fetch questions for a specific level (gates)
  Future<List<Map<String, dynamic>>> getQuestionsForLevel(String levelId) async {
    try {
      final response = await _client
          .from('questions')
          .select()
          .eq('level_id', levelId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching questions: $e');
      return [];
    }
  }
}