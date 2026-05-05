import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/access_gate_provider.dart';
import '../providers/global_providers.dart';
import 'level_overview_screen.dart' show levelDetailProvider;

class MockExamBriefingScreen extends ConsumerWidget {
  const MockExamBriefingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelAsync = ref.watch(levelDetailProvider(kMockExamPoolLevelId));
    final gateAsync = ref.watch(accessGateStatusProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'MISSION BRIEFING',
          style: TextStyle(
            color: Colors.amberAccent,
            letterSpacing: 2.0,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amberAccent),
        centerTitle: true,
      ),
      body: levelAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amberAccent)),
        error: (err, _) => Center(
          child: Text('SYSTEM ERROR: $err', style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (level) {
          final markdownData = (level.contentMarkdown != null && level.contentMarkdown!.isNotEmpty)
              ? level.contentMarkdown!
              : '### Scope of Assessment\n\n*No briefing data found for the mock exam pool.*';

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FINAL MOCK EXAM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        level.description ?? 'Prove your mastery in the final challenge.',
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Divider(color: AppTheme.border, thickness: 1),
                      const SizedBox(height: 24),
                      MarkdownBody(
                        data: markdownData,
                        styleSheet: MarkdownStyleSheet(
                          h1: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          h2: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          h3: const TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                          p: const TextStyle(color: AppTheme.textGrey, fontSize: 14, height: 1.6),
                          listBullet: const TextStyle(color: Colors.amber, fontSize: 16),
                          strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          code: TextStyle(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            color: Colors.amberAccent,
                            fontFamily: 'monospace',
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: const Color(0xFF0A0F14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.08),
                            border: const Border(left: BorderSide(color: Colors.amber, width: 4)),
                          ),
                          blockquote: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: const Border(top: BorderSide(color: AppTheme.border, width: 1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
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
                    error: (_, __) => _buildButtons(context, isAdmin: false),
                    data: (gate) => _buildButtons(context, isAdmin: gate.isAdmin),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildButtons(BuildContext context, {required bool isAdmin}) {
    final startBtn = SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () => context.push('/mock-exam'),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
        child: const Text(
          'START MOCK EXAM',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );

    if (!isAdmin) return startBtn;

    return Column(
      children: [
        startBtn,
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/level/$kMockExamPoolLevelId/questions'),
            icon: const Icon(Icons.visibility, color: Colors.amberAccent, size: 18),
            label: const Text('VIEW QUESTION POOL', style: TextStyle(color: Colors.amberAccent)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.amberAccent),
            ),
          ),
        ),
      ],
    );
  }
}

