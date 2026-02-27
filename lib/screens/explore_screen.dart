import '../providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the global providers
    final journeyAsync = ref.watch(userJourneyProvider);
    final hasPassedExamAsync = ref.watch(finalExamStatusProvider);
    
    final bool hasPassedFinal = hasPassedExamAsync.value ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text('Exploration Map', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: journeyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
                error: (err, stack) => Center(child: Text('Error loading map: $err', style: const TextStyle(color: Colors.redAccent))),
                data: (journeyData) {
                  final List<dynamic> levels = journeyData['levels'];
                  final bool isFullyComplete = journeyData['isFullyComplete'] ?? false;
                  
                  if (levels.isEmpty) {
                    return const Center(child: Text('No levels available yet.', style: TextStyle(color: Colors.white)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    // We add +1 to the length to append our Final Exam node at the very end
                    itemCount: levels.length + 1,
                    itemBuilder: (context, index) {
                      
                      // If we are at the very end of the list, render the Final Boss Node!
                      if (index == levels.length) {
                        return _buildFinalBossTile(
                          context, 
                          isUnlocked: isFullyComplete, 
                          hasPassed: hasPassedFinal
                        );
                      }

                      // Otherwise, render the standard chapters
                      final level = levels[index];
                      final bool isCompleted = level['isCompleted'] ?? false;
                      final bool isLocked = level['isLocked'] ?? true;
                      
                      return _buildTimelineTile(
                        context,
                        title: level['title'] ?? 'Unknown',
                        description: level['description'] ?? '',
                        isCompleted: isCompleted,
                        isLocked: isLocked,
                        // Normal levels are never the last item anymore, the Final Exam is.
                        isLast: false, 
                        levelId: level['id'],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile(BuildContext context, {
    required String title,
    required String description,
    required bool isCompleted,
    required bool isLocked,
    required bool isLast,
    required String levelId,
  }) {
    Color nodeColor = AppTheme.border;
    
    if (isCompleted) {
      nodeColor = Colors.greenAccent;
    } else if (!isLocked) {
      nodeColor = AppTheme.primary;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.greenAccent.withValues(alpha:0.2) : (isLocked ? AppTheme.surface : AppTheme.primary.withValues(alpha:0.2)),
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Icon(
                  isCompleted ? Icons.check : (isLocked ? Icons.lock : Icons.play_arrow),
                  size: 16, color: nodeColor,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: isCompleted ? Colors.greenAccent : AppTheme.border)),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Opacity(
              opacity: isLocked ? 0.5 : 1.0,
              child: Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                    const SizedBox(height: 16),
                    if (!isLocked && !isCompleted)
                      ElevatedButton(
                        onPressed: () => context.push('/level/$levelId'),
                        child: const Text('Start Chapter'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- THE NEW FINAL EXAM NODE ---
  Widget _buildFinalBossTile(BuildContext context, {required bool isUnlocked, required bool hasPassed}) {
    Color nodeColor = hasPassed ? Colors.amber : (isUnlocked ? Colors.amberAccent : AppTheme.border);
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: hasPassed ? Colors.amber.withValues(alpha: 0.2) : (isUnlocked ? Colors.amberAccent.withValues(alpha: 0.2) : AppTheme.surface),
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Icon(
                  hasPassed ? Icons.emoji_events : (isUnlocked ? Icons.warning_amber_rounded : Icons.lock),
                  size: 16, color: nodeColor,
                ),
              ),
              // We omit the vertical line completely here because this is the absolute end of the timeline!
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Opacity(
              opacity: isUnlocked ? 1.0 : 0.5,
              child: Container(
                margin: const EdgeInsets.only(bottom: 32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: hasPassed ? Colors.amber.withValues(alpha: 0.05) : (isUnlocked ? const Color(0xFF1E1A3A) : AppTheme.surface), 
                  borderRadius: BorderRadius.circular(16), 
                  border: Border.all(
                    color: hasPassed ? Colors.amber : (isUnlocked ? Colors.amberAccent : AppTheme.border), 
                    width: isUnlocked ? 2 : 1
                  )
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPassed ? 'CERTIFICATION CLEARED' : 'FINAL CHALLENGE', 
                      style: TextStyle(
                        color: hasPassed ? Colors.amber : (isUnlocked ? Colors.amberAccent : AppTheme.textGrey), 
                        fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold
                      )
                    ),
                    const SizedBox(height: 8),
                    const Text('Mock Exam', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      hasPassed ? 'You have successfully conquered the final challenge.' : 'Prove your mastery to earn your certification. This will test everything you have learned.', 
                      style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)
                    ),
                    const SizedBox(height: 16),
                    
                    // Button if Unlocked but not yet passed
                    if (isUnlocked && !hasPassed)
                      ElevatedButton(
                        onPressed: () => context.push('/mock-exam'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('START EXAM', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20, color: Colors.black),
                          ],
                        ),
                      ),
                      
                    // Optional: A 'Retake' button if they already passed but want to practice
                    if (hasPassed)
                       ElevatedButton(
                        onPressed: () => context.push('/mock-exam'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.border),
                        child: const Text('Retake Exam', style: TextStyle(color: Colors.white)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}