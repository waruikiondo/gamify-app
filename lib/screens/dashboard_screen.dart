import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';
import 'explore_screen.dart'; 
import 'rank_screen.dart';     // NEW
import 'profile_screen.dart';  // NEW

// --- GLOBAL STATE PROVIDERS ---
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(supabaseServiceProvider).getUserProfile();
});

final userJourneyProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  final levels = await supabase.getLevels();
  
  int completedCount = 0;
  Map<String, dynamic>? nextLevel;

  for (var level in levels) {
    final progress = await supabase.getUserProgress(level['id']);
    final isCompleted = progress != null && progress['completed'] == true;
    
    level['isCompleted'] = isCompleted;
    level['isLocked'] = !isCompleted && nextLevel != null; 

    if (isCompleted) {
      completedCount++;
    } else if (nextLevel == null) {
      nextLevel = level;
      level['isLocked'] = false; 
    }
  }

  return {
    'levels': levels,
    'completedCount': completedCount,
    'totalLevels': levels.length,
    'nextLevel': nextLevel,
    'isFullyComplete': completedCount == levels.length,
  };
});

final skillMasteryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getSkillMastery();
});

final finalExamStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  return await ref.read(supabaseServiceProvider).hasPassedFinalExam();
});


class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Color> _skillColors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
    Colors.tealAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            const ExploreScreen(),
            const RankScreen(),    // REPLACED PLACEHOLDER
            const ProfileScreen(), // REPLACED PLACEHOLDER
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab() {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Agent';
    
    final journeyAsyncValue = ref.watch(userJourneyProvider);
    final skillsAsyncValue = ref.watch(skillMasteryProvider); 
    final hasPassedExamAsync = ref.watch(finalExamStatusProvider);
    final bool hasPassedFinal = hasPassedExamAsync.value ?? false;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(userJourneyProvider);
        ref.invalidate(skillMasteryProvider);
        ref.invalidate(finalExamStatusProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome back,', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                        Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.settings, color: AppTheme.textGrey),
                  onPressed: () => setState(() => _currentIndex = 3), // Route to Profile tab
                ),
              ],
            ),
            const SizedBox(height: 32),

            // STREAK BADGE
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                    SizedBox(width: 4),
                    Text('0 Days', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            // --- OVERALL PROGRESS ---
            journeyAsyncValue.when(
              loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: Center(child: CircularProgressIndicator(color: AppTheme.primary))),
              error: (err, stack) => Padding(padding: const EdgeInsets.symmetric(vertical: 40.0), child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent)))),
              data: (journeyData) {
                final int totalLevels = journeyData['totalLevels'];
                final int completedLevels = journeyData['completedCount'];
                final double overallProgress = totalLevels > 0 ? completedLevels / totalLevels : 0.0;
                final bool isFullyComplete = journeyData['isFullyComplete'];
                
                final currentLevel = journeyData['nextLevel'] ?? {
                  'level_order': totalLevels,
                  'title': 'All Chapters Complete!',
                  'description': 'You are ready for the Final Exam.'
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200, height: 200,
                            child: CircularProgressIndicator(
                              value: overallProgress, strokeWidth: 12, backgroundColor: AppTheme.border,
                              color: isFullyComplete ? Colors.greenAccent : AppTheme.primary, strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isFullyComplete ? Icons.workspace_premium : Icons.military_tech, color: isFullyComplete ? Colors.greenAccent : AppTheme.primary, size: 32),
                              const SizedBox(height: 8),
                              Text('Lvl ${currentLevel['level_order']}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(isFullyComplete ? 'MAX RANK' : 'CURRENT PHASE', style: TextStyle(color: isFullyComplete ? Colors.greenAccent : AppTheme.primary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('$completedLevels / $totalLevels Levels', style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // CERTIFICATE OR UP NEXT CARD
                    if (hasPassedFinal)
                      _buildCertificateCard(context)
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFF1E1A3A), borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.primary.withOpacity(0.3))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isFullyComplete ? 'JOURNEY COMPLETE' : 'UP NEXT', style: const TextStyle(color: AppTheme.primary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                Icon(isFullyComplete ? Icons.done_all : Icons.lock_outline, color: AppTheme.textGrey.withOpacity(0.5), size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Chapter ${currentLevel['level_order']}:\n${currentLevel['title']}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppTheme.textGrey, size: 14),
                                const SizedBox(width: 4),
                                Expanded(child: Text(currentLevel['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12))),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: isFullyComplete 
                                ? () => context.push('/mock-exam') 
                                : () => context.push('/level/${currentLevel['id']}'), 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFullyComplete ? Colors.amber : AppTheme.primary,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(isFullyComplete ? 'START FINAL EXAM' : 'Start Session', 
                                    style: TextStyle(color: isFullyComplete ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                                  const SizedBox(width: 8),
                                  Icon(isFullyComplete ? Icons.warning_amber_rounded : Icons.arrow_forward, 
                                    size: 20, color: isFullyComplete ? Colors.black : Colors.white),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 32),

            // --- DYNAMIC SKILL MASTERY ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Skill Mastery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    // Activate "View All" button
                    final skills = skillsAsyncValue.value ?? [];
                    _showAllSkillsBottomSheet(context, skills, hasPassedFinal);
                  }, 
                  child: const Text('View All', style: TextStyle(color: AppTheme.primary, fontSize: 12))
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            skillsAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              error: (err, stack) => Text('Error loading skills: $err', style: const TextStyle(color: Colors.redAccent)),
              data: (skills) {
                if (skills.isEmpty) {
                  return const Text('Complete levels to reveal your skill mastery!', style: TextStyle(color: AppTheme.textGrey));
                }

                final displaySkills = skills.take(3).toList();

                return Row(
                  children: List.generate(displaySkills.length, (index) {
                    final skill = displaySkills[index];
                    final color = _skillColors[index % _skillColors.length];
                    
                    // Fixed Parsing and Override logic
                    final String title = skill['skill_title']?.toString() ?? skill['title']?.toString() ?? 'Skill Area';
                    
                    double mastery = 0.0;
                    if (hasPassedFinal) {
                      mastery = 1.0; // Force 100% if certified
                    } else {
                      final masteryNum = skill['mastery_percentage'] ?? 0;
                      double rawMastery = masteryNum is int ? masteryNum.toDouble() : (masteryNum as double);
                      mastery = rawMastery > 1.0 ? rawMastery / 100.0 : rawMastery; // Convert to 0.0 - 1.0 scale safely
                    }
                    
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index < displaySkills.length - 1 ? 12.0 : 0.0),
                        child: _buildSkillCard(title.replaceAll(' ', '\n'), mastery, color),
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  void _showAllSkillsBottomSheet(BuildContext context, List<Map<String, dynamic>> skills, bool hasPassedFinal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("All Skills", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close, color: AppTheme.textGrey), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(color: AppTheme.border, height: 32),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: skills.length,
                  itemBuilder: (context, index) {
                    final skill = skills[index];
                    final color = _skillColors[index % _skillColors.length];
                    final String title = skill['skill_title']?.toString() ?? skill['title']?.toString() ?? 'Skill Area';
                    
                    double mastery = 0.0;
                    if (hasPassedFinal) {
                      mastery = 1.0;
                    } else {
                      final val = skill['mastery_percentage'] ?? 0;
                      double raw = val is int ? val.toDouble() : (val as double);
                      mastery = raw > 1.0 ? raw / 100.0 : raw;
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                            child: Icon(Icons.stars, color: color),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: mastery,
                                  backgroundColor: AppTheme.border,
                                  color: color,
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('${(mastery * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.2), AppTheme.primary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CERTIFICATION ACHIEVED', style: TextStyle(color: Colors.amber, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Official Cloud\nArchitect', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.verified, color: Colors.greenAccent, size: 14),
              SizedBox(width: 4),
              Expanded(child: Text('All requirements met and verified.', style: TextStyle(color: Colors.greenAccent, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showCertificateDialog(context), 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('View Certificate', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.download, size: 20, color: Colors.black),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCertificateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        contentPadding: const EdgeInsets.all(32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.amber, width: 2)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('CERTIFICATE OF COMPLETION', textAlign: TextAlign.center, style: TextStyle(color: Colors.amber, fontSize: 12, letterSpacing: 2)),
            const SizedBox(height: 16),
            const Text('Cloud Architect', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Has successfully passed the Final Boss Mock Exam and demonstrated mastery in the subject matter.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), 
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.border),
              child: const Text('Close'),
            )
          ],
        ),
      )
    );
  }

  Widget _buildSkillCard(String title, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: AppTheme.border,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
                Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: BoxDecoration(color: AppTheme.background, border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_filled, 'Home', 0),
          _buildNavItem(Icons.explore_outlined, 'Explore', 1),
          
          // --- THE FUNCTIONAL PLAY BUTTON ---
          GestureDetector(
            onTap: () {
              // 1. Get the current journey state
              final journeyData = ref.read(userJourneyProvider).value;
              if (journeyData != null) {
                final isFullyComplete = journeyData['isFullyComplete'];
                final nextLevel = journeyData['nextLevel'];
                
                // 2. If finished, launch exam. Else, launch the next level!
                if (isFullyComplete) {
                  context.push('/mock-exam');
                } else if (nextLevel != null) {
                  context.push('/level/${nextLevel['id']}');
                }
              }
            },
            child: Container(
              height: 56, width: 56,
              decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppTheme.primary, blurRadius: 15, spreadRadius: -5)]),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
            ),
          ),
          
          _buildNavItem(Icons.bar_chart, 'Rank', 2),
          _buildNavItem(Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.white : AppTheme.textGrey, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textGrey, fontSize: 10)),
        ],
      ),
    );
  }
}