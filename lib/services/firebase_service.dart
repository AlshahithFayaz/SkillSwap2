import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../data/models/user_model.dart';
import '../data/models/exchange_request_model.dart';
import '../data/models/message_model.dart';
import '../data/models/review_model.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isInitialized = true;
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firebase initialization notice: $e');
      _isInitialized = false;
    }
  }

  // --- Auth & Users ---
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) return null;
    return await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_isInitialized) return null;
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    if (_isInitialized) {
      await auth.signOut();
    }
  }

  Future<void> saveUserToFirestore(UserModel user) async {
    if (!_isInitialized) {
      debugPrint('FirebaseService not initialized, skipping saveUserToFirestore');
      return;
    }
    try {
      await firestore.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true));
      debugPrint('Successfully saved user to Firestore: ${user.name} (${user.id}) with teach: ${user.teachSkills}, learn: ${user.learnSkills}');
    } catch (e) {
      debugPrint('Failed to save user to Firestore: $e');
    }
  }

  Future<UserModel?> getUserFromFirestore(String userId) async {
    if (!_isInitialized) return null;
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, documentId: doc.id);
      }
    } catch (e) {
      debugPrint('Failed to get user from Firestore: $e');
    }
    return null;
  }

  Stream<List<UserModel>> streamAllUsers(String currentUserId) {
    if (!_isInitialized) {
      debugPrint('FirebaseService not initialized, streamAllUsers is empty');
      return const Stream.empty();
    }
    return firestore.collection('users').snapshots().map((snapshot) {
      debugPrint('Firestore users snapshot received with ${snapshot.docs.length} total docs');
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }

  // --- Exchange Requests ---
  Future<void> createRequest(ExchangeRequestModel request) async {
    if (!_isInitialized) return;
    await firestore.collection('requests').doc(request.id).set(request.toMap());
  }

  Future<void> updateRequestStatus(String requestId, RequestStatus status) async {
    if (!_isInitialized) return;
    await firestore.collection('requests').doc(requestId).update({
      'status': status.value,
    });
  }

  Stream<List<ExchangeRequestModel>> streamUserRequests(String userId) {
    if (!_isInitialized) {
      return const Stream.empty();
    }
    return firestore
        .collection('requests')
        .where(Filter.or(
          Filter('fromUserId', isEqualTo: userId),
          Filter('toUserId', isEqualTo: userId),
        ))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ExchangeRequestModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }

  // --- Real-time 1-on-1 Chat Messages ---
  Future<void> sendMessage(String requestId, MessageModel message) async {
    if (!_isInitialized) return;
    await firestore
        .collection('requests')
        .doc(requestId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Stream<List<MessageModel>> streamMessages(String requestId) {
    if (!_isInitialized) {
      return const Stream.empty();
    }
    return firestore
        .collection('requests')
        .doc(requestId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }

  // --- Reviews ---
  Future<void> submitReview(ReviewModel review) async {
    if (!_isInitialized) return;
    await firestore.collection('reviews').doc(review.id).set(review.toMap());

    // Update reviewee average in users collection
    final revieweeDoc = await firestore.collection('users').doc(review.revieweeId).get();
    if (revieweeDoc.exists && revieweeDoc.data() != null) {
      final user = UserModel.fromMap(revieweeDoc.data()!, documentId: revieweeDoc.id);
      final newCount = user.ratingCount + 1;
      final newAvg = ((user.ratingAvg * user.ratingCount) + review.stars) / newCount;

      await firestore.collection('users').doc(user.id).update({
        'ratingAvg': double.parse(newAvg.toStringAsFixed(2)),
        'ratingCount': newCount,
      });
    }
  }

  Stream<List<ReviewModel>> streamUserReviews(String userId) {
    if (!_isInitialized) {
      return const Stream.empty();
    }
    return firestore
        .collection('reviews')
        .where('revieweeId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromMap(doc.data(), documentId: doc.id))
          .toList();
    });
  }
}
