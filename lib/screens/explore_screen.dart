import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';

final userJourneyProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabaseService = ref.read(supabaseServiceProvider);
  return await supabaseService.getUserJourney();
});

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsyncValue = ref.watch(userJourneyProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppTheme.background,
            floating: true,
            pinned: true,
            elevation: 0,
            title: const Text(
              'Journey Map',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          journeyAsyncValue.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
            ),
            data: (levels) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final levelData = levels[index];
                      return _buildTimelineTile(
                        context: context,
                        isFirst: index == 0,
                        isLast: index == levels.length - 1,
                        levelId: levelData['id'].toString(),
                        levelNumber: levelData['level'] as int,
                        title: levelData['title'] as String,
                        subtitle: levelData['subtitle'] as String,
                        status: levelData['status'] as String,
                        score: levelData['score'] as String,
                      );
                    },
                    childCount: levels.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildTimelineTile({
    required BuildContext context,
    required bool isFirst,
    required bool isLast,
    required String levelId,
    required int levelNumber,
    required String title,
    required String subtitle,
    required String status,
    required String score,
  }) {
    final bool isCurrent = status == 'current';
    final bool isCompleted = status == 'completed';
    final bool isLocked = status == 'locked';

    return IntrinsicHeight(
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(child: Container(width: 4, color: isFirst ? Colors.transparent : AppTheme.primary)),
                Container(
                  height: 32, width: 32,
                  decoration: BoxDecoration(
                    color: isLocked ? AppTheme.background : AppTheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: isLocked ? AppTheme.border : AppTheme.primary, width: 3),
                  ),
                  child: Icon(isCompleted ? Icons.check : (isLocked ? Icons.lock : Icons.play_arrow), color: Colors.white, size: 16),
                ),
                Expanded(child: Container(width: 4, color: isLast ? Colors.transparent : AppTheme.primary)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Opacity(
                opacity: isLocked ? 0.5 : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFF1E1A3A) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isCurrent ? AppTheme.primary : AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LEVEL $levelNumber', style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(subtitle, style: const TextStyle(color: AppTheme.textGrey, fontSize: 14)),
                      if (isCurrent) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/level/$levelId'),
                          child: const Center(child: Text('Start Chapter')),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}