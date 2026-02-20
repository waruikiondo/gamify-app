import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import 'explore_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

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
            const Center(child: Text('Leaderboard Coming Soon', style: TextStyle(color: Colors.white))),
            const Center(child: Text('Profile Coming Soon', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- MAIN DASHBOARD CONTENT (HOME TAB) ---
  Widget _buildHomeTab() {
    // 1. Get the current user from Supabase
    final user = Supabase.instance.client.auth.currentUser;
    // 2. Safely extract the full_name from the metadata, or provide a fallback
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Academy Member';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Settings / Sign Out logic
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    // You can later make this dynamic too if you add profile pictures!
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'), 
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Welcome back,', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                      // 3. Inject the dynamic name here
                      Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {},
                  ),
                  // --- SETTINGS COG ---
                  IconButton(
                    icon: const Icon(Icons.settings, color: AppTheme.textGrey),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: AppTheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("Settings", 
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              const Divider(color: AppTheme.border, height: 32),
                              ListTile(
                                leading: const Icon(Icons.logout, color: Colors.redAccent),
                                title: const Text("Sign Out", style: TextStyle(color: Colors.white)),
                                onTap: () async {
                                  await Supabase.instance.client.auth.signOut();
                                  if (mounted) context.go('/login'); // Updated to /login to match our new router
                                },
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 32),

          // Streak Badge
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 16),
                  SizedBox(width: 4),
                  Text('12 Days', style: TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          
          // Hero Circular Progress
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                const SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: 0.65,
                    strokeWidth: 12,
                    backgroundColor: AppTheme.border,
                    color: AppTheme.primary,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.military_tech, color: AppTheme.primary, size: 32),
                    SizedBox(height: 8),
                    Text('Lvl 4', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('ADVANCED ARCH.', style: TextStyle(color: AppTheme.primary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('1,240 / 2,000 XP', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Up Next Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A3A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('UP NEXT', style: TextStyle(color: AppTheme.primary, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                    Icon(Icons.lock_outline, color: AppTheme.textGrey.withOpacity(0.5), size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Chapter 5:\nSecurity Gates', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, height: 1.2)),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Icon(Icons.schedule, color: AppTheme.textGrey, size: 14),
                    SizedBox(width: 4),
                    Text('15m remaining', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                    SizedBox(width: 16),
                    Icon(Icons.category, color: AppTheme.textGrey, size: 14),
                    SizedBox(width: 4),
                    Text('Network Sec', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => setState(() => _currentIndex = 1), // Takes them to Explore map
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Start Session'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Skill Mastery
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Skill Mastery', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: AppTheme.primary, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildSkillCard('System\nDesign', 0.80, Colors.blueAccent)),
              const SizedBox(width: 12),
              Expanded(child: _buildSkillCard('Cloud\nOps', 0.65, Colors.purpleAccent)),
              const SizedBox(width: 12),
              Expanded(child: _buildSkillCard('NetSec\nBasics', 0.25, Colors.pinkAccent)),
            ],
          ),
          const SizedBox(height: 100), // Padding for nav bar
        ],
      ),
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
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.border.withOpacity(0.5))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home_filled, 'Home', 0),
          _buildNavItem(Icons.explore_outlined, 'Explore', 1),
          GestureDetector(
            onTap: () => setState(() => _currentIndex = 1),
            child: Container(
              height: 56, width: 56,
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppTheme.primary, blurRadius: 15, spreadRadius: -5)],
              ),
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