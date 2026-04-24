import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme.dart';
import '../models/level.dart';
import '../providers/access_gate_provider.dart';

// --- NEW: Fetch the specific level details directly from Supabase ---
final levelDetailProvider = FutureProvider.autoDispose.family<Level, String>((ref, levelId) async {
  final response = await Supabase.instance.client
      .from('levels')
      .select()
      .eq('id', levelId)
      .single();
      
  return Level.fromJson(response);
});

class LevelOverviewScreen extends ConsumerWidget {
  final String levelId;

  const LevelOverviewScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(levelDetailProvider(levelId));
    final gateAsync = ref.watch(accessGateStatusProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'MISSION BRIEFING', 
          style: TextStyle(
            color: Colors.cyanAccent, 
            letterSpacing: 2.0, 
            fontSize: 14, 
            fontWeight: FontWeight.bold
          )
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        centerTitle: true,
      ),
      body: levelAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent)
        ),
        error: (err, stack) => Center(
          child: Text(
            'SYSTEM ERROR: $err', 
            style: const TextStyle(color: Colors.redAccent)
          )
        ),
        data: (level) {
          // Fallback text just in case the SQL update missed a row
          final String markdownData = level.contentMarkdown != null && level.contentMarkdown!.isNotEmpty
              ? level.contentMarkdown!
              : '### Scope of Assessment\n\n*No briefing data found in the database for this module.*';

          return Column(
            children: [
              // --- SCROLLABLE CONTENT AREA ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Level Title
                      Text(
                        level.title.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 28, 
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Level Description
                      Text(
                        level.description ?? 'Prepare for the assessment.',
                        style: const TextStyle(
                          color: AppTheme.textGrey, 
                          fontSize: 16, 
                          height: 1.5
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      const Divider(color: AppTheme.border, thickness: 1),
                      const SizedBox(height: 24),
                      
                      // --- THE CYBERPUNK MARKDOWN RENDERER ---
                      MarkdownBody(
                        data: markdownData,
                        styleSheet: MarkdownStyleSheet(
                          h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          h3: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          p: const TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.6),
                          listBullet: const TextStyle(color: AppTheme.primary, fontSize: 16),
                          strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          code: TextStyle(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            color: Colors.pinkAccent,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: const Color(0xFF0A0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            border: const Border(left: BorderSide(color: AppTheme.primary, width: 4)),
                          ),
                          blockquote: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // --- FIXED BOTTOM GATEWAY BUTTON ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: const Border(
                    top: BorderSide(color: AppTheme.border, width: 1)
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ]
                ),
                child: SafeArea(
                  child: gateAsync.when(
                    loading: () => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: null,
                        child: const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    ),
                    error: (_, ___) => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _buildAssessmentButton(context, level.id, isAdmin: false),
                    ),
                    data: (gate) {
                      if (!gate.isAdmin) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: _buildAssessmentButton(context, level.id, isAdmin: false),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 56,
                            child: _buildAssessmentButton(context, level.id, isAdmin: true),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 56,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.cyanAccent,
                                side: const BorderSide(color: Colors.cyanAccent),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => context.push('/level/${level.id}/questions'),
                              child: const Text('VIEW QUESTIONS'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAssessmentButton(BuildContext context, String levelId, {required bool isAdmin}) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 10,
        shadowColor: AppTheme.primary.withValues(alpha: 0.5),
      ),
      onPressed: () {
        // Admins can still run the assessment, but also have a read-only preview route.
        context.push('/level/$levelId/assessment');
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isAdmin ? Icons.visibility : Icons.bolt, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            isAdmin ? 'PREVIEW ASSESSMENT' : 'INITIALIZE ASSESSMENT',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}