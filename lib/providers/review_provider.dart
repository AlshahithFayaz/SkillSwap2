import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/review_model.dart';
import '../data/models/user_model.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class ReviewProvider with ChangeNotifier {
  final LocalStorageService _storage;
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();

  List<ReviewModel> _reviews = [];
  bool _isLoading = false;

  List<ReviewModel> get reviews => _reviews;
  bool get isLoading => _isLoading;

  ReviewProvider(this._storage) {
    loadReviews();
  }

  void loadReviews() {
    _isLoading = true;
    notifyListeners();
    _reviews = _storage.getReviews();
    _isLoading = false;
    notifyListeners();
  }

  bool hasReviewed(String requestId, String reviewerId) {
    return _reviews.any((r) => r.requestId == requestId && r.reviewerId == reviewerId);
  }

  List<ReviewModel> getReviewsForUser(String userId) {
    return _reviews.where((r) => r.revieweeId == userId).toList();
  }

  Future<void> submitReview({
    required String requestId,
    required String reviewerId,
    required String revieweeId,
    required int stars,
    required String comment,
    String? reviewerName,
    required Function(UserModel updatedUser) onUserUpdated,
  }) async {
    final review = ReviewModel(
      id: _uuid.v4(),
      requestId: requestId,
      reviewerId: reviewerId,
      revieweeId: revieweeId,
      stars: stars,
      comment: comment.trim(),
      createdAt: DateTime.now(),
      reviewerName: reviewerName,
    );

    _reviews.add(review);
    await _storage.saveReviews(_reviews);

    // Update user average locally in storage
    final allUsers = _storage.getUsers();
    final index = allUsers.indexWhere((u) => u.id == revieweeId);
    if (index != -1) {
      final oldUser = allUsers[index];
      final newCount = oldUser.ratingCount + 1;
      final newAvg = ((oldUser.ratingAvg * oldUser.ratingCount) + stars) / newCount;
      final updated = oldUser.copyWith(
        ratingAvg: double.parse(newAvg.toStringAsFixed(1)),
        ratingCount: newCount,
      );
      allUsers[index] = updated;
      await _storage.saveUsers(allUsers);
      onUserUpdated(updated);
    }

    if (_firebase.isInitialized) {
      await _firebase.submitReview(review);
    }

    notifyListeners();
  }
}
