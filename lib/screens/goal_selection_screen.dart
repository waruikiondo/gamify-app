import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod
import '../core/theme.dart';
import '../providers/global_providers.dart'; // Added to refresh the leaderboard

// Changed to ConsumerStatefulWidget to access Riverpod
class GoalSelectionScreen extends ConsumerStatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  ConsumerState<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends ConsumerState<GoalSelectionScreen> {
  int? _selectedIndex;
  bool _isLoading = false; 

  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'certified',
      'icon': Icons.flight_takeoff_outlined,
      'title': 'CERTIFIED PILOT',
      'subtitle': 'Pass the FAA Part 107 exam and unlock commercial drone operations.',
      'iconColor': Colors.purpleAccent,
      'bgColor': const Color(0xFF2E1A47),
    },
    {
      'id': 'aerial',
      'icon': Icons.camera_outdoor_outlined,
      'title': 'AERIAL ARTIST',
      'subtitle': 'Master drone photography and cinematography for creative work.',
      'iconColor': Colors.tealAccent,
      'bgColor': const Color(0xFF1A3B3A),
    },
    {
      'id': 'commercial',
      'icon': Icons.business_center_outlined,
      'title': 'COMMERCIAL FLYER',
      'subtitle': 'Build a drone services business — inspections, mapping, delivery.',
      'iconColor': Colors.orangeAccent,
      'bgColor': const Color(0xFF4A2B1A),
    },
    {
      'id': 'explore',
      'icon': Icons.explore_outlined,
      'title': 'FREE EXPLORER',
      'subtitle': 'Learn drone fundamentals and airspace rules at your own pace.',
      'iconColor': Colors.pinkAccent,
      'bgColor': const Color(0xFF4A1A31),
    },
  ];

  // --- UPDATED: Backend Logic ---
  Future<void> _saveGoalAndContinue([String defaultGoalTitle = 'ACADEMY AGENT']) async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      
      // We now save the actual TITLE so it looks good on the Leaderboard
      final selectedTitle = _selectedIndex != null ? _goals[_selectedIndex!]['title'] : defaultGoalTitle;
      
      // FIX: Changed 'users' to 'profiles' so it syncs with the rest of the app
      await Supabase.instance.client
          .from('profiles')
          .update({'primary_goal': selectedTitle})
          .eq('id', userId);

      // Tell the app to refresh the user's profile and the leaderboard
      ref.invalidate(userProfileProvider);
      ref.invalidate(leaderboardProvider);

      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving goal: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom Top Navigation Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.center,
                  ),
                  Row(
                    children: [
                      _buildProgressSegment(isActive: true),
                      const SizedBox(width: 4),
                      _buildProgressSegment(isActive: false),
                      const SizedBox(width: 4),
                      _buildProgressSegment(isActive: false),
                      const SizedBox(width: 4),
                      _buildProgressSegment(isActive: false),
                    ],
                  ),
                  TextButton(
                    onPressed: () => _saveGoalAndContinue('FREE EXPLORER'),
                    child: const Text(
                      'Skip',
                      style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Header Text
              const Text(
                'Why are you here to fly?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We'll tailor your training path to match your drone ambitions.",
                style: TextStyle(color: AppTheme.textGrey, fontSize: 16),
              ),
              const SizedBox(height: 32),

              // Goal Selection Cards
              Expanded(
                child: ListView.builder(
                  itemCount: _goals.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedIndex == index;
                    final goal = _goals[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: _buildGoalCard(
                        title: goal['title'],
                        subtitle: goal['subtitle'],
                        icon: goal['icon'],
                        iconColor: goal['iconColor'],
                        iconBgColor: goal['bgColor'],
                        isSelected: isSelected,
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              ElevatedButton(
                onPressed: _selectedIndex != null && !_isLoading ? _saveGoalAndContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedIndex != null ? AppTheme.primary : AppTheme.border,
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Continue'),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSegment({required bool isActive}) {
    return Container(
      width: 24,
      height: 4,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : AppTheme.border,
        borderRadius: BorderRadius.circular(2),
        boxShadow: isActive
            ? [BoxShadow(color: AppTheme.primary.withOpacity(0.5), blurRadius: 4)]
            : [],
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181622), 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.lightBlueAccent : AppTheme.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.lightBlueAccent.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.lightBlueAccent : AppTheme.border,
                width: 2,
              ),
              color: isSelected ? Colors.lightBlueAccent.withOpacity(0.2) : Colors.transparent,
            ),
            child: isSelected
                ? const Icon(Icons.circle, color: Colors.lightBlueAccent, size: 12)
                : null,
          ),
        ],
      ),
    );
  }
}