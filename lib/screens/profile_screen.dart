import '../providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart'; // Added to check admin status
import 'dashboard_screen.dart'; // To access the cert provider

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleSecretTap() async {
    final now = DateTime.now();
    // Reset if they tap too slowly (more than 1 second between taps)
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 1) {
      _tapCount = 0; 
    }
    
    _lastTap = now;
    _tapCount++;

    if (_tapCount == 5) {
      _tapCount = 0; // Reset after triggering
      
      // Show loading while verifying admin status
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verifying clearance...'), 
          backgroundColor: AppTheme.border,
          duration: Duration(seconds: 1),
        )
      );
      
      final isAdmin = await ref.read(supabaseServiceProvider).isUserAdmin();
      
      if (isAdmin && mounted) {
        context.push('/admin');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Nice try, Agent.'), 
            backgroundColor: Colors.redAccent
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Agent';
    final email = user?.email ?? 'Unknown Email';
    
    // Check if they have the cert
    final hasPassedExamAsync = ref.watch(finalExamStatusProvider);
    final bool hasPassedFinal = hasPassedExamAsync.value ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _handleSecretTap, // <-- THE SECRET ENTRANCE
          child: const Text(
            'PROFILE', 
            style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 1.5, fontWeight: FontWeight.bold)
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            
            // --- USER INFO (NO PICTURE) ---
            Text(fullName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(email, style: const TextStyle(color: AppTheme.textGrey, fontSize: 16)),
            
            const SizedBox(height: 40),
            
            // --- STATS GRID ---
            Row(
              children: [
                Expanded(child: _buildStatCard('Rank', hasPassedFinal ? 'Gold' : 'Silver', Icons.military_tech, Colors.amber)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Certificates', hasPassedFinal ? '1' : '0', Icons.workspace_premium, Colors.greenAccent)),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // --- SETTINGS / ACTIONS ---
            _buildActionTile(Icons.notifications_none, 'Notifications', () => _showNotifications(context)),
            const SizedBox(height: 8),
            _buildActionTile(Icons.security, 'Privacy & Security', () => _showPrivacySecurity(context)),
            const SizedBox(height: 8),
            _buildActionTile(Icons.help_outline, 'Help & Support', () => _showHelpSupport(context)),
            
            const SizedBox(height: 40),
            
            // --- EXACT MATCH SIGN OUT BUTTON ---
            ElevatedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, // Dark background
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5), // Red Outline
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppTheme.textGrey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppTheme.surface,
      leading: Icon(icon, color: AppTheme.primary),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textGrey),
      onTap: onTap,
    );
  }

  // --- INTERACTIVE BOTTOM SHEETS ---

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Exam Reminders', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Get notified to complete your daily training.', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              value: true,
              activeColor: AppTheme.primary,
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text('Leaderboard Updates', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Alerts when your global percentile changes.', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              value: false,
              activeColor: AppTheme.primary,
              onChanged: (val) {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showPrivacySecurity(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Privacy & Security', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: AppTheme.textGrey),
              title: const Text('Change Password', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.push('/update-password');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text('Delete Account Data', style: TextStyle(color: Colors.redAccent)),
              onTap: () => Navigator.pop(context), 
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showHelpSupport(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Help & Support', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Text('Need assistance with your certification prep?', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primary),
              title: const Text('Contact Support', style: TextStyle(color: Colors.white)),
              subtitle: const Text('support@gamify-learning.com', style: TextStyle(color: AppTheme.textGrey)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: AppTheme.primary),
              title: const Text('Read FAQs', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}