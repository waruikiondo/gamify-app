import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart'; // <-- NEW: Share Plus Import

import '../core/theme.dart';
import '../providers/global_providers.dart'; 
import '../services/supabase_service.dart';
import 'explore_screen.dart'; 
import 'rank_screen.dart';     
import 'profile_screen.dart';  

// --- PDF IMPORTS ---
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/analytics_service.dart';

// NEW: Dynamic Streak Provider
final userStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  return await ref.read(supabaseServiceProvider).updateAndGetStreak();
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
    // Watch at the top level so the play button always has fresh data
    final journeyAsync = ref.watch(userJourneyProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            const ExploreScreen(),
            const RankScreen(),    
            const ProfileScreen(), 
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(journeyAsync),
    );
  }

  Widget _buildHomeTab() {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Agent';
    
    // Watching the global providers
    final journeyAsyncValue = ref.watch(userJourneyProvider);
    final skillsAsyncValue = ref.watch(skillMasteryProvider); 
    final hasPassedExamAsync = ref.watch(finalExamStatusProvider);
    final bool hasPassedFinal = hasPassedExamAsync.value ?? false;
    
    // Watching the newly created streak provider
    final streakAsyncValue = ref.watch(userStreakProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final String? avatarUrl = profileAsync.value?['avatar_url'];
    
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(userJourneyProvider);
        ref.invalidate(skillMasteryProvider);
        ref.invalidate(finalExamStatusProvider);
        ref.invalidate(userStreakProvider); // Invalidate streak too
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary,
                      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                      child: avatarUrl == null 
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
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
                  onPressed: () => setState(() => _currentIndex = 3), 
                ),
              ],
            ),
            const SizedBox(height: 32),

            // DYNAMIC STREAK BADGE (UPDATED WITH TAP TO SHARE)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  final currentStreak = streakAsyncValue.value ?? 0;
                  if (currentStreak > 0) {
                    _showStreakShareDialog(context, currentStreak);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete a session today to start your streak!'),
                        backgroundColor: Colors.orangeAccent,
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withValues(alpha: 0.2), 
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)), // Added slight border to make it look clickable
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 4),
                      streakAsyncValue.when(
                        loading: () => const SizedBox(
                          height: 12, width: 12, 
                          child: CircularProgressIndicator(color: Colors.orangeAccent, strokeWidth: 2)
                        ),
                        error: (err, stack) => const Text('0 Days', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        data: (streak) => Text('$streak Days', style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // --- OVERALL PROGRESS ---
            journeyAsyncValue.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0), 
                child: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0), 
                child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
              ),
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
                              value: overallProgress, 
                              strokeWidth: 12, 
                              backgroundColor: AppTheme.border,
                              color: isFullyComplete ? Colors.greenAccent : AppTheme.primary, 
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(isFullyComplete ? Icons.workspace_premium : Icons.military_tech, 
                                color: isFullyComplete ? Colors.greenAccent : AppTheme.primary, size: 32),
                              const SizedBox(height: 8),
                              Text('Lvl ${currentLevel['level_order']}', 
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(isFullyComplete ? 'MAX RANK' : 'CURRENT PHASE', 
                                style: TextStyle(color: isFullyComplete ? Colors.greenAccent : AppTheme.primary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
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
                      _buildCertificateCard(context, fullName) 
                    else
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A3A), 
                          borderRadius: BorderRadius.circular(24), 
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(isFullyComplete ? 'JOURNEY COMPLETE' : 'UP NEXT', 
                                  style: const TextStyle(color: AppTheme.primary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                                Icon(isFullyComplete ? Icons.done_all : Icons.lock_outline, 
                                  color: AppTheme.textGrey.withValues(alpha: 0.5), size: 20),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Chapter ${currentLevel['level_order']}:\n${currentLevel['title']}', 
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.info_outline, color: AppTheme.textGrey, size: 14),
                                const SizedBox(width: 4),
                                Expanded(child: Text(currentLevel['description'] ?? '', 
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12))),
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
                    
                    final String title = skill['skill_title']?.toString() ?? skill['title']?.toString() ?? 'Skill Area';
                    
                    double mastery = 0.0;
                    if (hasPassedFinal) {
                      mastery = 1.0; 
                    } else {
                      final masteryNum = skill['mastery_percentage'] ?? 0;
                      double rawMastery = masteryNum is int ? masteryNum.toDouble() : (masteryNum as double);
                      mastery = rawMastery > 1.0 ? rawMastery / 100.0 : rawMastery; 
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

  // --- NEW: SHARE STREAK DIALOG ---
  void _showStreakShareDialog(BuildContext context, int streak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        contentPadding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), 
          side: const BorderSide(color: Colors.orangeAccent, width: 2)
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_fire_department, size: 80, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            const Text('STREAK KEEPER', textAlign: TextAlign.center, style: TextStyle(color: Colors.orangeAccent, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('$streak Days', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('You are on fire! Keep learning every day to maintain your streak and master your certification.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Close', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog first
              Share.share('🔥 I am on a $streak-day learning streak! Getting ready for my certification. Can you beat my record?');
            },
            icon: const Icon(Icons.ios_share, color: Colors.black, size: 18),
            label: const Text('Share Achievement', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              minimumSize: const Size(0, 48), 
            ),
          )
        ],
      )
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
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2), 
                              borderRadius: BorderRadius.circular(12),
                            ),
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

  Widget _buildCertificateCard(BuildContext context, String fullName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withValues(alpha: 0.2), AppTheme.primary.withValues(alpha: 0.1)],
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
            onPressed: () => _showCertificateDialog(context, fullName), 
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

  void _showCertificateDialog(BuildContext context, String fullName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        contentPadding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
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
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text('Close', style: TextStyle(color: AppTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              _downloadCertificate(fullName); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(0, 48), 
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, color: Colors.black, size: 18),
                SizedBox(width: 8),
                Text('Download PDF', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      )
    );
  }

  Future<void> _downloadCertificate(String userName) async {
    ref.read(analyticsServiceProvider).trackCertificateDownloaded(userName);
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.amber, width: 8),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('CERTIFICATE OF COMPLETION', style: pw.TextStyle(fontSize: 36, fontWeight: pw.FontWeight.bold, color: PdfColors.amber)),
                  pw.SizedBox(height: 24),
                  pw.Text('This is proudly presented to', style: const pw.TextStyle(fontSize: 20)),
                  pw.SizedBox(height: 24),
                  pw.Text(userName.toUpperCase(), style: pw.TextStyle(fontSize: 48, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                  pw.SizedBox(height: 24),
                  pw.Text('For successfully passing the Final Challenge and demonstrating mastery as an', style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 12),
                  pw.Text('Official Cloud Architect', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 60),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Date: ${DateTime.now().toString().split(' ')[0]}', style: const pw.TextStyle(fontSize: 16)),
                      pw.Text('Signature: ___________________', style: const pw.TextStyle(fontSize: 16)),
                    ]
                  )
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Cloud_Architect_Certificate_$userName.pdf',
    );
  }

  Widget _buildSkillCard(String title, double progress, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.border.withValues(alpha: 0.3),
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

  Widget _buildBottomNav(AsyncValue<Map<String, dynamic>> journeyAsync) {
    final isLoading = journeyAsync is AsyncLoading;

    void onPlayTap() {
      if (isLoading) return; // Button shows spinner — ignore taps while loading

      journeyAsync.whenData((journeyData) {
        final isFullyComplete = journeyData['isFullyComplete'] as bool? ?? false;
        final nextLevel = journeyData['nextLevel'] as Map<String, dynamic>?;
        final levels = List<Map<String, dynamic>>.from(
          (journeyData['levels'] as List? ?? []).map((e) => e as Map<String, dynamic>)
        );

        if (isFullyComplete) {
          context.push('/mock-exam');
          return;
        }

        // Mirror exactly what the "Start Session" button does:
        // Use nextLevel, or fall back to the first level in the list
        final target = nextLevel ?? (levels.isNotEmpty ? levels.first : null);

        if (target != null && target['id'] != null) {
          context.push('/level/${target['id']}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No levels available yet. Check back soon!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.primary,
            ),
          );
        }
      });
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: BoxDecoration(
        color: AppTheme.background, 
        border: Border(top: BorderSide(color: AppTheme.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_filled, 'Home', 0),
          _buildNavItem(Icons.explore_outlined, 'Explore', 1),
          
          GestureDetector(
            onTap: onPlayTap,
            child: Container(
              height: 56, width: 56,
              decoration: const BoxDecoration(
                color: AppTheme.primary, 
                shape: BoxShape.circle, 
                boxShadow: [BoxShadow(color: AppTheme.primary, blurRadius: 15, spreadRadius: -5)],
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow, color: Colors.white, size: 32),
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