import '../providers/global_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../services/supabase_service.dart';

// Providers to fetch dropdown data for the Questions Manager
final adminLevelsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getLevels();
});

final adminSkillsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return await ref.read(supabaseServiceProvider).getAllSkillAreas();
});

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isCheckingAccess = true; // Security Flag
  static const Color adminCyan = Colors.cyanAccent;

  @override
  void initState() {
    super.initState();
    _verifyAdminAccess();
  }

  // --- ROUTE GUARD SECURITY CHECK ---
  Future<void> _verifyAdminAccess() async {
    final isAdmin = await ref.read(supabaseServiceProvider).isUserAdmin();
    if (mounted) {
      if (!isAdmin) {
        // Hacker/User typed the URL manually: Kick them back to the dashboard immediately
        context.go('/dashboard');
      } else {
        // Verified Admin: Reveal the UI
        setState(() {
          _isCheckingAccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a secure loading screen while verifying the database role
    if (_isCheckingAccess) {
      return const Scaffold(
        backgroundColor: Color(0xFF0A0F14),
        body: Center(child: CircularProgressIndicator(color: adminCyan)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F14), // Deep Admin Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: adminCyan),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings, color: adminCyan, size: 20),
            SizedBox(width: 8),
            Text('OVERRIDE MODE', style: TextStyle(color: adminCyan, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildLevelsManager(),
          _buildQuestionsManager(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0A0F14),
        selectedItemColor: adminCyan,
        unselectedItemColor: AppTheme.textGrey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Manage Levels'),
          BottomNavigationBarItem(icon: Icon(Icons.question_answer), label: 'Manage Questions'),
        ],
      ),
    );
  }

  // ==========================================
  // 1. LEVELS MANAGER
  // ==========================================
  Widget _buildLevelsManager() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final orderCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '80'); // Default Passing Threshold

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Create New Level', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Define the chapters and passing thresholds.', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(height: 32),
          
          _buildAdminTextField(titleCtrl, 'Level Title', Icons.title),
          const SizedBox(height: 16),
          _buildAdminTextField(descCtrl, 'Description', Icons.description, maxLines: 3),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildAdminTextField(orderCtrl, 'Level Order (e.g. 1)', Icons.format_list_numbered, isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildAdminTextField(passCtrl, 'Pass Threshold %', Icons.percent, isNumber: true)),
            ],
          ),
          
          const SizedBox(height: 40),
          
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty || orderCtrl.text.isEmpty) return;
              try {
                await ref.read(supabaseServiceProvider).addLevel(
                  title: titleCtrl.text,
                  description: descCtrl.text,
                  levelOrder: int.parse(orderCtrl.text),
                  passingPercentage: int.parse(passCtrl.text),
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Level created successfully!'), backgroundColor: adminCyan, behavior: SnackBarBehavior.floating));
                  titleCtrl.clear(); descCtrl.clear(); orderCtrl.clear();
                  
                  // Instantly refresh the admin dropdowns and user dashboard
                  ref.invalidate(adminLevelsProvider); 
                  ref.invalidate(userJourneyProvider); 
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
                }
              }
            },
            style: _adminButtonStyle(),
            child: const Text('DEPLOY LEVEL', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 2. QUESTIONS MANAGER (MAPPED TO SKILLS)
  // ==========================================
  
  // State variables for Questions Form
  String? _selectedLevelId;
  String? _selectedSkillId;
  final _questionCtrl = TextEditingController();
  final _opt1Ctrl = TextEditingController();
  final _opt2Ctrl = TextEditingController();
  final _opt3Ctrl = TextEditingController();
  final _opt4Ctrl = TextEditingController();
  String? _correctOptionValue; // Will hold the exact text of the correct option

  Widget _buildQuestionsManager() {
    final levelsAsync = ref.watch(adminLevelsProvider);
    final skillsAsync = ref.watch(adminSkillsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Content & Skill Mapping', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Add questions and map them to the Skill Tree.', style: TextStyle(color: AppTheme.textGrey, fontSize: 14)),
          const SizedBox(height: 32),

          // --- DROPDOWNS ---
          Row(
            children: [
              Expanded(
                child: levelsAsync.when(
                  loading: () => const CircularProgressIndicator(color: adminCyan),
                  error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                  data: (levels) => _buildDropdown(
                    hint: 'Select Level',
                    value: _selectedLevelId,
                    items: levels.map((l) => DropdownMenuItem(value: l['id'].toString(), child: Text('Lvl ${l['level_order']}: ${l['title']}'))).toList(),
                    onChanged: (val) => setState(() => _selectedLevelId = val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: skillsAsync.when(
                  loading: () => const CircularProgressIndicator(color: adminCyan),
                  error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                  data: (skills) => _buildDropdown(
                    hint: 'Map to Skill Area',
                    value: _selectedSkillId,
                    items: skills.map((s) => DropdownMenuItem(value: s['id'].toString(), child: Text(s['title'].toString()))).toList(),
                    onChanged: (val) => setState(() => _selectedSkillId = val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // --- QUESTION TEXT ---
          _buildAdminTextField(_questionCtrl, 'Question Text', Icons.help_outline, maxLines: 3),
          const SizedBox(height: 24),
          const Text('Answer Options (Select the correct one)', style: TextStyle(color: adminCyan, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // --- OPTIONS ---
          RadioGroup<String>(
            groupValue: _correctOptionValue,
            onChanged: (val) => setState(() => _correctOptionValue = val),
            child: Column(
              children: [
                _buildOptionRow(_opt1Ctrl, 'Option A'),
                const SizedBox(height: 12),
                _buildOptionRow(_opt2Ctrl, 'Option B'),
                const SizedBox(height: 12),
                _buildOptionRow(_opt3Ctrl, 'Option C'),
                const SizedBox(height: 12),
                _buildOptionRow(_opt4Ctrl, 'Option D'),
              ],
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: _submitQuestion,
            style: _adminButtonStyle(),
            child: const Text('DEPLOY QUESTION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          )
        ],
      ),
    );
  }

  Widget _buildOptionRow(TextEditingController controller, String hint) {
    return Row(
      children: [
        Radio<String>(
          value: controller.text,
          activeColor: adminCyan,
          fillColor: WidgetStateProperty.resolveWith((states) => adminCyan),
        ),
        Expanded(
          child: _buildAdminTextField(controller, hint, Icons.short_text, onChanged: (val) {
            // Update radio value if this was the selected correct answer
            if (_correctOptionValue == controller.text) {
              setState(() => _correctOptionValue = val);
            }
          }),
        ),
      ],
    );
  }

  Future<void> _submitQuestion() async {
    if (_selectedLevelId == null || _selectedSkillId == null || _questionCtrl.text.isEmpty || _correctOptionValue == null || _correctOptionValue!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select a correct answer.'), backgroundColor: Colors.redAccent));
      return;
    }

    // Compile options, ignoring empty ones
    final options = [_opt1Ctrl.text, _opt2Ctrl.text, _opt3Ctrl.text, _opt4Ctrl.text].where((o) => o.isNotEmpty).toList();

    try {
      await ref.read(supabaseServiceProvider).addQuestion(
        levelId: _selectedLevelId!,
        skillAreaId: _selectedSkillId!,
        questionText: _questionCtrl.text,
        answerOptions: options,
        correctAnswer: _correctOptionValue!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question successfully mapped and deployed!'), backgroundColor: adminCyan, behavior: SnackBarBehavior.floating));
        _questionCtrl.clear(); _opt1Ctrl.clear(); _opt2Ctrl.clear(); _opt3Ctrl.clear(); _opt4Ctrl.clear();
        setState(() => _correctOptionValue = null);

        // Instantly refresh the user dashboard
        ref.invalidate(userJourneyProvider); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildAdminTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1, bool isNumber = false, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textGrey),
        prefixIcon: Icon(icon, color: adminCyan.withValues(alpha:0.5)),
        filled: true,
        fillColor: const Color(0xFF131B24),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border.withValues(alpha:0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: adminCyan, width: 2)),
      ),
    );
  }

  Widget _buildDropdown({required String hint, required String? value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF131B24),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border.withValues(alpha:0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppTheme.textGrey)),
          dropdownColor: const Color(0xFF131B24),
          icon: const Icon(Icons.arrow_drop_down, color: adminCyan),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  ButtonStyle _adminButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: adminCyan.withValues(alpha:0.1),
      foregroundColor: adminCyan,
      side: const BorderSide(color: adminCyan, width: 2),
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}