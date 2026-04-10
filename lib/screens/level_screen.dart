import '../providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart'; // <-- NEW CACHING IMPORT
import '../core/theme.dart';
import '../services/supabase_service.dart';

// Import our new brain
import '../providers/game_state_provider.dart'; 

final levelQuestionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, levelId) async {
  return ref.read(supabaseServiceProvider).getQuestionsForLevel(levelId);
});

class LevelScreen extends ConsumerStatefulWidget {
  final String levelId;
  const LevelScreen({super.key, required this.levelId});

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _hasSubmitted = false;
  bool _isSavingProgress = false; 
  int _score = 0;
  
  // NEW: List to keep track of every attempt in this session
  final List<Map<String, dynamic>> _questionAttempts = [];

  void _submitAnswer(List<Map<String, dynamic>> questions) {
    if (_selectedIndex == null) return;

    final currentQuestion = questions[_currentIndex];
    final options = currentQuestion['answer_options'] as List<dynamic>;
    final String correctAnswerText = currentQuestion['correct_answer'] as String;
    
    final bool passed = options[_selectedIndex!] == correctAnswerText;

    // Record the attempt for Skill Mastery tracking
    _questionAttempts.add({
      'question_id': currentQuestion['id'],
      'skill_area_id': currentQuestion['skill_area_id'],
      'passed': passed,
    });
    
    setState(() {
      _hasSubmitted = true;
      if (passed) {
        _score++;
      }
    });
  }

  Future<void> _nextQuestion(int totalQuestions) async {
    if (_currentIndex < totalQuestions - 1) {
      setState(() {
        _currentIndex++;
        _selectedIndex = null;
        _hasSubmitted = false;
      });
    } else {
      setState(() => _isSavingProgress = true);

      // 1. Send all our recorded attempts to the database for Skill Mastery
      if (_questionAttempts.isNotEmpty) {
        await ref.read(supabaseServiceProvider).saveQuestionAttempts(_questionAttempts);
      }

      final double percentage = (_score / totalQuestions) * 100;
      
      // 2. Fetch the actual Level object to get dynamic rules (like passing_percentage)
      final levels = await ref.read(levelsProvider.future);
      final currentLevel = levels.firstWhere((l) => l.id == widget.levelId);

      // 3. Let our central GameStateNotifier handle the DB upserts and unlocks
      final passed = await ref.read(gameStateProvider.notifier).evaluateAndUnlockNextLevel(
        currentLevel: currentLevel,
        scorePercentage: percentage,
      );

      if (mounted) {
        setState(() => _isSavingProgress = false);
        _showLevelCompleteDialog(totalQuestions, passed, currentLevel.passingPercentage);
      }
    }
  }

  void _showLevelCompleteDialog(int totalQuestions, bool passed, int requiredPercentage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                color: passed ? Colors.amber : Colors.redAccent,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                passed ? 'Gate Cleared!' : 'Gate Failed',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You scored $_score out of $totalQuestions',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 16),
              ),
              if (!passed)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'A $requiredPercentage% score is required to unlock the next level.', 
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Invalidate journey and skill mastery so the dashboard updates
                  ref.invalidate(userJourneyProvider); 
                  ref.invalidate(skillMasteryProvider);

                  context.pop(); // Close the dialog

                  if (passed) {
                    // Success: Return to dashboard
                    context.go('/dashboard'); 
                  } else {
                    // 🚨 BUG FIX: Failure: Wipe state and instantly restart this exact level 🚨
                    ref.invalidate(levelQuestionsProvider(widget.levelId)); 
                    setState(() {
                      _currentIndex = 0;
                      _score = 0;
                      _selectedIndex = null;
                      _hasSubmitted = false;
                      _isSavingProgress = false;
                      _questionAttempts.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: passed ? AppTheme.primary : AppTheme.border,
                ),
                child: Text(passed ? 'Continue Journey' : 'Try Again'),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(levelQuestionsProvider(widget.levelId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: questionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (questions) {
            if (questions.isEmpty) {
              return const Center(child: Text('No questions found.', style: TextStyle(color: Colors.white)));
            }

            final currentQuestion = questions[_currentIndex];
            final List<dynamic> options = currentQuestion['answer_options'];
            final String correctAnswerText = currentQuestion['correct_answer'];
            final int correctIndex = options.indexOf(correctAnswerText);
            final progress = (_currentIndex + 1) / questions.length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: AppTheme.textGrey),
                        onPressed: () => _showExitWarning(),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: AppTheme.border,
                            color: AppTheme.primary,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text('${_currentIndex + 1}/${questions.length}', 
                        style: const TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SECURITY GATE', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 12),
                        
                        // --- HIGH-PERFORMANCE IMAGE RENDERER START ---
                        if (currentQuestion['image_url'] != null && currentQuestion['image_url'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: currentQuestion['image_url'].toString(),
                                fit: BoxFit.contain,
                                placeholder: (context, url) => const SizedBox(
                                  height: 100, 
                                  child: Center(child: CircularProgressIndicator(color: AppTheme.primary))
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.white54),
                              ),
                            ),
                          ),
                        // --- HIGH-PERFORMANCE IMAGE RENDERER END ---

                        Text(currentQuestion['question_text'] as String, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 40),
                        ...List.generate(options.length, (index) {
                          return _buildOptionCard(
                            text: options[index].toString(),
                            index: index,
                            correctIndex: correctIndex,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                _buildBottomAction(correctIndex, currentQuestion['explanation'] ?? '', questions),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOptionCard({required String text, required int index, required int correctIndex}) {
    final isSelected = _selectedIndex == index;
    final isCorrect = index == correctIndex;

    Color borderColor = AppTheme.border;
    Color bgColor = AppTheme.surface;

    if (_hasSubmitted) {
      if (isCorrect) {
        borderColor = Colors.greenAccent;
      } else if (isSelected) {
        borderColor = Colors.redAccent;
      }
    } else if (isSelected) {
      borderColor = AppTheme.primary;
    }

    return GestureDetector(
      onTap: _hasSubmitted ? null : () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ),
    );
  }

  Widget _buildBottomAction(int correctIndex, String explanation, List<Map<String, dynamic>> questions) {
    if (!_hasSubmitted) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        child: ElevatedButton(
          onPressed: _selectedIndex == null ? null : () => _submitAnswer(questions),
          child: const Text('Check Answer'),
        ),
      );
    }

    final bool gotItRight = _selectedIndex == correctIndex;

    return Container(
      padding: const EdgeInsets.all(24.0),
      color: gotItRight ? Colors.green.withValues(alpha:0.1) : Colors.red.withValues(alpha:0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gotItRight ? 'Correct!' : 'Incorrect', style: TextStyle(color: gotItRight ? Colors.greenAccent : Colors.redAccent, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(explanation, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSavingProgress ? null : () => _nextQuestion(questions.length),
            style: ElevatedButton.styleFrom(backgroundColor: gotItRight ? Colors.green : Colors.redAccent),
            child: _isSavingProgress 
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Leave Session?'),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey))),
          TextButton(onPressed: () { context.pop(); context.go('/dashboard'); }, child: const Text('Leave', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}