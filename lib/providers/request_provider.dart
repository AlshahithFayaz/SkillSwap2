import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/exchange_request_model.dart';
import '../data/models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class RequestProvider with ChangeNotifier {
  final LocalStorageService _storage;
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();
  StreamSubscription? _requestsSub;

  List<ExchangeRequestModel> _requests = [];
  bool _isLoading = false;

  List<ExchangeRequestModel> get requests => _requests;
  bool get isLoading => _isLoading;

  RequestProvider(this._storage) {
    loadRequests();
  }

  void loadRequests() {
    _isLoading = true;
    _requests = _storage.getRequests();
    _isLoading = false;
    notifyListeners();
  }

  void syncWithUser(UserModel? currentUser) {
    if (currentUser == null) return;
    _requests = _storage.getRequests();
    notifyListeners();

    if (_firebase.isInitialized) {
      _requestsSub?.cancel();
      _requestsSub = _firebase.streamUserRequests(currentUser.id).listen((firestoreRequests) {
        debugPrint('RequestProvider: received ${firestoreRequests.length} requests from Firestore');
        _requests = firestoreRequests;
        _storage.saveRequests(_requests);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error streaming requests: $e');
      });
    }
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
  }

  bool isRequestSent(String currentUserId, String targetUserId) {
    return _requests.any((r) =>
        r.fromUserId == currentUserId &&
        r.toUserId == targetUserId &&
        r.status == RequestStatus.pending);
  }

  bool isConnected(String currentUserId, String targetUserId) {
    return _requests.any((r) =>
        ((r.fromUserId == currentUserId && r.toUserId == targetUserId) ||
            (r.fromUserId == targetUserId && r.toUserId == currentUserId)) &&
        r.status == RequestStatus.accepted);
  }

  ExchangeRequestModel? getRequestBetween(String user1, String user2) {
    try {
      return _requests.firstWhere((r) =>
          (r.fromUserId == user1 && r.toUserId == user2) ||
          (r.fromUserId == user2 && r.toUserId == user1));
    } catch (_) {
      return null;
    }
  }

  Future<void> sendRequest({
    required UserModel fromUser,
    required UserModel toUser,
  }) async {
    final newRequest = ExchangeRequestModel(
      id: _uuid.v4(),
      fromUserId: fromUser.id,
      toUserId: toUser.id,
      status: RequestStatus.pending,
      createdAt: DateTime.now(),
      fromUserName: fromUser.name,
      toUserName: toUser.name,
      fromUserDept: '${fromUser.department} • ${fromUser.year}',
      toUserDept: '${toUser.department} • ${toUser.year}',
    );

    _requests.insert(0, newRequest);
    await _storage.saveRequests(_requests);

    if (_firebase.isInitialized) {
      await _firebase.createRequest(newRequest);
    }

    notifyListeners();
  }

  Future<void> acceptRequest(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: RequestStatus.accepted);
      await _storage.saveRequests(_requests);

      if (_firebase.isInitialized) {
        await _firebase.updateRequestStatus(requestId, RequestStatus.accepted);
      }

      notifyListeners();
    }
  }

  Future<void> rejectRequest(String requestId) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: RequestStatus.rejected);
      await _storage.saveRequests(_requests);

      if (_firebase.isInitialized) {
        await _firebase.updateRequestStatus(requestId, RequestStatus.rejected);
      }

      notifyListeners();
    }
  }

  Future<void> cancelRequest(String requestId) async {
    _requests.removeWhere((r) => r.id == requestId);
    await _storage.saveRequests(_requests);

    if (_firebase.isInitialized) {
      await _firebase.updateRequestStatus(requestId, RequestStatus.rejected);
    }

    notifyListeners();
  }

  List<ExchangeRequestModel> getPendingIncoming(String currentUserId) {
    return _requests
        .where((r) => r.toUserId == currentUserId && r.status == RequestStatus.pending)
        .toList();
  }

  List<ExchangeRequestModel> getPendingOutgoing(String currentUserId) {
    return _requests
        .where((r) => r.fromUserId == currentUserId && r.status == RequestStatus.pending)
        .toList();
  }

  List<ExchangeRequestModel> getAccepted(String currentUserId) {
    return _requests
        .where((r) =>
            (r.fromUserId == currentUserId || r.toUserId == currentUserId) &&
            r.status == RequestStatus.accepted)
        .toList();
  }

  List<ExchangeRequestModel> getRejected(String currentUserId) {
    return _requests
        .where((r) =>
            (r.fromUserId == currentUserId || r.toUserId == currentUserId) &&
            r.status == RequestStatus.rejected)
        .toList();
  }
}
