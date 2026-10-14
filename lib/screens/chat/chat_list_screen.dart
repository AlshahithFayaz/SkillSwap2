import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/empty_state.dart';
import 'conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1 && now.day == timestamp.day) {
      return DateFormat('hh:mm a').format(timestamp);
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final acceptedRequests = requestProvider.getAccepted(currentUser.id);

    // Keep chat streams synced for all accepted requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatProvider.syncAcceptedConversations(
        acceptedRequests: acceptedRequests,
        currentUserId: currentUser.id,
      );
    });

    final totalUnread = chatProvider.getTotalUnreadCount(currentUser.id);

    // Filter by search query
    final filteredRequests = acceptedRequests.where((req) {
      if (_searchQuery.isEmpty) return true;
      final isIncoming = req.toUserId == currentUser.id;
      final partnerName = (isIncoming ? req.fromUserName : req.toUserName) ?? '';
      final partnerDept = (isIncoming ? req.fromUserDept : req.toUserDept) ?? '';
      return partnerName.toLowerCase().contains(_searchQuery) ||
          partnerDept.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (totalUnread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalUnread new',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: acceptedRequests.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No Active Conversations',
              description:
                  'Chats unlock automatically once an exchange request is accepted by both partners. Connect with peers from the Home or Matches tab!',
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search chats or partners...',
                      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.border),

                // Conversation List
                Expanded(
                  child: filteredRequests.isEmpty
                      ? const Center(
                          child: Text(
                            'No matching conversations found',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: filteredRequests.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 82, endIndent: 16, color: Color(0xFFF1F5F9)),
                          itemBuilder: (context, index) {
                            final req = filteredRequests[index];
                            final isIncoming = req.toUserId == currentUser.id;
                            final partnerId = isIncoming ? req.fromUserId : req.toUserId;
                            final partnerName =
                                (isIncoming ? req.fromUserName : req.toUserName) ?? 'Skill Partner';
                            final partnerDept = isIncoming ? req.fromUserDept : req.toUserDept;

                            final lastMsg = chatProvider.getLastMessageForRequest(req.id);
                            final unreadCount =
                                chatProvider.getUnreadCountForRequest(req.id, currentUser.id);
                            final hasUnread = unreadCount > 0;

                            final timeDisplay = lastMsg != null
                                ? _formatTimestamp(lastMsg.timestamp)
                                : DateFormat('MMM dd').format(req.createdAt);

                            final isSentByMe = lastMsg != null && lastMsg.senderId == currentUser.id;

                            return Material(
                              color: hasUnread ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  chatProvider.markRequestAsRead(req.id, currentUser.id);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ConversationScreen(
                                        request: req,
                                        partnerId: partnerId,
                                        partnerName: partnerName,
                                        partnerDept: partnerDept,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Avatar with Online Badge
                                      Stack(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  AppColors.primary.withValues(alpha: 0.15),
                                                  AppColors.cyan.withValues(alpha: 0.25),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: hasUnread ? AppColors.primary : AppColors.border,
                                                width: hasUnread ? 2 : 1,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                partnerName.isNotEmpty
                                                    ? partnerName[0].toUpperCase()
                                                    : 'U',
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 1,
                                            right: 1,
                                            child: Container(
                                              width: 13,
                                              height: 13,
                                              decoration: BoxDecoration(
                                                color: AppColors.teachBadge,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 14),

                                      // Main info & message snippet
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          partnerName,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: hasUnread
                                                                ? FontWeight.w700
                                                                : FontWeight.w600,
                                                            color: AppColors.textPrimary,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (partnerDept != null && partnerDept.isNotEmpty) ...[
                                                        const SizedBox(width: 6),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                              horizontal: 6, vertical: 1.5),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFF1F5F9),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            partnerDept,
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                              color: AppColors.textMuted,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  timeDisplay,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: hasUnread
                                                        ? AppColors.primary
                                                        : AppColors.textMuted,
                                                    fontWeight: hasUnread
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 5),

                                            Row(
                                              children: [
                                                if (isSentByMe) ...[
                                                  const Icon(
                                                    Icons.done_all_rounded,
                                                    size: 16,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 4),
                                                ],
                                                Expanded(
                                                  child: Text(
                                                    lastMsg?.text ??
                                                        'Exchange accepted! Tap to schedule your session.',
                                                    style: TextStyle(
                                                      fontSize: 13.5,
                                                      color: hasUnread
                                                          ? AppColors.textPrimary
                                                          : (lastMsg != null
                                                              ? AppColors.textSecondary
                                                              : AppColors.primary),
                                                      fontWeight: hasUnread
                                                          ? FontWeight.w600
                                                          : FontWeight.w400,
                                                      fontStyle: lastMsg == null
                                                          ? FontStyle.italic
                                                          : FontStyle.normal,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasUnread) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: const BoxDecoration(
                                                      color: AppColors.primary,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: Text(
                                                      '$unreadCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w700,
                                                        height: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
