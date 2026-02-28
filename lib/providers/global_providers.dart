import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(supabaseServiceProvider).getUserProfile();
});

final userJourneyProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) {
    return {
      'totalLevels': 0,
      'completedCount': 0,
      'isFullyComplete': false,
      'nextLevel': null,
      'levels': <Map<String, dynamic>>[],
    };
  }

  // 1. Fetch all levels
  final levelsResponse = await supabase.from('levels').select().order('level_order', ascending: true);
  final List<Map<String, dynamic>> allLevels = List<Map<String, dynamic>>.from(levelsResponse);

  // 2. Fetch the current user's progress
  final progressResponse = await supabase.from('user_level_progress').select().eq('user_id', user.id);
  final List<Map<String, dynamic>> progress = List<Map<String, dynamic>>.from(progressResponse);

  // 3. Map progress records to the static levels
  int completedCount = 0;
  Map<String, dynamic>? nextLevel;
  final List<Map<String, dynamic>> mappedLevels = [];

  for (int i = 0; i < allLevels.length; i++) {
    final level = allLevels[i];
    final levelId = level['id'].toString();
    
    // Find the specific progress record for this level
    final levelProgress = progress.firstWhere(
      (p) => p['level_id'].toString() == levelId,
      orElse: () => <String, dynamic>{},
    );

    bool isUnlocked = i == 0; 
    bool isCompleted = false;

    if (levelProgress.isNotEmpty) {
      isUnlocked = levelProgress['unlocked'] == true;
      isCompleted = levelProgress['completed'] == true;
    }

    if (isCompleted) {
      completedCount++;
    }

    final mappedLevel = {
      ...level,
      'isLocked': !isUnlocked,
      'isCompleted': isCompleted,
    };

    mappedLevels.add(mappedLevel);

    if (!isCompleted && isUnlocked && nextLevel == null) {
      nextLevel = mappedLevel;
    }
  }

  final isFullyComplete = completedCount == allLevels.length && allLevels.isNotEmpty;

  return {
    'totalLevels': allLevels.length,
    'completedCount': completedCount,
    'isFullyComplete': isFullyComplete,
    'nextLevel': nextLevel,
    'levels': mappedLevels,
  };
});

final skillMasteryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getSkillMastery();
});

final finalExamStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  return await ref.read(supabaseServiceProvider).hasPassedFinalExam();
});

// --- UPDATED LEADERBOARD PROVIDER WITH DUMMY RIVALS ---
// This populates the Podium UI and seamlessly blends real users with dummy bots.
final leaderboardProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final currentUserId = supabase.auth.currentUser?.id;
  
  List<Map<String, dynamic>> finalRankings = [];

  try {
    // UPDATED: Added avatar_url to the select query
    final response = await supabase
        .from('profiles')
        .select('id, full_name, total_score, levels_completed, primary_goal, streak, avatar_url')
        .order('total_score', ascending: false)
        .limit(50);
        
    finalRankings = List<Map<String, dynamic>>.from(response).map((user) {
      return {
        'user_id': user['id'],
        'full_name': user['full_name'] ?? 'Agent Anonymous',
        'total_score': (double.tryParse(user['total_score'].toString()) ?? 0.0),
        'levels_completed': user['levels_completed'] ?? 0,
        'title': user['primary_goal'] ?? 'ACADEMY AGENT', 
        'streak': user['streak'] ?? 0,
        'avatar_url': user['avatar_url'], // UPDATED: Passed to the UI
      };
    }).toList();
  } catch (e) {
    print('🚨 SUPABASE LEADERBOARD ERROR: $e');
    // If it fails due to RLS or missing columns, we just proceed with the dummy data below
  }

  // 2. INJECT DUMMY RIVAL AGENTS
  // These bots make the podium look amazing. Real users will surpass them over time.
  final List<Map<String, dynamic>> dummyRivals = [
    {'user_id': 'bot_1', 'full_name': 'Agent Maverick', 'total_score': 15200.0, 'levels_completed': 12, 'title': 'CYBER SPECIALIST', 'streak': 14},
    {'user_id': 'bot_2', 'full_name': 'Agent Ghost', 'total_score': 12500.0, 'levels_completed': 10, 'title': 'CLOUD ARCHITECT', 'streak': 7},
    {'user_id': 'bot_3', 'full_name': 'Agent Cipher', 'total_score': 9800.0, 'levels_completed': 8, 'title': 'NETWORK ENGINEER', 'streak': 3},
    {'user_id': 'bot_4', 'full_name': 'Agent Nova', 'total_score': 4400.0, 'levels_completed': 4, 'title': 'ACADEMY AGENT', 'streak': 5},
    {'user_id': 'bot_5', 'full_name': 'Agent Apex', 'total_score': 2100.0, 'levels_completed': 2, 'title': 'ACADEMY AGENT', 'streak': 1},
  ];

  // Add the rivals to the real rankings
  finalRankings.addAll(dummyRivals);

  // 3. GUARANTEE CURRENT USER IS VISIBLE
  // If the logged-in user hasn't saved their profile yet, they won't be in the DB query.
  // We inject them manually at the bottom so the "Sticky Bottom Bar" always works.
  if (currentUserId != null && !finalRankings.any((user) => user['user_id'] == currentUserId)) {
      finalRankings.add({
        'user_id': currentUserId,
        'full_name': supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'You (Recruit)',
        'total_score': 0.0,
        'levels_completed': 0,
        'title': 'NEW RECRUIT',
        'streak': 0,
      });
  }

  // 4. SORT AND RETURN
  // Sort everyone (real + bots) by score, highest to lowest
  finalRankings.sort((a, b) => (b['total_score'] as double).compareTo(a['total_score'] as double));

  // Return the top 50
  return finalRankings.take(50).toList();
});