import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/level.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';

// Provider to fetch the list of all levels sorted by order
final levelsProvider = FutureProvider<List<Level>>((ref) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  final data = await supabaseService.getLevels();
  return data.map((json) => Level.fromJson(json)).toList();
});

// The main Game State Notifier
class GameStateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state logic can go here if needed
  }

  /// Evaluates a completed level and handles the unlock logic
  Future<bool> evaluateAndUnlockNextLevel({
    required Level currentLevel,
    required double scorePercentage,
  }) async {
    final supabaseService = ref.read(supabaseServiceProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    
    if (userId == null) return false;

    // FIX APPLIED HERE: Compare raw percentage directly (e.g., 50.0 >= 80)
    final bool passed = scorePercentage >= currentLevel.passingPercentage;

    try {
      // 2. Save the progress for the CURRENT level
      await supabaseService.saveLevelProgress(
        levelId: currentLevel.id,
        scorePercentage: scorePercentage,
        passed: passed,
      );
      ref.read(analyticsServiceProvider).trackLevelCompleted(currentLevel.id, scorePercentage, passed);

      // 3. If passed, find the next level and unlock it
      if (passed) {
        // Get all levels to figure out which one is next
        final allLevelsData = await supabaseService.getLevels();
        final allLevels = allLevelsData.map((j) => Level.fromJson(j)).toList();
        
        // Find the level with the next highest order
        final nextLevels = allLevels.where((l) => l.levelOrder > currentLevel.levelOrder).toList();
        nextLevels.sort((a, b) => a.levelOrder.compareTo(b.levelOrder));

        if (nextLevels.isNotEmpty) {
          final nextLevel = nextLevels.first;
          
          // Upsert progress for the NEXT level to unlock it
          await Supabase.instance.client.from('user_level_progress').upsert({
            'user_id': userId,
            'level_id': nextLevel.id,
            'unlocked': true,
            'completed': false, // Just unlocked, not finished yet
          }, onConflict: 'user_id, level_id');
        }
      }

      // Refresh the providers so the UI updates to show the unlocked level
      ref.invalidate(levelsProvider);
      return passed;

    } catch (e) {
      // FIX APPLIED HERE: Cleared the 'avoid_print' warning
      debugPrint('Error evaluating level progress: $e');
      return false;
    }
  }
}

final gameStateProvider = AsyncNotifierProvider<GameStateNotifier, void>(() {
  return GameStateNotifier();
});