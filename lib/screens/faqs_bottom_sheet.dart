import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';

class FaqsBottomSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const FaqsBottomSheet({super.key, required this.scrollController});

  @override
  ConsumerState<FaqsBottomSheet> createState() => _FaqsBottomSheetState();
}

class _FaqsBottomSheetState extends ConsumerState<FaqsBottomSheet> {
  late Future<List<Map<String, dynamic>>> _faqsFuture;

  @override
  void initState() {
    super.initState();
    _faqsFuture = _fetchFaqs();
  }

  Future<List<Map<String, dynamic>>> _fetchFaqs() async {
    final response = await Supabase.instance.client
        .from('faq_entries')
        .select('question, answer_markdown, sort_order')
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  void _openLink(String? href) {
    if (href == null) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;

    // Fire-and-forget; callback type is non-async.
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _faqsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading FAQs: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
          );
        }

        final faqs = snapshot.data ?? [];
        if (faqs.isEmpty) {
          return const Center(
            child: Text(
              'No FAQs found.',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final linkStyle = TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        );

        return ListView.builder(
          controller: widget.scrollController,
          itemCount: faqs.length,
          padding: const EdgeInsets.all(0),
          itemBuilder: (context, index) {
            final faq = faqs[index];
            final question = (faq['question'] ?? '').toString();
            final answer = (faq['answer_markdown'] ?? '').toString();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                title: Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                collapsedBackgroundColor: AppTheme.surface,
                backgroundColor: AppTheme.surface,
                iconColor: AppTheme.primary,
                collapsedIconColor: AppTheme.primary,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: MarkdownBody(
                      data: answer,
                      onTapLink: (text, href, title) => _openLink(href),
                      styleSheet: MarkdownStyleSheet(
                        a: linkStyle,
                        p: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 14,
                          height: 1.6,
                        ),
                        code: TextStyle(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          color: Colors.pinkAccent,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

