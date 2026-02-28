import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/global_providers.dart';

class RankScreen extends ConsumerStatefulWidget {
  const RankScreen({super.key});

  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen> {
  // Helper to format numbers like 15200 to 15.2k
  String _formatXP(double xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}k';
    }
    return xp.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF0A191E), // Matching the dark teal from your design
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Ensures no default back button appears
        title: const Text(
          'Global Leaderboard', 
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: leaderboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (rankings) {
          if (rankings.isEmpty) return const Center(child: Text('No agents ranked yet.', style: TextStyle(color: Colors.white)));

          // Find current user's rank
          int currentUserRank = -1;
          Map<String, dynamic>? currentUserData;
          for (int i = 0; i < rankings.length; i++) {
            if (rankings[i]['user_id'] == currentUserId) {
              currentUserRank = i + 1;
              currentUserData = rankings[i];
              break;
            }
          }

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async => ref.invalidate(leaderboardProvider),
                color: Colors.cyanAccent,
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          const SizedBox(height: 16), // Added a little top padding where the tabs used to be
                          if (rankings.isNotEmpty) _buildPodium(rankings),
                          const SizedBox(height: 32),
                          _buildListHeader(),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100), // Padding for sticky bottom bar
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Start listing from rank #4
                            final realIndex = index + 3;
                            if (realIndex >= rankings.length) return null;
                            return _buildListTile(rankings[realIndex], realIndex + 1, currentUserId);
                          },
                          childCount: rankings.length > 3 ? rankings.length - 3 : 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Sticky Bottom Bar for Current User
              if (currentUserData != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildStickyBottomBar(currentUserData, currentUserRank),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<dynamic> rankings) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Rank 2 (Silver)
          if (rankings.length > 1) 
            Expanded(child: _buildPodiumAvatar(rankings[1], 2, Colors.grey[400]!, 80)),
          
          // Rank 1 (Gold) - Largest
          Expanded(child: _buildPodiumAvatar(rankings[0], 1, Colors.amber, 110)),
          
          // Rank 3 (Bronze)
          if (rankings.length > 2) 
            Expanded(child: _buildPodiumAvatar(rankings[2], 3, Colors.deepOrange[300]!, 80)),
        ],
      ),
    );
  }
Widget _buildPodiumAvatar(Map<String, dynamic> user, int rank, Color color, double size) {
    final double totalScore = double.tryParse(user['total_score'].toString()) ?? 0.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: rank == 1 ? 4 : 2),
                boxShadow: rank == 1 ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 20)] : [],
              ),
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: Colors.white24,
                backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                child: user['avatar_url'] == null 
                    ? Icon(Icons.person, size: size / 2, color: Colors.white) 
                    : null, 
              ),
            ),
            // Rank Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            if (rank == 1)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(Icons.workspace_premium, color: color, size: 28),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          user['full_name']?.split(' ')[0] ?? 'Agent',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${_formatXP(totalScore)} XP',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }


  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOP RANKINGS', 
            style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('Updates daily', style: TextStyle(color: Colors.tealAccent, fontSize: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> user, int rank, String? currentUserId) {
    final bool isCurrentUser = user['user_id'] == currentUserId;
    final double totalScore = double.tryParse(user['total_score'].toString()) ?? 0.0;
    
    // Fallbacks for data we don't have yet
    final String title = user['title'] ?? 'ACADEMY AGENT';
    final int streak = user['streak'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.cyanAccent.withOpacity(0.1) : const Color(0xFF162529),
        borderRadius: BorderRadius.circular(24),
        border: isCurrentUser ? Border.all(color: Colors.cyanAccent, width: 1) : null,
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 30,
            child: Text(
              '#$rank', 
              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          ),
          
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
            child: user['avatar_url'] == null 
                ? const Icon(Icons.person, color: Colors.white, size: 20)
                : null,
          ),
          const SizedBox(width: 16),
          
          // Name & Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['full_name'] ?? 'Anonymous',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.grey, size: 12),
                    const SizedBox(width: 4),
                    Text(title.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          
          // XP & Streak
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_formatXP(totalScore)} XP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                  Text('$streak', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(Map<String, dynamic> user, int rank) {
    final double totalScore = double.tryParse(user['total_score'].toString()) ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.cyanAccent,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('#$rank', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 16),
           CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
              child: user['avatar_url'] == null 
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('YOU', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('TOP 15% OF LEARNERS', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_formatXP(totalScore)} XP', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 12),
                    Text(' Keep it up!', style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}