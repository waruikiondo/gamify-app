import '../providers/global_providers.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:confetti/confetti.dart'; 
import 'package:cached_network_image/cached_network_image.dart'; // <-- NEW CACHING IMPORT
import '../core/theme.dart';
import '../services/supabase_service.dart';
import '../services/analytics_service.dart';

final mockQuestionsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getMockExamQuestions(limit: 20); 
});

// Provider to check if the user is currently on a 24-hour cooldown
final examEligibilityProvider = FutureProvider.autoDispose<DateTime?>((ref) async {
  return await ref.read(supabaseServiceProvider).getLastFailedExamTime();
});

class MockExamScreen extends ConsumerStatefulWidget {
  const MockExamScreen({super.key});

  @override
  ConsumerState<MockExamScreen> createState() => _MockExamScreenState();
}

class _MockExamScreenState extends ConsumerState<MockExamScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {}; 
  bool _isSubmitting = false;

  // Final Boss State Variables
  bool _isExamFinished = false;
  bool _didPass = false;
  int _finalScore = 0;
  int _finalTime = 0;
  List<String> _weakAreas = [];

  // Post-exam FAA follow-up questions (null = not answered)
  bool? _faaScheduled;
  bool? _faaPassed;
  bool _followUpSaved = false;

  static const int _examDurationSeconds = 60 * 60; 
  int _remainingSeconds = _examDurationSeconds;
  Timer? _timer;
  
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  // --- THE ANTI-CHEAT ENGINE ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (_timer != null && _timer!.isActive && !_isExamFinished && !_isSubmitting) {
        _triggerAntiCheatPenalty();
      }
    }
  }

  Future<void> _triggerAntiCheatPenalty() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);
    ref.read(analyticsServiceProvider).trackAntiCheatTriggered();

    final questions = ref.read(mockQuestionsProvider).value ?? [];
    
    await ref.read(supabaseServiceProvider).saveMockExamResult(
      score: 0,
      totalQuestions: questions.length,
      passed: false,
      timeTakenSeconds: _examDurationSeconds - _remainingSeconds,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isExamFinished = true;
        _didPass = false;
        _finalScore = 0;
        _finalTime = _examDurationSeconds - _remainingSeconds;
        _weakAreas = ['Exam Protocol Violation']; 
      });
      
      _showAntiCheatDialog();
    }
  }

  void _showAntiCheatDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.redAccent, width: 2)),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('ANTI-CHEAT TRIGGERED', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        content: const Text(
          'You navigated away from the application during an active Final Boss Exam. This violates exam protocol.\n\nYour exam has been automatically terminated and the 24-hour recovery cooldown has been applied.', 
          style: TextStyle(color: Colors.white, height: 1.5)
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              ref.invalidate(finalExamStatusProvider);
              ref.invalidate(examEligibilityProvider);
              context.pop(); 
              context.go('/dashboard'); 
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Acknowledge', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }
  // --- END ANTI-CHEAT ENGINE ---

  void _startTimerSafe() {
    if (_timer != null && _timer!.isActive) return; 
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

    ref.read(analyticsServiceProvider).trackExamCompleted(score, passed, timeTaken);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isExamFinished = true;
        _didPass = passed;
        _finalScore = score;
        _finalTime = timeTaken;
        _weakAreas = weakAreas;
      });
      
      if (passed) {
        _confettiController.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eligibilityAsync = ref.watch(examEligibilityProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: eligibilityAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
          error: (err, stack) => Center(child: Text('Error checking eligibility: $err', style: const TextStyle(color: Colors.redAccent))),
          data: (lastFailedTime) {
            
            if (lastFailedTime != null) {
              final cooldownEnd = lastFailedTime.add(const Duration(hours: 24));
              final now = DateTime.now();
              if (now.isBefore(cooldownEnd)) {
                return _buildCooldownScreen(cooldownEnd.difference(now));
              }
            }

            final questionsAsync = ref.watch(mockQuestionsProvider);
            return questionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
              data: (questions) {
                if (questions.isEmpty) return const Center(child: Text('No mock exam questions available.', style: TextStyle(color: Colors.white)));

                if (_isExamFinished) {
                  return _buildResultsScreen(questions.length);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) => _startTimerSafe());

                return _buildActiveExam(questions);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCooldownScreen(Duration timeLeft) {
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock, size: 80, color: Colors.redAccent),
            const SizedBox(height: 24),
            const Text(
              'RECOVERY PERIOD',
              style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            const Text(
              'You must wait before attempting the Final Exam again. Use this time to review your weak areas in the previous chapters.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textGrey, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                'Unlocks in $hours hr $minutes min',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.pop(),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text('Return to Dashboard'),
            ),
          ],
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
                          color: _didPass ? Colors.greenAccent.withValues(alpha:0.1) : Colors.redAccent.withValues(alpha:0.1),
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
                  _didPass ? 'READY FOR THE FAA' : 'EXAM FAILED',
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
                        )),
                      ]
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),

                // --- FAA FOLLOW-UP QUESTIONS (OPTIONAL) ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.help_outline, color: AppTheme.primary, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'QUICK CHECK-IN',
                            style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                          ),
                          const Spacer(),
                          Text(
                            'Optional',
                            style: TextStyle(color: AppTheme.textGrey, fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFollowUpQuestion(
                        question: 'Have you scheduled the FAA Part 107 exam?',
                        value: _faaScheduled,
                        onChanged: (val) {
                          setState(() => _faaScheduled = val);
                          _saveFaaFollowUp();
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFollowUpQuestion(
                        question: 'Have you taken the FAA Part 107 exam and passed?',
                        value: _faaPassed,
                        onChanged: (val) {
                          setState(() => _faaPassed = val);
                          _saveFaaFollowUp();
                        },
                      ),
                      if (_followUpSaved) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                            SizedBox(width: 6),
                            Text('Saved — thanks!', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // --- END FAA FOLLOW-UP ---

                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
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
                    _didPass ? 'Steps to Get Certified' : 'Return to Training',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildFollowUpQuestion({
    required String question,
    required bool? value,
    required void Function(bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildYesNoButton(label: 'Yes', selected: value == true, onTap: () => onChanged(true)),
            const SizedBox(width: 8),
            _buildYesNoButton(label: 'No', selected: value == false, onTap: () => onChanged(false)),
          ],
        ),
      ],
    );
  }

  Widget _buildYesNoButton({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.primary : AppTheme.textGrey,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
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
              IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => _showExitWarning(questions.length)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _remainingSeconds < 300 ? Colors.redAccent.withValues(alpha:0.2) : AppTheme.surface,
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
                
                // --- NEW HIGH-PERFORMANCE IMAGE RENDERER START ---
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
                // --- NEW HIGH-PERFORMANCE IMAGE RENDERER END ---

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
                        color: isSelected ? AppTheme.primary.withValues(alpha:0.1) : AppTheme.surface,
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
          decoration: BoxDecoration(color: AppTheme.background, border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha:0.5)))),
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

  Future<void> _saveFaaFollowUp() async {
    if (_followUpSaved) return;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.from('profiles').update({
        if (_faaScheduled != null) 'faa_exam_scheduled': _faaScheduled,
        if (_faaPassed != null) 'faa_exam_passed': _faaPassed,
      }).eq('id', userId);
      if (mounted) setState(() => _followUpSaved = true);
    } catch (e) {
      debugPrint('FAA follow-up save failed (columns may not exist yet): $e');
    }
  }

  void _showExitWarning(int totalQuestions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Abandon Exam?'),
        content: const Text(
          'Your progress will be lost and this will trigger a 24-hour cooldown penalty.', 
          style: TextStyle(color: AppTheme.textGrey)
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('Cancel', style: TextStyle(color: AppTheme.textGrey))),
          TextButton(
            onPressed: () async {
              _timer?.cancel();
              
              await ref.read(supabaseServiceProvider).saveMockExamResult(
                score: 0,
                totalQuestions: totalQuestions,
                passed: false,
                timeTakenSeconds: _examDurationSeconds - _remainingSeconds,
              );
              
              if (context.mounted) {
                context.pop(); 
                context.go('/dashboard'); 
              }
            }, 
            child: const Text('Abandon', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}