import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/access_gate_provider.dart';
import '../services/supabase_service.dart';

final adminLevelQuestionsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, levelId) async {
  return ref.read(supabaseServiceProvider).getQuestionsForLevel(levelId);
});

class AdminQuestionPreviewScreen extends ConsumerWidget {
  final String levelId;
  const AdminQuestionPreviewScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateAsync = ref.watch(accessGateStatusProvider);
    final questionsAsync = ref.watch(adminLevelQuestionsProvider(levelId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: const Text(
          'QUESTION PREVIEW',
          style: TextStyle(color: Colors.cyanAccent, letterSpacing: 2.0, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: gateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.redAccent))),
        data: (gate) {
          if (!gate.isAdmin) {
            return Center(
              child: Text('Access denied.', style: TextStyle(color: AppTheme.textGrey.withValues(alpha: 0.9))),
            );
          }

          return questionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
            error: (e, __) => Center(child: Text('Error loading questions: $e', style: const TextStyle(color: Colors.redAccent))),
            data: (questions) {
              if (questions.isEmpty) {
                return const Center(child: Text('No questions found for this level.', style: TextStyle(color: Colors.white)));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final text = (q['question_text'] ?? '').toString();
                  final options = (q['answer_options'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
                  final correct = (q['correct_answer'] ?? '').toString();

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Q${index + 1}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
                        const SizedBox(height: 12),
                        ...options.map((opt) {
                          final isCorrect = opt == correct;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 16, color: isCorrect ? Colors.greenAccent : AppTheme.textGrey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    opt,
                                    style: TextStyle(
                                      color: isCorrect ? Colors.greenAccent : AppTheme.textGrey,
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

