import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/exchange_request_model.dart';
import '../data/models/message_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class IncomingMessageAlert {
  final MessageModel message;
  final String requestId;
  final String senderName;
  final String partnerId;
  final String? partnerDept;

  IncomingMessageAlert({
    required this.message,
    required this.requestId,
    required this.senderName,
    required this.partnerId,
    this.partnerDept,
  });
}

class ChatProvider with ChangeNotifier {
  final LocalStorageService _storage;
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();

  final Map<String, StreamSubscription> _conversationSubs = {};
  final Set<String> _readMessageIds = {};
  final Set<String> _knownMessageIds = {};
  final StreamController<IncomingMessageAlert> _incomingAlertController =
      StreamController<IncomingMessageAlert>.broadcast();

  Stream<IncomingMessageAlert> get onNewIncomingAlert => _incomingAlertController.stream;

  List<MessageModel> _allMessages = [];
  bool _isLoading = false;
  String? activeConversationRequestId;

  List<MessageModel> get allMessages => _allMessages;
  bool get isLoading => _isLoading;

  ChatProvider(this._storage) {
    loadMessages();
    _readMessageIds.addAll(_storage.getReadMessageIds());
  }

  void loadMessages() {
    _isLoading = true;
    _allMessages = _storage.getMessages();
    for (final m in _allMessages) {
      _knownMessageIds.add(m.id);
    }
    _isLoading = false;
    notifyListeners();
  }

  void syncAcceptedConversations({
    required List<ExchangeRequestModel> acceptedRequests,
    required String currentUserId,
  }) {
    if (!_firebase.isInitialized) return;

    for (final req in acceptedRequests) {
      if (_conversationSubs.containsKey(req.id)) continue;

      final isIncoming = req.toUserId == currentUserId;
      final partnerId = isIncoming ? req.fromUserId : req.toUserId;
      final partnerName = (isIncoming ? req.fromUserName : req.toUserName) ?? 'Skill Partner';
      final partnerDept = isIncoming ? req.fromUserDept : req.toUserDept;

      bool isInitial = true;
      _conversationSubs[req.id] = _firebase.streamMessages(req.id).listen((messages) {
        bool hasChanges = false;
        for (final m in messages) {
          if (!_knownMessageIds.contains(m.id)) {
            _knownMessageIds.add(m.id);
            _allMessages.removeWhere((existing) => existing.id == m.id);
            _allMessages.add(m);
            hasChanges = true;

            if (m.senderId != currentUserId) {
              if (activeConversationRequestId == req.id) {
                // Actively viewing this screen
                _readMessageIds.add(m.id);
                _storage.saveReadMessageIds(_readMessageIds.toList());
              } else if (!isInitial) {
                // Notify user with in-app alert banner
                _incomingAlertController.add(
                  IncomingMessageAlert(
                    message: m,
                    requestId: req.id,
                    senderName: partnerName,
                    partnerId: partnerId,
                    partnerDept: partnerDept,
                  ),
                );
              }
            }
          }
        }
        isInitial = false;

        if (hasChanges) {
          _allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          _storage.saveMessages(_allMessages);
          notifyListeners();
        }
      }, onError: (e) {
        debugPrint('Error streaming messages for req ${req.id}: $e');
      });
    }
  }

  void markRequestAsRead(String requestId, [String? currentUserId]) {
    final msgs = getMessagesForRequest(requestId);
    bool changed = false;
    for (final m in msgs) {
      if (currentUserId == null || m.senderId != currentUserId) {
        if (!_readMessageIds.contains(m.id)) {
          _readMessageIds.add(m.id);
          changed = true;
        }
      }
    }
    if (changed) {
      _storage.saveReadMessageIds(_readMessageIds.toList());
      notifyListeners();
    }
  }

  int getUnreadCountForRequest(String requestId, String currentUserId) {
    return _allMessages
        .where((m) =>
            m.requestId == requestId &&
            m.senderId != currentUserId &&
            !_readMessageIds.contains(m.id))
        .length;
  }

  int getTotalUnreadCount(String currentUserId) {
    return _allMessages
        .where((m) =>
            m.senderId != currentUserId &&
            !_readMessageIds.contains(m.id))
        .length;
  }

  void subscribeToConversation(String requestId) {
    // Kept for backward compatibility, syncAcceptedConversations handles streaming
  }

  void unsubscribeFromConversation() {
    activeConversationRequestId = null;
  }

  @override
  void dispose() {
    for (final sub in _conversationSubs.values) {
      sub.cancel();
    }
    _conversationSubs.clear();
    _incomingAlertController.close();
    super.dispose();
  }

  List<MessageModel> getMessagesForRequest(String requestId) {
    final list = _allMessages.where((m) => m.requestId == requestId).toList();
    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  MessageModel? getLastMessageForRequest(String requestId) {
    final list = getMessagesForRequest(requestId);
    return list.isNotEmpty ? list.last : null;
  }

  Future<void> sendMessage({
    required String requestId,
    required String senderId,
    required String text,
    String? senderName,
    String? imageBase64,
  }) async {
    if (text.trim().isEmpty && imageBase64 == null) return;

    final newMessage = MessageModel(
      id: _uuid.v4(),
      requestId: requestId,
      senderId: senderId,
      text: text.trim().isEmpty ? '📷 Photo' : text.trim(),
      timestamp: DateTime.now(),
      senderName: senderName,
      imageBase64: imageBase64,
    );

    _knownMessageIds.add(newMessage.id);
    _readMessageIds.add(newMessage.id);
    _allMessages.add(newMessage);
    await _storage.saveMessages(_allMessages);
    await _storage.saveReadMessageIds(_readMessageIds.toList());

    if (_firebase.isInitialized) {
      await _firebase.sendMessage(requestId, newMessage);
    }

    notifyListeners();
  }

  static const List<String> quickReplies = [
    'Tomorrow 5 PM?',
    'This weekend works for me!',
    'Shall we meet at the library?',
    'Are you free today evening?',
    'I have prepared the topics!',
  ];
}
