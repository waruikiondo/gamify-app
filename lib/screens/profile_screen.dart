import '../providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart'; 

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
    if (_lastTap != null && now.difference(_lastTap!).inSeconds > 1) {
      _tapCount = 0; 
    }
    
    _lastTap = now;
    _tapCount++;

    if (_tapCount == 5) {
      _tapCount = 0; 
      
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
    // Watch Auth state to keep the name updated instantly
    final user = Supabase.instance.client.auth.currentUser;
    final fullName = user?.userMetadata?['full_name'] as String? ?? 'Agent';
    final email = user?.email ?? 'Unknown Email';
    
    final hasPassedExamAsync = ref.watch(finalExamStatusProvider);
    final bool hasPassedFinal = hasPassedExamAsync.value ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _handleSecretTap, 
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
            
            // --- USER INFO ---
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
            _buildActionTile(Icons.person_outline, 'Edit Profile', () => _showEditProfile(context, fullName)),
            const SizedBox(height: 8),
            _buildActionTile(Icons.track_changes, 'Change Primary Goal', () => context.push('/goal-selection')),
            const SizedBox(height: 8),
            _buildActionTile(Icons.notifications_none, 'Notifications', () => _showNotifications(context)),
            const SizedBox(height: 8),
            _buildActionTile(Icons.security, 'Privacy & Security', () => _showPrivacySecurity(context)),
            const SizedBox(height: 8),
            _buildActionTile(Icons.help_outline, 'Help & Support', () => _showHelpSupport(context)),
            
            const SizedBox(height: 40),
            
            // --- SIGN OUT BUTTON ---
            ElevatedButton.icon(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              label: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent, 
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.redAccent, width: 1.5), 
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

  void _showEditProfile(BuildContext context, String currentName) {
    final TextEditingController nameController = TextEditingController(text: currentName);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24, right: 24, top: 24
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: AppTheme.textGrey),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primary), borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSaving ? null : () async {
                    if (nameController.text.trim().isEmpty) return;
                    setModalState(() => isSaving = true);
                    
                    try {
                      await ref.read(supabaseServiceProvider).updateUserName(nameController.text.trim());
                      ref.invalidate(userProfileProvider); 
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        setState(() {}); 
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      setModalState(() => isSaving = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, minimumSize: const Size(double.infinity, 50)),
                  child: isSaving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

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
              activeThumbColor: AppTheme.primary, // FIX APPLIED HERE
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text('Leaderboard Updates', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Alerts when your global percentile changes.', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
              value: false,
              activeThumbColor: AppTheme.primary, // FIX APPLIED HERE
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