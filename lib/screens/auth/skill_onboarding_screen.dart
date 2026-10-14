import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skill_chip.dart';
import '../main_navigation_screen.dart';

class SkillOnboardingScreen extends StatefulWidget {
  final bool isEditingProfile;
  final SkillChipType initialSection;

  const SkillOnboardingScreen({
    super.key,
    this.isEditingProfile = false,
    this.initialSection = SkillChipType.teach,
  });

  @override
  State<SkillOnboardingScreen> createState() => _SkillOnboardingScreenState();
}

class _SkillOnboardingScreenState extends State<SkillOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _teachSkills = [];
  final List<String> _learnSkills = [];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isSaving = false;

  final Map<String, List<String>> _categorizedSkills = {
    'Tech & Coding': [
      'Python',
      'Java',
      'C++',
      'Flutter',
      'React',
      'JavaScript',
      'Node.js',
      'SQL',
      'Data Structures',
      'Git/GitHub',
      'Linux',
      'Docker',
      'Cyber Security',
    ],
    'Design & Creative': [
      'Figma',
      'UI/UX Design',
      'Canva',
      'Video Editing',
      'Photoshop',
      '3D Modeling',
      'Blender',
    ],
    'Data & AI': [
      'Machine Learning',
      'Data Analytics',
      'Excel',
      'Tableau',
      'Power BI',
      'Deep Learning',
    ],
    'Core & Communication': [
      'Public Speaking',
      'Presentation Skills',
      'Content Writing',
      'AutoCAD',
      'SolidWorks',
      'English Debate',
      'Aptitude',
    ],
  };

  List<String> get _allCatalogSkills {
    final Set<String> all = {};
    for (final list in _categorizedSkills.values) {
      all.addAll(list);
    }
    all.addAll(MockData.popularSkills);
    return all.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialSection == SkillChipType.teach ? 0 : 1,
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      _teachSkills.addAll(user.teachSkills);
      _learnSkills.addAll(user.learnSkills);
    }

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
          _selectedCategory = 'All';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill, SkillChipType type) {
    final clean = skill.trim();
    if (clean.isEmpty) return;

    setState(() {
      final targetList = type == SkillChipType.teach ? _teachSkills : _learnSkills;
      final existingIndex = targetList.indexWhere(
        (s) => s.toLowerCase() == clean.toLowerCase(),
      );

      if (existingIndex != -1) {
        // Toggle OFF
        targetList.removeAt(existingIndex);
      } else {
        // Toggle ON
        targetList.add(clean);
      }
    });
  }

  void _addCustomSkill(SkillChipType type) {
    final clean = _searchController.text.trim();
    if (clean.isEmpty) return;

    _toggleSkill(clean, type);
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  Future<void> _handleSave() async {
    if (_teachSkills.isEmpty || _learnSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _teachSkills.isEmpty
                ? 'Please add at least 1 skill to Teach.'
                : 'Please add at least 1 skill you want to Learn.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updateSkills(
      teachSkills: _teachSkills,
      learnSkills: _learnSkills,
    );
    setState(() => _isSaving = false);

    if (!mounted) return;

    if (widget.isEditingProfile) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skills updated successfully!'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  List<String> _getFilteredSuggestions() {
    List<String> pool;
    if (_selectedCategory == 'All') {
      pool = _allCatalogSkills;
    } else {
      pool = _categorizedSkills[_selectedCategory] ?? [];
    }

    if (_searchQuery.isEmpty) {
      return pool;
    }

    return pool
        .where((s) => s.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _teachSkills.isNotEmpty && _learnSkills.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditingProfile ? 'Manage Skills' : 'Skill Setup'),
        automaticallyImplyLeading: widget.isEditingProfile,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: AppTextStyles.captionBold.copyWith(fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.teach,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('I Can Teach (${_teachSkills.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.learn,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('I Want to Learn (${_learnSkills.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Teach Tab
                  _buildSkillEditor(
                    type: SkillChipType.teach,
                    selectedSkills: _teachSkills,
                    themeColor: AppColors.teach,
                    hintText: 'Search or add skill you teach (e.g. Python, Figma)',
                    guideTitle: 'What knowledge can you share?',
                    guideSubtitle: 'Peers looking for these skills will be matched with you.',
                  ),
                  // Learn Tab
                  _buildSkillEditor(
                    type: SkillChipType.learn,
                    selectedSkills: _learnSkills,
                    themeColor: AppColors.learn,
                    hintText: 'Search or add skill you want to learn (e.g. SQL, React)',
                    guideTitle: 'What do you want to master?',
                    guideSubtitle: 'We will match you with students who teach these topics.',
                  ),
                ],
              ),
            ),

            // Bottom Fixed Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Live status checklist
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildRequirementBadge(
                        label: 'Teach: ${_teachSkills.length}',
                        isSatisfied: _teachSkills.isNotEmpty,
                        color: AppColors.teach,
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      _buildRequirementBadge(
                        label: 'Learn: ${_learnSkills.length}',
                        isSatisfied: _learnSkills.isNotEmpty,
                        color: AppColors.learn,
                      ),
                      const Text('•', style: TextStyle(color: AppColors.textMuted)),
                      Text(
                        canSave ? 'Ready to Swap! ✓' : 'Add at least 1 in each',
                        style: AppTextStyles.captionBold.copyWith(
                          color: canSave ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: widget.isEditingProfile ? 'Save Changes' : 'Complete Setup & Find Matches',
                    icon: Icons.check_circle_outline,
                    onPressed: _handleSave,
                    isLoading: _isSaving,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillEditor({
    required SkillChipType type,
    required List<String> selectedSkills,
    required Color themeColor,
    required String hintText,
    required String guideTitle,
    required String guideSubtitle,
  }) {
    final filteredSuggestions = _getFilteredSuggestions();
    final isCustomTextNew = _searchQuery.isNotEmpty &&
        !filteredSuggestions.any((s) => s.toLowerCase() == _searchQuery);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      children: [
        // Helper Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: themeColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: themeColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(
                type == SkillChipType.teach ? Icons.school_outlined : Icons.lightbulb_outline,
                color: themeColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guideTitle, style: AppTextStyles.subheading.copyWith(fontSize: 14)),
                    Text(guideSubtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Search / Input Box
        TextField(
          controller: _searchController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
          onSubmitted: (_) => _addCustomSkill(type),
        ),
        const SizedBox(height: 12),

        // Add Custom Skill banner if typing something unique
        if (isCustomTextNew) ...[
          InkWell(
            onTap: () => _addCustomSkill(type),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: themeColor, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_circle, color: themeColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add "${_searchController.text.trim()}" as a custom skill',
                      style: AppTextStyles.captionBold.copyWith(color: themeColor),
                    ),
                  ),
                  Text('Tap to add', style: AppTextStyles.caption.copyWith(color: themeColor)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Selected Skills Tray
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected (${selectedSkills.length})',
              style: AppTextStyles.subheading,
            ),
            if (selectedSkills.isNotEmpty)
              Text(
                'Tap × to remove',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selectedSkills.isEmpty ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border,
              width: 1.2,
            ),
          ),
          child: selectedSkills.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No skills added yet. Tap suggestions below or type above!',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedSkills.map((skill) {
                    return SkillChip(
                      label: skill,
                      type: type,
                      isRemovable: true,
                      onRemove: () => _toggleSkill(skill, type),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 20),

        // Category Filter Chips
        Text('Browse Categories', style: AppTextStyles.subheading),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildCategoryChip('All'),
              ..._categorizedSkills.keys.map((cat) => _buildCategoryChip(cat)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Suggestions Catalog
        Text(
          _searchQuery.isNotEmpty
              ? 'Search Results (${filteredSuggestions.length})'
              : 'Tap to Add or Remove:',
          style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),

        if (filteredSuggestions.isEmpty && !isCustomTextNew)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No matching skills found. Hit Enter to add as custom!',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredSuggestions.map((skill) {
              final isSelected = selectedSkills.any(
                (s) => s.toLowerCase() == skill.toLowerCase(),
              );

              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                avatar: Icon(
                  isSelected ? Icons.check_circle : Icons.add_circle_outline,
                  size: 16,
                  color: isSelected ? Colors.white : themeColor,
                ),
                selectedColor: themeColor,
                backgroundColor: Colors.white,
                labelStyle: AppTextStyles.captionBold.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                side: BorderSide(
                  color: isSelected ? themeColor : AppColors.border,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                showCheckmark: false,
                onSelected: (_) => _toggleSkill(skill, type),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        labelStyle: AppTextStyles.captionBold.copyWith(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 12,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        showCheckmark: false,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
        },
      ),
    );
  }

  Widget _buildRequirementBadge({
    required String label,
    required bool isSatisfied,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSatisfied ? Icons.check_circle : Icons.circle_outlined,
          size: 14,
          color: isSatisfied ? color : AppColors.textMuted,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: isSatisfied ? color : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
