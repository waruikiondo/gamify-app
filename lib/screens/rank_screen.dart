import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/global_providers.dart';

class RankScreen extends ConsumerWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: const Text(
          'GLOBAL RANKING', 
          style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textGrey),
            onPressed: () => ref.invalidate(leaderboardProvider),
          )
        ],
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, stack) => Center(child: Text('Error loading ranks: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (rankings) {
          if (rankings.isEmpty) {
            return const Center(child: Text('No agents ranked yet.', style: TextStyle(color: AppTheme.textGrey)));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(leaderboardProvider),
            color: AppTheme.primary,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: rankings.length,
              itemBuilder: (context, index) {
                final userRank = rankings[index];
                final bool isCurrentUser = userRank['user_id'] == currentUserId;
                final int rankPosition = index + 1;
                
                return _buildRankCard(userRank, rankPosition, isCurrentUser);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRankCard(Map<String, dynamic> user, int rank, bool isCurrentUser) {
    Color rankColor;
    IconData rankIcon;

    // Gamified Rank Tier Colors
    if (rank == 1) {
      rankColor = Colors.amber;
      rankIcon = Icons.emoji_events;
    } else if (rank == 2) {
      rankColor = Colors.grey[400]!;
      rankIcon = Icons.military_tech;
    } else if (rank == 3) {
      rankColor = Colors.brown[300]!;
      rankIcon = Icons.military_tech;
    } else {
      rankColor = AppTheme.textGrey;
      rankIcon = Icons.person;
    }

    // Safely parse numbers from the database
    final int levelsCompleted = int.tryParse(user['levels_completed'].toString()) ?? 0;
    final double totalScore = double.tryParse(user['total_score'].toString()) ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppTheme.primary.withValues(alpha:0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? AppTheme.primary : AppTheme.border,
          width: isCurrentUser ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank Position & Icon
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Icon(rankIcon, color: rankColor, size: 28),
                const SizedBox(height: 4),
                Text('#$rank', style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? 'Agent Anonymous',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 16, 
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCurrentUser ? 'You' : 'Agent', 
                  style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)
                ),
              ],
            ),
          ),
          
          // Score/Levels
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$levelsCompleted LVL',
                style: const TextStyle(color: AppTheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              // FIX: Now displays as total XP (e.g., "Score: 180 XP")
              Text(
                'Score: ${totalScore.toInt()} XP',
                style: const TextStyle(color: AppTheme.textGrey, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}