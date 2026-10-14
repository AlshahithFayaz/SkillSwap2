import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../data/models/exchange_request_model.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/match_provider.dart';
import '../providers/request_provider.dart';
import 'chat/conversation_screen.dart';
import 'home/home_screen.dart';
import 'matches/matches_screen.dart';
import 'chat/chat_list_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  StreamSubscription<IncomingMessageAlert>? _alertSub;
  IncomingMessageAlert? _currentAlert;
  Timer? _alertDismissTimer;

  late AnimationController _bannerAnimController;
  late Animation<Offset> _bannerOffsetAnim;

  final List<Widget> _screens = const [
    HomeScreen(),
    MatchesScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();

    _bannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _bannerOffsetAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bannerAnimController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInQuad,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final match = Provider.of<MatchProvider>(context, listen: false);
      final req = Provider.of<RequestProvider>(context, listen: false);
      final chat = Provider.of<ChatProvider>(context, listen: false);

      if (auth.currentUser != null) {
        auth.syncCurrentUserToFirestore();
        match.syncWithUser(auth.currentUser);
        req.syncWithUser(auth.currentUser);
        chat.syncAcceptedConversations(
          acceptedRequests: req.getAccepted(auth.currentUser!.id),
          currentUserId: auth.currentUser!.id,
        );
      }

      // Listen to incoming message alerts for in-app floating banner
      _alertSub = chat.onNewIncomingAlert.listen((alert) {
        _triggerIncomingAlert(alert);
      });
    });
  }

  void _triggerIncomingAlert(IncomingMessageAlert alert) {
    if (!mounted) return;
    HapticFeedback.mediumImpact();

    _alertDismissTimer?.cancel();
    setState(() {
      _currentAlert = alert;
    });

    _bannerAnimController.forward();

    // Auto-dismiss after 4.5 seconds
    _alertDismissTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        _bannerAnimController.reverse().then((_) {
          if (mounted) {
            setState(() => _currentAlert = null);
          }
        });
      }
    });
  }

  void _openAlertChat(IncomingMessageAlert alert) {
    _alertDismissTimer?.cancel();
    _bannerAnimController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentAlert = null);
      }
    });

    final reqProvider = Provider.of<RequestProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    ExchangeRequestModel? targetRequest;
    try {
      targetRequest = reqProvider.requests.firstWhere((r) => r.id == alert.requestId);
    } catch (_) {
      targetRequest = null;
    }

    if (targetRequest != null) {
      if (authProvider.currentUser != null) {
        chatProvider.markRequestAsRead(targetRequest.id, authProvider.currentUser!.id);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            request: targetRequest!,
            partnerId: alert.partnerId,
            partnerName: alert.senderName,
            partnerDept: alert.partnerDept,
          ),
        ),
      );
    } else {
      // Switch to Chat tab
      setState(() => _currentIndex = 2);
    }
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    _alertDismissTimer?.cancel();
    _bannerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = authProvider.currentUser;

    final pendingIncomingCount = currentUser != null
        ? requestProvider.getPendingIncoming(currentUser.id).length
        : 0;

    final acceptedRequests = currentUser != null
        ? requestProvider.getAccepted(currentUser.id)
        : <ExchangeRequestModel>[];

    if (currentUser != null && acceptedRequests.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatProvider.syncAcceptedConversations(
          acceptedRequests: acceptedRequests,
          currentUserId: currentUser.id,
        );
      });
    }

    final unreadChatCount = currentUser != null
        ? chatProvider.getTotalUnreadCount(currentUser.id)
        : 0;

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // Floating In-App New Message Alert Banner
          if (_currentAlert != null)
            SlideTransition(
              position: _bannerOffsetAnim,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Material(
                    elevation: 10,
                    shadowColor: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: InkWell(
                      onTap: () => _openAlertChat(_currentAlert!),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Partner Avatar
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                gradient: AppColors.brandGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _currentAlert!.senderName.isNotEmpty
                                      ? _currentAlert!.senderName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Partner Message Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          _currentAlert!.senderName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
                                            color: AppColors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Text(
                                        'Just now',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentAlert!.message.text,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Reply Button
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Reply',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              setState(() => _currentIndex = idx);
            },
            backgroundColor: Colors.white,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            height: 64,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingIncomingCount > 0,
                  label: Text('$pendingIncomingCount'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColors.textMuted),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingIncomingCount > 0,
                  label: Text('$pendingIncomingCount'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                ),
                label: 'Matches',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: unreadChatCount > 0,
                  label: Text('$unreadChatCount'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.chat_bubble_outline_rounded,
                      color: AppColors.textMuted),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unreadChatCount > 0,
                  label: Text('$unreadChatCount'),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                ),
                label: 'Chat',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
