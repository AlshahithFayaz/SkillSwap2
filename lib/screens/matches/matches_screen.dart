import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/exchange_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../chat/conversation_screen.dart';
import '../rating/rating_review_modal.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final requestProvider = Provider.of<RequestProvider>(context);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final incomingPending = requestProvider.getPendingIncoming(currentUser.id);
    final outgoingPending = requestProvider.getPendingOutgoing(currentUser.id);
    final accepted = requestProvider.getAccepted(currentUser.id);
    final rejected = requestProvider.getRejected(currentUser.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Exchange Requests'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.captionBold.copyWith(fontSize: 13),
          tabs: [
            Tab(text: 'Pending (${incomingPending.length + outgoingPending.length})'),
            Tab(text: 'Accepted (${accepted.length})'),
            Tab(text: 'Rejected (${rejected.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending Tab (Both Incoming and Outgoing)
          _buildPendingTab(incomingPending, outgoingPending, requestProvider, currentUser.id),
          // Accepted Tab
          _buildAcceptedTab(accepted, requestProvider, currentUser.id),
          // Rejected Tab
          _buildRejectedTab(rejected, currentUser.id),
        ],
      ),
    );
  }

  Widget _buildPendingTab(
    List<ExchangeRequestModel> incoming,
    List<ExchangeRequestModel> outgoing,
    RequestProvider provider,
    String currentUserId,
  ) {
    if (incoming.isEmpty && outgoing.isEmpty) {
      return const EmptyState(
        icon: Icons.hourglass_empty_rounded,
        title: 'No Pending Requests',
        description: 'Connect with peers on the Home feed to begin skill exchanges.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        if (incoming.isNotEmpty) ...[
          Text('Incoming Requests', style: AppTextStyles.subheading),
          const SizedBox(height: 10),
          ...incoming.map((req) => _buildIncomingCard(req, provider)),
          const SizedBox(height: 20),
        ],
        if (outgoing.isNotEmpty) ...[
          Text('Sent by You', style: AppTextStyles.subheading),
          const SizedBox(height: 10),
          ...outgoing.map((req) => _buildOutgoingCard(req, provider)),
        ],
      ],
    );
  }

  Widget _buildIncomingCard(ExchangeRequestModel req, RequestProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  req.fromUserName != null && req.fromUserName!.isNotEmpty
                      ? req.fromUserName![0].toUpperCase()
                      : 'U',
                  style: AppTextStyles.heading.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.fromUserName ?? 'Student Peer', style: AppTextStyles.subheading),
                    Text(
                      req.fromUserDept ?? 'College Student',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const StatusBadge(status: RequestStatus.pending),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'Accept',
                  icon: Icons.check,
                  height: 40,
                  onPressed: () => provider.acceptRequest(req.id),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomButton(
                  text: 'Reject',
                  icon: Icons.close,
                  variant: ButtonVariant.destructive,
                  height: 40,
                  onPressed: () => provider.rejectRequest(req.id),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutgoingCard(ExchangeRequestModel req, RequestProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.surfaceMuted,
            child: Text(
              req.toUserName != null && req.toUserName!.isNotEmpty
                  ? req.toUserName![0].toUpperCase()
                  : 'U',
              style: AppTextStyles.heading.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req.toUserName ?? 'Student Peer', style: AppTextStyles.subheading),
                Text(req.toUserDept ?? 'College Student', style: AppTextStyles.caption),
              ],
            ),
          ),
          CustomButton(
            text: 'Cancel',
            variant: ButtonVariant.ghost,
            height: 36,
            onPressed: () => provider.cancelRequest(req.id),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedTab(
    List<ExchangeRequestModel> accepted,
    RequestProvider provider,
    String currentUserId,
  ) {
    if (accepted.isEmpty) {
      return const EmptyState(
        icon: Icons.handshake_outlined,
        title: 'No Accepted Exchanges Yet',
        description: 'When someone accepts your request (or you accept theirs), they appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: accepted.length,
      itemBuilder: (context, index) {
        final req = accepted[index];
        final isIncoming = req.toUserId == currentUserId;
        final partnerId = isIncoming ? req.fromUserId : req.toUserId;
        final partnerName =
            (isIncoming ? req.fromUserName : req.toUserName) ?? 'Student Peer';
        final partnerDept = isIncoming ? req.fromUserDept : req.toUserDept;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'U',
                      style: AppTextStyles.heading.copyWith(color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partnerName, style: AppTextStyles.subheading),
                        Text(partnerDept ?? 'Partner', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const StatusBadge(status: RequestStatus.accepted),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Open Chat',
                      icon: Icons.chat_bubble_outline_rounded,
                      height: 40,
                      onPressed: () {
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
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Mark Complete',
                      variant: ButtonVariant.secondary,
                      icon: Icons.star_outline_rounded,
                      height: 40,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => RatingReviewModal(
                            request: req,
                            partnerId: partnerId,
                            partnerName: partnerName,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRejectedTab(List<ExchangeRequestModel> rejected, String currentUserId) {
    if (rejected.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Rejected Requests',
        description: 'You have no rejected exchanges in your history.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: rejected.length,
      itemBuilder: (context, index) {
        final req = rejected[index];
        final isIncoming = req.toUserId == currentUserId;
        final partnerName =
            (isIncoming ? req.fromUserName : req.toUserName) ?? 'Student Peer';
        final partnerDept = isIncoming ? req.fromUserDept : req.toUserDept;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceMuted,
                child: Text(
                  partnerName.isNotEmpty ? partnerName[0].toUpperCase() : 'U',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partnerName, style: AppTextStyles.subheading),
                    Text(partnerDept ?? 'College Student', style: AppTextStyles.caption),
                  ],
                ),
              ),
              const StatusBadge(status: RequestStatus.rejected),
            ],
          ),
        );
      },
    );
  }
}
