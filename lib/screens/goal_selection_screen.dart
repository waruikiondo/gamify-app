import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  int? _selectedIndex;
  bool _isLoading = false; // Added loading state

  // Added 'id' to map to the database
  final List<Map<String, dynamic>> _goals = [
    {
      'id': 'certified',
      'icon': Icons.verified_outlined,
      'title': 'Get Certified',
      'subtitle': 'Earn recognized credentials to boost your resume.',
      'iconColor': Colors.purpleAccent,
      'bgColor': const Color(0xFF2E1A47),
    },
    {
      'id': 'skills',
      'icon': Icons.psychology_outlined,
      'title': 'Master New Skills',
      'subtitle': 'Deepen your technical knowledge in specific areas.',
      'iconColor': Colors.tealAccent,
      'bgColor': const Color(0xFF1A3B3A),
    },
    {
      'id': 'pivot',
      'icon': Icons.rocket_launch_outlined,
      'title': 'Career Pivot',
      'subtitle': 'Transition to a new role or industry entirely.',
      'iconColor': Colors.orangeAccent,
      'bgColor': const Color(0xFF4A2B1A),
    },
    {
      'id': 'explore',
      'icon': Icons.explore_outlined,
      'title': 'Just Exploring',
      'subtitle': 'Browsing courses without a specific end goal.',
      'iconColor': Colors.pinkAccent,
      'bgColor': const Color(0xFF4A1A31),
    },
  ];

  // --- NEW: Backend Logic ---
  Future<void> _saveGoalAndContinue() async {
    if (_selectedIndex == null) return;
    
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final selectedGoalId = _goals[_selectedIndex!]['id'];
      
      // Update the profile in Supabase
      await Supabase.instance.client
          .from('profiles')
          .update({'primary_goal': selectedGoalId})
          .eq('id', userId);

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
                    // Replaced Navigator with GoRouter
                    onPressed: () => context.pop(), 
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  // Progress Indicator (Step 1 of 4)
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
                    // Replaced empty comment with route to dashboard
                    onPressed: () => context.go('/dashboard'),
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
                'What is your primary goal?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "We'll personalize your learning path based on your selection.",
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
                // Hooked up the new async function here
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

  // Helper widget for the custom progress bar at the top
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

  // Helper widget for the selectable cards
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
        color: const Color(0xFF181622), // Slightly lighter than background
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
          // Icon Container
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
          
          // Text Content
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

          // Custom Radio Button Indicator
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