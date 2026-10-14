import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exchange_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../rating/rating_review_modal.dart';

class ConversationScreen extends StatefulWidget {
  final ExchangeRequestModel request;
  final String partnerId;
  final String partnerName;
  final String? partnerDept;

  const ConversationScreen({
    super.key,
    required this.request,
    required this.partnerId,
    required this.partnerName,
    this.partnerDept,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _canSend = false;
  bool _showScrollToBottom = false;
  bool _isUploadingImage = false;
  int _prevMessageCount = 0;

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      final canSend = _textController.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isNearBottom = _scrollController.position.maxScrollExtent -
                _scrollController.offset <
            120;
        if (_showScrollToBottom == isNearBottom) {
          setState(() {
            _showScrollToBottom = !isNearBottom;
          });
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      chatProvider.activeConversationRequestId = widget.request.id;
      if (authProvider.currentUser != null) {
        chatProvider.markRequestAsRead(widget.request.id, authProvider.currentUser!.id);
      }
      _scrollToBottom(immediate: true);
    });
  }

  @override
  void dispose() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.activeConversationRequestId = null;
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (immediate) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuad,
          );
        }
      }
    });
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.lightImpact();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser != null) {
      chatProvider.sendMessage(
        requestId: widget.request.id,
        senderId: currentUser.id,
        text: text,
        senderName: currentUser.name,
      );
      if (presetText == null) {
        _textController.clear();
      }
      _scrollToBottom();
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingImage = true);

      final bytes = await pickedFile.readAsBytes();
      final base64String = base64Encode(bytes);

      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser != null) {
        final caption = _textController.text.trim();
        await chatProvider.sendMessage(
          requestId: widget.request.id,
          senderId: currentUser.id,
          text: caption.isNotEmpty ? caption : '📷 Photo',
          senderName: currentUser.name,
          imageBase64: base64String,
        );
        _textController.clear();
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share Image',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Take a Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Capture with camera'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSendImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                  ),
                  title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pick study notes, screenshots, diagrams'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndSendImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewFullScreenImage(String base64Str) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(base64Decode(base64Str)),
            ),
          ),
        ),
      ),
    );
  }

  void _openRatingModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingReviewModal(
        request: widget.request,
        partnerId: widget.partnerId,
        partnerName: widget.partnerName,
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (now.year == date.year && now.month == date.month && now.day == date.day) {
      return 'Today';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == date.year &&
        yesterday.month == date.month &&
        yesterday.day == date.day) {
      return 'Yesterday';
    }
    return DateFormat('EEEE, MMM dd').format(date);
  }

  bool _isDifferentDay(DateTime date1, DateTime date2) {
    return date1.year != date2.year ||
        date1.month != date2.month ||
        date1.day != date2.day;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentUser = authProvider.currentUser;

    final messages = chatProvider.getMessagesForRequest(widget.request.id);

    if (messages.length > _prevMessageCount) {
      _prevMessageCount = messages.length;
      if (!_showScrollToBottom) {
        _scrollToBottom();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 19, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    widget.partnerName.isNotEmpty ? widget.partnerName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppColors.teachBadge,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.teachBadge,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.partnerDept != null && widget.partnerDept!.isNotEmpty
                            ? '${widget.partnerDept} • Active'
                            : 'Active now',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'complete') {
                _openRatingModal();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'complete',
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.amber, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Rate & Complete Session',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Chat Message Stream
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.handshake_rounded,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Exchange Request Accepted! 🎉',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Say hi to ${widget.partnerName} and schedule your first skill swap session.',
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            final isMe = currentUser != null && msg.senderId == currentUser.id;
                            final timeStr = DateFormat('hh:mm a').format(msg.timestamp);

                            final showDateHeader = index == 0 ||
                                _isDifferentDay(
                                    messages[index - 1].timestamp, msg.timestamp);

                            return Column(
                              children: [
                                if (showDateHeader) ...[
                                  Container(
                                    margin: const EdgeInsets.symmetric(vertical: 14),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _formatDateHeader(msg.timestamp),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    mainAxisAlignment: isMe
                                        ? MainAxisAlignment.end
                                        : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Partner Avatar beside incoming bubble
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: 14,
                                          backgroundColor:
                                              AppColors.primary.withValues(alpha: 0.12),
                                          child: Text(
                                            widget.partnerName.isNotEmpty
                                                ? widget.partnerName[0].toUpperCase()
                                                : 'U',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],

                                      // Bubble
                                      Flexible(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(context).size.width * 0.74,
                                          ),
                                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                                          decoration: BoxDecoration(
                                            gradient: isMe
                                                ? const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      AppColors.primary,
                                                      Color(0xFF0F766E),
                                                    ],
                                                  )
                                                : null,
                                            color: isMe ? null : Colors.white,
                                            borderRadius: BorderRadius.only(
                                              topLeft: const Radius.circular(18),
                                              topRight: const Radius.circular(18),
                                              bottomLeft: isMe
                                                  ? const Radius.circular(18)
                                                  : const Radius.circular(4),
                                              bottomRight: isMe
                                                  ? const Radius.circular(4)
                                                  : const Radius.circular(18),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                    alpha: isMe ? 0.12 : 0.04),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                            border: isMe
                                                ? null
                                                : Border.all(
                                                    color: AppColors.border
                                                        .withValues(alpha: 0.8),
                                                    width: 1,
                                                  ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isMe
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              // Image inside bubble if present
                                              if (msg.imageBase64 != null) ...[
                                                GestureDetector(
                                                  onTap: () => _viewFullScreenImage(
                                                      msg.imageBase64!),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                    child: Image.memory(
                                                      base64Decode(msg.imageBase64!),
                                                      width: double.infinity,
                                                      height: 180,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),
                                                if (msg.text != '📷 Photo' &&
                                                    msg.text.trim().isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    msg.text,
                                                    style: TextStyle(
                                                      fontSize: 14.5,
                                                      height: 1.35,
                                                      color: isMe
                                                          ? Colors.white
                                                          : const Color(0xFF1E293B),
                                                      fontWeight: FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
                                              ] else ...[
                                                Text(
                                                  msg.text,
                                                  style: TextStyle(
                                                    fontSize: 14.5,
                                                    height: 1.35,
                                                    color: isMe
                                                        ? Colors.white
                                                        : const Color(0xFF1E293B),
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    timeStr,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w500,
                                                      color: isMe
                                                          ? Colors.white.withValues(alpha: 0.75)
                                                          : const Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                  if (isMe) ...[
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.done_all_rounded,
                                                      size: 14,
                                                      color: Color(0xFF67E8F9),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),

                // Uploading Image Indicator
                if (_isUploadingImage)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.white,
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sending image...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick Replies Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 12, right: 6),
                        child: Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(right: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: ChatProvider.quickReplies.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, idx) {
                              final reply = ChatProvider.quickReplies[idx];
                              return ActionChip(
                                label: Text(reply),
                                labelStyle: const TextStyle(
                                  color: AppColors.primaryDark,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.08),
                                side: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                padding: EdgeInsets.zero,
                                onPressed: () => _sendMessage(reply),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppColors.border),

                // Bottom Input Bar with Image Attachment Button
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // Camera / Gallery Image Attachment Button
                      IconButton(
                        icon: const Icon(
                          Icons.add_photo_alternate_rounded,
                          color: AppColors.primary,
                          size: 26,
                        ),
                        tooltip: 'Share Image',
                        onPressed: _isUploadingImage ? null : _showImagePickerSheet,
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _textController,
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 4,
                            minLines: 1,
                            style: const TextStyle(fontSize: 14.5),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: _canSend
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primary,
                                    Color(0xFF0F766E),
                                  ],
                                )
                              : null,
                          color: _canSend ? null : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                          boxShadow: _canSend
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: _canSend ? Colors.white : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          onPressed: _canSend ? () => _sendMessage() : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Scroll to Bottom Button
            if (_showScrollToBottom)
              Positioned(
                bottom: 110,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                  elevation: 4,
                  onPressed: () => _scrollToBottom(),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 26),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
