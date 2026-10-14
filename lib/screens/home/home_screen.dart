import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/mock_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/match_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/match_card.dart';
import '../auth/skill_onboarding_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sync();
    });
  }

  Future<void> _sync() async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final matchProvider = Provider.of<MatchProvider>(context, listen: false);
    final requestProvider = Provider.of<RequestProvider>(context, listen: false);

    final user = authProvider.currentUser;
    if (user != null) {
      await authProvider.syncCurrentUserToFirestore();
      matchProvider.syncWithUser(user);
      requestProvider.syncWithUser(user);
    }

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final matchProvider = Provider.of<MatchProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);

    final currentUser = authProvider.currentUser;
    final rankedMatches = matchProvider.getRankedMatches(currentUser);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, ${currentUser?.name.split(' ').first ?? 'Student'} 👋',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Find peers with complementary skills',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Sync / Refresh button
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 22),
                      tooltip: 'Refresh Matches',
                      onPressed: _isRefreshing ? null : _sync,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Notification bell
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No new system notifications'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: TextField(
                onChanged: (val) => matchProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: 'Search by student name or skill (e.g. Python)',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                  suffixIcon: matchProvider.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => matchProvider.setSearchQuery(''),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Department Filters horizontal list
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: MockData.departments.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final dept = MockData.departments[idx];
                  final isSelected = matchProvider.selectedDepartment == dept;

                  return FilterChip(
                    label: Text(dept),
                    selected: isSelected,
                    onSelected: (_) => matchProvider.setSelectedDepartment(dept),
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary,
                    labelStyle: AppTextStyles.captionBold.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // Match Cards List with Pull to Refresh
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _sync,
                child: matchProvider.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      )
                    : rankedMatches.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 60),
                              EmptyState(
                                icon: Icons.find_in_page_outlined,
                                title: 'No Matches Found',
                                description: currentUser?.teachSkills.isEmpty == true ||
                                        currentUser?.learnSkills.isEmpty == true
                                    ? 'Add skills you teach and want to learn to get matched.'
                                    : 'Try relaxing your filters or add more skills to your inventory.',
                                buttonText: 'Update Skills',
                                onButtonPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SkillOnboardingScreen(isEditingProfile: true),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            itemCount: rankedMatches.length,
                            itemBuilder: (context, index) {
                              final matchItem = rankedMatches[index];
                              final candidate = matchItem.candidate;
                              final result = matchItem.result;

                              final isSent = currentUser != null &&
                                  requestProvider.isRequestSent(currentUser.id, candidate.id);

                              return MatchCard(
                                candidate: candidate,
                                matchResult: result,
                                isRequestSent: isSent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MatchDetailScreen(
                                        candidate: candidate,
                                        matchResult: result,
                                      ),
                                    ),
                                  );
                                },
                                onConnect: () {
                                  if (currentUser != null) {
                                    requestProvider.sendRequest(
                                      fromUser: currentUser,
                                      toUser: candidate,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Swap request sent to ${candidate.name}!'),
                                        backgroundColor: AppColors.primary,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
