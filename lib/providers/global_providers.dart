import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(supabaseServiceProvider).getUserProfile();
});

final userJourneyProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  final levels = await supabase.getLevels();
  
  int completedCount = 0;
  Map<String, dynamic>? nextLevel;

  for (var level in levels) {
    final progress = await supabase.getUserProgress(level['id']);
    final isCompleted = progress != null && progress['completed'] == true;
    
    level['isCompleted'] = isCompleted;
    level['isLocked'] = !isCompleted && nextLevel != null; 

    if (isCompleted) {
      completedCount++;
    } else if (nextLevel == null) {
      nextLevel = level;
      level['isLocked'] = false; 
    }
  }

  return {
    'levels': levels,
    'completedCount': completedCount,
    'totalLevels': levels.length,
    'nextLevel': nextLevel,
    'isFullyComplete': completedCount == levels.length,
  };
});

final skillMasteryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getSkillMastery();
});

final finalExamStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  return await ref.read(supabaseServiceProvider).hasPassedFinalExam();
});