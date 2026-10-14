import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/user_model.dart';
import '../data/models/exchange_request_model.dart';
import '../data/models/message_model.dart';
import '../data/models/review_model.dart';

class LocalStorageService {
  static const String _keyCurrentUser = 'skillswap_current_user';
  static const String _keyUsers = 'skillswap_all_users';
  static const String _keyRequests = 'skillswap_all_requests';
  static const String _keyMessages = 'skillswap_all_messages';
  static const String _keyReviews = 'skillswap_all_reviews';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // Current User
  Future<void> saveCurrentUser(UserModel user) async {
    await _prefs.setString(_keyCurrentUser, jsonEncode(user.toMap()));
  }

  UserModel? getCurrentUser() {
    final str = _prefs.getString(_keyCurrentUser);
    if (str == null) return null;
    try {
      return UserModel.fromMap(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  Future<void> clearCurrentUser() async {
    await _prefs.remove(_keyCurrentUser);
  }

  // All Peers
  Future<void> saveUsers(List<UserModel> users) async {
    final list = users.map((u) => u.toMap()).toList();
    await _prefs.setString(_keyUsers, jsonEncode(list));
  }

  List<UserModel> getUsers() {
    final str = _prefs.getString(_keyUsers);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((item) => UserModel.fromMap(item)).toList();
    } catch (_) {
      return [];
    }
  }

  // Requests
  Future<void> saveRequests(List<ExchangeRequestModel> requests) async {
    final list = requests.map((r) => r.toMap()).toList();
    await _prefs.setString(_keyRequests, jsonEncode(list));
  }

  List<ExchangeRequestModel> getRequests() {
    final str = _prefs.getString(_keyRequests);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((item) => ExchangeRequestModel.fromMap(item)).toList();
    } catch (_) {
      return [];
    }
  }

  // Messages
  Future<void> saveMessages(List<MessageModel> messages) async {
    final list = messages.map((m) => m.toMap()).toList();
    await _prefs.setString(_keyMessages, jsonEncode(list));
  }

  List<MessageModel> getMessages() {
    final str = _prefs.getString(_keyMessages);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((item) => MessageModel.fromMap(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static const String _keyReadMessageIds = 'skillswap_read_message_ids';

  Future<void> saveReadMessageIds(List<String> ids) async {
    await _prefs.setStringList(_keyReadMessageIds, ids);
  }

  List<String> getReadMessageIds() {
    return _prefs.getStringList(_keyReadMessageIds) ?? [];
  }

  // Reviews
  Future<void> saveReviews(List<ReviewModel> reviews) async {
    final list = reviews.map((r) => r.toMap()).toList();
    await _prefs.setString(_keyReviews, jsonEncode(list));
  }

  List<ReviewModel> getReviews() {
    final str = _prefs.getString(_keyReviews);
    if (str == null) return [];
    try {
      final list = jsonDecode(str) as List;
      return list.map((item) => ReviewModel.fromMap(item)).toList();
    } catch (_) {
      return [];
    }
  }
}
