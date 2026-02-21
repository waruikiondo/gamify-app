import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import 'dashboard_screen.dart'; // IMPORTANT: Imports the provider from Dashboard

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the global provider defined in dashboard_screen.dart
    final journeyAsync = ref.watch(userJourneyProvider);

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
                  
                  if (levels.isEmpty) {
                    return const Center(child: Text('No levels available yet.', style: TextStyle(color: Colors.white)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      final bool isCompleted = level['isCompleted'] ?? false;
                      final bool isLocked = level['isLocked'] ?? true;
                      
                      return _buildTimelineTile(
                        context,
                        title: level['title'] ?? 'Unknown',
                        description: level['description'] ?? '',
                        isCompleted: isCompleted,
                        isLocked: isLocked,
                        isLast: index == levels.length - 1,
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
    if (isCompleted) nodeColor = Colors.greenAccent;
    else if (!isLocked) nodeColor = AppTheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.greenAccent.withOpacity(0.2) : (isLocked ? AppTheme.surface : AppTheme.primary.withOpacity(0.2)),
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
}