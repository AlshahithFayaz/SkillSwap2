import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/user_model.dart';
import '../data/repositories/mock_data.dart';
import '../core/utils/matching_engine.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class MatchItem {
  final UserModel candidate;
  final MatchCalculationResult result;

  MatchItem({required this.candidate, required this.result});
}

class MatchProvider with ChangeNotifier {
  final LocalStorageService _storage;
  final FirebaseService _firebase = FirebaseService();
  StreamSubscription? _usersSub;

  List<UserModel> _candidates = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedDepartment = 'All';
  String _selectedYear = 'All';

  List<UserModel> get candidates => _candidates;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedDepartment => _selectedDepartment;
  String get selectedYear => _selectedYear;

  MatchProvider(this._storage) {
    loadCandidates();
  }

  void loadCandidates([String? currentUserId]) {
    _isLoading = true;
    _candidates = _storage.getUsers();
    if (_candidates.isEmpty) {
      _candidates = List.from(MockData.seedStudents);
      _storage.saveUsers(_candidates);
    }
    _isLoading = false;
    notifyListeners();
  }

  void syncWithUser(UserModel? currentUser) {
    if (currentUser == null) return;

    // Load initial candidates map
    final localUsers = _storage.getUsers();
    final Map<String, UserModel> map = {};

    for (final mock in MockData.seedStudents) {
      if (mock.id != currentUser.id && mock.email.toLowerCase() != currentUser.email.toLowerCase()) {
        map[mock.id] = mock;
      }
    }

    for (final u in localUsers) {
      if (u.id != currentUser.id && u.email.toLowerCase() != currentUser.email.toLowerCase()) {
        map[u.id] = u;
      }
    }

    _candidates = map.values.toList();
    notifyListeners();

    // Listen to live Firestore users stream
    if (_firebase.isInitialized) {
      _usersSub?.cancel();
      _usersSub = _firebase.streamAllUsers(currentUser.id).listen((firestoreUsers) {
        debugPrint('MatchProvider: received ${firestoreUsers.length} users from Firestore');
        for (final u in firestoreUsers) {
          if (u.id != currentUser.id && u.email.toLowerCase() != currentUser.email.toLowerCase()) {
            map[u.id] = u;
          }
        }
        _candidates = map.values.toList();
        _storage.saveUsers(_candidates);
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error streaming Firestore users: $e');
      });
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    super.dispose();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  void setSelectedDepartment(String dept) {
    _selectedDepartment = dept;
    notifyListeners();
  }

  void setSelectedYear(String year) {
    _selectedYear = year;
    notifyListeners();
  }

  void resetFilters() {
    _searchQuery = '';
    _selectedDepartment = 'All';
    _selectedYear = 'All';
    notifyListeners();
  }

  /// Calculates and filters matches for the active user
  List<MatchItem> getRankedMatches(UserModel? currentUser) {
    if (currentUser == null) return [];

    final List<MatchItem> matches = [];

    for (final candidate in _candidates) {
      if (candidate.id == currentUser.id) continue;

      // Filter by Department
      if (_selectedDepartment != 'All' &&
          candidate.department.toLowerCase() != _selectedDepartment.toLowerCase()) {
        continue;
      }

      // Filter by Year
      if (_selectedYear != 'All' &&
          candidate.year.toLowerCase() != _selectedYear.toLowerCase()) {
        continue;
      }

      // Filter by search query (name or skills)
      if (_searchQuery.isNotEmpty) {
        final matchesName = candidate.name.toLowerCase().contains(_searchQuery);
        final matchesTeach = candidate.teachSkills
            .any((s) => s.toLowerCase().contains(_searchQuery));
        final matchesLearn = candidate.learnSkills
            .any((s) => s.toLowerCase().contains(_searchQuery));

        if (!matchesName && !matchesTeach && !matchesLearn) {
          continue;
        }
      }

      // Calculate compatibility score
      final result = MatchingEngine.calculateMatch(
        myTeachSkills: currentUser.teachSkills,
        myLearnSkills: currentUser.learnSkills,
        theirTeachSkills: candidate.teachSkills,
        theirLearnSkills: candidate.learnSkills,
      );

      // Rule: exclude users with score of 0
      if (result.score > 0) {
        matches.add(MatchItem(candidate: candidate, result: result));
      }
    }

    // Sort: Mutual matches first, then highest score first
    matches.sort((a, b) {
      if (a.result.isMutual != b.result.isMutual) {
        return a.result.isMutual ? -1 : 1;
      }
      return b.result.score.compareTo(a.result.score);
    });

    return matches;
  }
}
