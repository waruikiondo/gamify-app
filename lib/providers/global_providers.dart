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

// THIS FIXES THE RANK_SCREEN ERROR
final leaderboardProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getLeaderboard();
});