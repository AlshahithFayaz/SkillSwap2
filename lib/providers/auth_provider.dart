import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/user_model.dart';
import '../data/repositories/mock_data.dart';
import '../services/local_storage_service.dart';
import '../services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final LocalStorageService _storage;
  final FirebaseService _firebase = FirebaseService();
  final _uuid = const Uuid();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider(this._storage) {
    _init();
  }

  void _init() {
    _currentUser = _storage.getCurrentUser();
    // Seed peers locally if storage is empty
    if (_storage.getUsers().isEmpty) {
      _storage.saveUsers(MockData.seedStudents);
    }
    if (_currentUser != null) {
      syncCurrentUserToFirestore();
    }
  }

  Future<void> syncCurrentUserToFirestore() async {
    if (_currentUser == null) return;
    try {
      if (!_firebase.isInitialized) {
        await _firebase.initialize();
      }
      if (_firebase.isInitialized) {
        await _firebase.saveUserToFirestore(_currentUser!);
      }
    } catch (e) {
      debugPrint('Error syncing user to Firestore: $e');
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_firebase.isInitialized) {
        final cred = await _firebase.signInWithEmail(email: email, password: password);
        if (cred?.user != null) {
          final firestoreUser = await _firebase.getUserFromFirestore(cred!.user!.uid);
          if (firestoreUser != null) {
            _currentUser = firestoreUser;
            await _storage.saveCurrentUser(_currentUser!);
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      }

      // Local / Offline demo authentication fallback
      final allUsers = _storage.getUsers();
      final existingUser = allUsers.firstWhere(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
        orElse: () => UserModel(
          id: 'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}',
          name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
          email: email.trim(),
          rollNo: '22CS099',
          department: 'CSE',
          year: '3rd',
          teachSkills: ['Python', 'Data Structures'],
          learnSkills: ['Figma', 'UI/UX Design'],
        ),
      );

      _currentUser = existingUser;
      await _storage.saveCurrentUser(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String rollNo,
    required String department,
    required String year,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String userId = _uuid.v4();

      if (_firebase.isInitialized) {
        final cred = await _firebase.signUpWithEmail(email: email, password: password);
        if (cred?.user != null) {
          userId = cred!.user!.uid;
        }
      }

      final newUser = UserModel(
        id: userId,
        name: name.trim(),
        email: email.trim(),
        rollNo: rollNo.trim().toUpperCase(),
        department: department,
        year: year,
        teachSkills: [],
        learnSkills: [],
      );

      _currentUser = newUser;
      await _storage.saveCurrentUser(newUser);

      if (_firebase.isInitialized) {
        await _firebase.saveUserToFirestore(newUser);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateSkills({
    required List<String> teachSkills,
    required List<String> learnSkills,
  }) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      teachSkills: teachSkills,
      learnSkills: learnSkills,
    );

    await _storage.saveCurrentUser(_currentUser!);

    if (_firebase.isInitialized) {
      await _firebase.saveUserToFirestore(_currentUser!);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    await _storage.clearCurrentUser();
    if (_firebase.isInitialized) {
      await _firebase.signOut();
    }
    notifyListeners();
  }
}
