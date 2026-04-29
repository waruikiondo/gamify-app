import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // NEW IMPORT
import '../core/theme.dart';
import '../providers/global_providers.dart';
import '../providers/access_gate_provider.dart';
import 'faqs_bottom_sheet.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _tapCount = 0;
  DateTime? _lastTap;
  bool _isUploadingImage = false; // Tracks image upload state

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
        ),
      );

      final isAdmin = await ref.read(supabaseServiceProvider).isUserAdmin();

      if (isAdmin && mounted) {
        context.push('/admin');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access Denied: Nice try, Agent.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // Helper to format XP (e.g., 12400 -> 12.4k)
  String _formatXP(double xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}k';
    }
    return xp.toInt().toString();
  }

  // --- NEW: IMAGE UPLOAD LOGIC ---
  Future<void> _uploadProfilePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      // Pick an image from the gallery
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512, // Compress size
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return; // User canceled

      setState(() => _isUploadingImage = true);

      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final fileExt = image.name.split('.').last;
      final fileName =
          '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // We read as bytes to ensure it works flawlessly on Flutter Web and Mobile
      final bytes = await image.readAsBytes();

      // Upload to Supabase Storage 'avatars' bucket
      await supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: image.mimeType),
          );

      // Get the public URL of the uploaded image
      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      // Update the user's profile with the new image URL
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl})
          .eq('id', userId);

      // Refresh Riverpod state to instantly show the new image!
      ref.invalidate(userProfileProvider);
      ref.invalidate(leaderboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser = Supabase.instance.client.auth.currentUser;
    final fallbackName =
        authUser?.userMetadata?['full_name'] as String? ?? 'Agent';

    final profileAsync = ref.watch(userProfileProvider);
    final skillsAsync = ref.watch(skillMasteryProvider);
    final hasPassedExamAsync = ref.watch(finalExamStatusProvider);

    final bool hasPassedFinal = hasPassedExamAsync.value ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: GestureDetector(
          onTap: _handleSecretTap,
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white70),
              onPressed: () => _showSettingsPanel(context, fallbackName),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error loading profile: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (profile) {
          final String fullName = profile['full_name'] ?? fallbackName;
          final String title = profile['primary_goal'] ?? 'ACADEMY AGENT';
          final double totalScore =
              double.tryParse(profile['total_score']?.toString() ?? '0') ?? 0.0;
          final int streak = profile['streak'] ?? 0;
          final int levelsCompleted = profile['levels_completed'] ?? 0;

          // GRAB THE AVATAR URL FROM DB
          final String? avatarUrl = profile['avatar_url'];

          final double nextLevelThreshold = ((totalScore ~/ 1000) + 1) * 1000.0;
          final double progressPercent = (totalScore % 1000) / 1000.0;
          final double xpNeeded = nextLevelThreshold - totalScore;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProfileProvider);
              ref.invalidate(skillMasteryProvider);
            },
            color: Colors.purpleAccent,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  // --- 1. AVATAR & LEVEL BADGE ---
                  GestureDetector(
                    onTap: _isUploadingImage ? null : _uploadProfilePicture,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.purpleAccent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purpleAccent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: const Color(0xFF1E1A3A),
                            // DYNAMIC IMAGE LOADING
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: _isUploadingImage
                                ? const CircularProgressIndicator(
                                    color: Colors.purpleAccent,
                                  )
                                : (avatarUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 45,
                                          color: Colors.white,
                                        )
                                      : null),
                          ),
                        ),

                        // Edit Icon Badge (Bottom Right)
                        Positioned(
                          right: 0,
                          bottom: 20,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF0A0A1A),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),

                        // Level Badge (Bottom Center)
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 80),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF0A0A1A),
                                width: 2,
                              ),
                            ),
                            child: Text(
                              'LVL $levelsCompleted',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 2. NAME & TITLE ---
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- 3. XP PROGRESS BAR ---
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${totalScore.toInt()} XP',
                            style: const TextStyle(
                              color: Colors.purpleAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${xpNeeded.toInt()} XP to Next Tier',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1A3A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progressPercent == 0 && totalScore > 0
                                ? 1.0
                                : progressPercent,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.purpleAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // --- 4. GAMIFIED STATS ROW ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildGamifiedStatCard(
                          'Total XP',
                          _formatXP(totalScore),
                          Icons.star,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGamifiedStatCard(
                          'Streak',
                          '$streak Days',
                          Icons.local_fire_department,
                          Colors.deepOrange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGamifiedStatCard(
                          'Certs',
                          hasPassedFinal ? '1' : '0',
                          Icons.workspace_premium,
                          Colors.greenAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- 5. SKILL BADGES GRID ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SKILL BADGES',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  skillsAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.purpleAccent,
                      ),
                    ),
                    error: (err, stack) => Text(
                      'Error: $err',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                    data: (skills) {
                      if (skills.isEmpty) {
                        return _buildEmptySkillsState();
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 2.5,
                            ),
                        itemCount: skills.length > 4 ? 4 : skills.length,
                        itemBuilder: (context, index) {
                          final skill = skills[index];
                          final String skillTitle =
                              skill['skill_title'] ?? skill['title'] ?? 'Skill';
                          final int mastery = skill['mastery_percentage'] ?? 0;

                          String status = 'Locked';
                          Color iconColor = Colors.grey;
                          if (mastery >= 100 || hasPassedFinal) {
                            status = 'Mastery';
                            iconColor = Colors.amber;
                          } else if (mastery > 50) {
                            status = 'Advanced';
                            iconColor = Colors.cyanAccent;
                          } else if (mastery > 0) {
                            status = 'Proficient';
                            iconColor = Colors.greenAccent;
                          }

                          return _buildSkillBadgeCard(
                            skillTitle,
                            status,
                            iconColor,
                            Icons.architecture,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- UI WIDGETS ---

  Widget _buildGamifiedStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillBadgeCard(
    String title,
    String status,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(status, style: TextStyle(color: color, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySkillsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, style: BorderStyle.solid),
      ),
      child: const Column(
        children: [
          Icon(Icons.lock_outline, color: Colors.white38, size: 32),
          SizedBox(height: 12),
          Text(
            'Complete assessments to unlock skill badges.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- SETTINGS BOTTOM SHEET ---

  void _showSettingsPanel(BuildContext context, String currentName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          final gateAsync = ref.watch(accessGateStatusProvider);

          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Settings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                _buildActionTile(Icons.person_outline, 'Edit Profile', () {
                  Navigator.pop(context);
                  _showEditProfile(context, currentName);
                }),
                const SizedBox(height: 8),
                _buildActionTile(
                  Icons.track_changes,
                  'Change Primary Goal',
                  () {
                    Navigator.pop(context);
                    context.push('/goal-selection');
                  },
                ),
                const SizedBox(height: 8),

                if (gateAsync.value?.isAdmin == true) ...[
                  _buildActionTile(
                    Icons.admin_panel_settings,
                    'Admin Dashboard',
                    () {
                      Navigator.pop(context);
                      context.push('/admin');
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                _buildActionTile(Icons.notifications_none, 'Notifications', () {
                  Navigator.pop(context);
                  _showNotifications(context);
                }),
                const SizedBox(height: 8),
                _buildActionTile(Icons.security, 'Privacy & Security', () {
                  Navigator.pop(context);
                  _showPrivacySecurity(context);
                }),
                const SizedBox(height: 8),
                _buildActionTile(Icons.help_outline, 'Help & Support', () {
                  Navigator.pop(context);
                  _showHelpSupport(context);
                }),

                const SizedBox(height: 40),

                ElevatedButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: const Color(0xFF161224),
      leading: Icon(icon, color: Colors.purpleAccent),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }

  // --- EXISTING BOTTOM SHEETS ---

  void _showEditProfile(BuildContext context, String currentName) {
    final TextEditingController nameController = TextEditingController(
      text: currentName,
    );
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purpleAccent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (nameController.text.trim().isEmpty) return;
                          setModalState(() => isSaving = true);

                          try {
                            await ref
                                .read(supabaseServiceProvider)
                                .updateUserName(nameController.text.trim());
                            ref.invalidate(userProfileProvider);

                            if (context.mounted) {
                              Navigator.pop(context);
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Profile updated successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setModalState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text(
                'Exam Reminders',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Get notified to complete your daily training.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: true,
              activeThumbColor: Colors.purpleAccent,
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text(
                'Leaderboard Updates',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Alerts when your global percentile changes.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              value: false,
              activeThumbColor: Colors.purpleAccent,
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
      backgroundColor: const Color(0xFF1E1A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy & Security',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Colors.white54),
              title: const Text(
                'Change Password',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/update-password');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_forever,
                color: Colors.redAccent,
              ),
              title: const Text(
                'Delete Account Data',
                style: TextStyle(color: Colors.redAccent),
              ),
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
      backgroundColor: const Color(0xFF1E1A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Help & Support',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Need assistance with your certification prep?',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.purpleAccent),
              title: const Text(
                'Contact Support',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'support@2flydrone-learning.com',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.purpleAccent),
              title: const Text(
                'Read FAQs',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Pop the current bottom sheet first, but open the new one using
                // the root navigator context to avoid deactivated-context errors.
                final navContext = Navigator.of(context, rootNavigator: true).context;
                Navigator.pop(context);
                _showFaqsPanel(navContext);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showFaqsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scrollController) => FaqsBottomSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }
}
