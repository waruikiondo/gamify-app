import '../providers/global_providers.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart'; // Added for Phase 4 Polish
import '../core/theme.dart';
import '../services/supabase_service.dart';
import 'dashboard_screen.dart'; // Imported to access dashboard providers

final mockQuestionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getMockExamQuestions(limit: 20); 
});

class MockExamScreen extends ConsumerStatefulWidget {
  const MockExamScreen({super.key});

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; 
  bool _isSubmitting = false;

  // Final Boss State Variables
  bool _isExamFinished = false;
  bool _didPass = false;
  int _finalScore = 0;
  int _finalTime = 0;
  List<String> _weakAreas = [];

  static const int _examDurationSeconds = 60 * 60; 
  int _remainingSeconds = _examDurationSeconds;
  Timer? _timer;
  
  // UX Polish: Confetti Controller
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _submitExam(ref.read(mockQuestionsProvider).value ?? []);
      }
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  List<dynamic> _parseOptions(dynamic rawOptions) {
    if (rawOptions is List) return rawOptions;
    if (rawOptions is String) {
      try { return jsonDecode(rawOptions); } catch (_) {}
    }
    return [];
  }

  Future<void> _submitExam(List<Map<String, dynamic>> questions) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    _timer?.cancel();

    int score = 0;
    Map<String, int> failedSkills = {};

    for (int i = 0; i < questions.length; i++) {
      bool isCorrect = false;

      if (_selectedAnswers.containsKey(i)) {
        final options = _parseOptions(questions[i]['answer_options']);
        if (options.isNotEmpty && _selectedAnswers[i]! < options.length) {
          final String selectedText = options[_selectedAnswers[i]!].toString();
          final String correctText = questions[i]['correct_answer']?.toString() ?? '';
          if (selectedText == correctText) isCorrect = true;
        }
      }

      if (isCorrect) {
        score++;
      } else {
        final dynamic skillData = questions[i]['skill_areas'];
        final String skillTitle = (skillData != null && skillData['title'] != null) 
            ? skillData['title'].toString() 
            : 'Core Concepts';
        
        failedSkills[skillTitle] = (failedSkills[skillTitle] ?? 0) + 1;
      }
    }

    final sortedSkills = failedSkills.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final weakAreas = sortedSkills.map((e) => e.key).take(3).toList();

    final double percentage = questions.isEmpty ? 0 : score / questions.length;
    final bool passed = percentage >= 0.8; 
    final int timeTaken = _examDurationSeconds - _remainingSeconds;

    await ref.read(supabaseServiceProvider).saveMockExamResult(
      score: score,
      totalQuestions: questions.length,
      passed: passed,
      timeTakenSeconds: timeTaken,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isExamFinished = true;
        _didPass = passed;
        _finalScore = score;
        _finalTime = timeTaken;
        _weakAreas = weakAreas;
      });
      
      // Trigger confetti if they passed
      if (passed) {
        _confettiController.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(mockQuestionsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: questionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (questions) {
            if (questions.isEmpty) return const Center(child: Text('No mock exam questions available.', style: TextStyle(color: Colors.white)));

            if (_isExamFinished) {
              return _buildResultsScreen(questions.length);
            }

            return _buildActiveExam(questions);
          },
        ),
      ),
    );
  }

  Widget _buildResultsScreen(int totalQuestions) {
    final int percentage = totalQuestions == 0 ? 0 : ((_finalScore / totalQuestions) * 100).toInt();

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _didPass ? Colors.greenAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: _didPass ? Colors.greenAccent : Colors.redAccent, width: 4),
                        ),
                        child: Icon(
                          _didPass ? Icons.workspace_premium : Icons.warning_amber_rounded,
                          color: _didPass ? Colors.greenAccent : Colors.redAccent,
                          size: 80,
                        ),
                      ),
                    );
                  }
                ),
                const SizedBox(height: 32),
                
                Text(
                  _didPass ? 'CERTIFICATION ACHIEVED' : 'EXAM FAILED',
                  style: TextStyle(
                    color: _didPass ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Score', '$_finalScore / $totalQuestions', AppTheme.primary),
                          Container(width: 1, height: 40, color: AppTheme.border),
                          _buildStatColumn('Grade', '$percentage%', _didPass ? Colors.greenAccent : Colors.redAccent),
                          Container(width: 1, height: 40, color: AppTheme.border),
                          _buildStatColumn('Time', _formatTime(_finalTime), AppTheme.textGrey),
                        ],
                      ),
                      
                      if (_weakAreas.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Divider(color: AppTheme.border),
                        ),
                        const Text('AREAS TO REVIEW', style: TextStyle(color: AppTheme.textGrey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        const SizedBox(height: 16),
                        ..._weakAreas.map((skill) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(child: Text(skill, style: const TextStyle(color: Colors.white, fontSize: 16))),
                            ],
                          ),
                        )).toList(),
                      ]
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // Force refresh all dashboard state providers before leaving
                    ref.invalidate(finalExamStatusProvider);
                    ref.invalidate(userJourneyProvider);
                    ref.invalidate(skillMasteryProvider);
                    ref.invalidate(userProfileProvider);
                    
                    context.go('/dashboard');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _didPass ? Colors.green : AppTheme.border,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: Text(
                    _didPass ? 'Claim Certificate' : 'Return to Training',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Confetti Widget overlay
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 50,
          gravity: 0.1,
          colors: const [Colors.amber, Colors.greenAccent, Colors.white],
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: valueColor, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActiveExam(List<Map<String, dynamic>> questions) {
    final currentQuestion = questions[_currentIndex];
    final bool isLastQuestion = _currentIndex == questions.length - 1;

    final String questionText = currentQuestion['question_text']?.toString() ?? '';
    final List<dynamic> options = _parseOptions(currentQuestion['answer_options']);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => _showExitWarning()),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 300 ? Colors.redAccent.withOpacity(0.2) : AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _remainingSeconds < 300 ? Colors.redAccent : AppTheme.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: _remainingSeconds < 300 ? Colors.redAccent : Colors.white),
                    const SizedBox(width: 8),
                    Text(_formatTime(_remainingSeconds), style: TextStyle(color: _remainingSeconds < 300 ? Colors.redAccent : Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Text('Q ${_currentIndex + 1}/${questions.length}', style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(questionText, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
                const SizedBox(height: 40),
                ...List.generate(options.length, (index) {
                  final isSelected = _selectedAnswers[_currentIndex] == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAnswers[_currentIndex] = index),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 20, width: 20,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.textGrey), color: isSelected ? AppTheme.primary : Colors.transparent),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(options[index].toString(), style: const TextStyle(color: Colors.white, fontSize: 16))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(color: AppTheme.background, border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _currentIndex > 0 ? () => setState(() => _currentIndex--) : null,
                child: Text('Previous', style: TextStyle(color: _currentIndex > 0 ? AppTheme.textGrey : Colors.transparent)),
              ),
              ElevatedButton(
                onPressed: isLastQuestion ? () => _submitExam(questions) : () => setState(() => _currentIndex++),
                style: ElevatedButton.styleFrom(backgroundColor: isLastQuestion ? Colors.amber : AppTheme.primary, minimumSize: const Size(160, 56)),
                child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isLastQuestion ? 'Submit Exam' : 'Next Question', style: TextStyle(color: isLastQuestion ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showExitWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Abandon Exam?'),
        content: const Text('Your progress will be lost and this will count as a failed attempt.', style: TextStyle(color: AppTheme.textGrey)),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey))),
          TextButton(onPressed: () {
            _timer?.cancel();
            context.pop(); 
            context.go('/dashboard'); 
          }, child: const Text('Abandon', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}