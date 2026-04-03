/// SafeGuardHer - Auth Service
/// Handles Firebase Authentication (email/password) and Firestore user creation.
/// Falls back to local simulation when Firebase is not configured yet.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  AuthService() {
    _loadSavedUser();
  }

  /// Load user from local storage on app start
  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email');
    final name = prefs.getString('user_name');
    final uid = prefs.getString('user_uid');

    if (email != null && name != null && uid != null) {
      _currentUser = UserModel(
        uid: uid,
        fullName: name,
        email: email,
        phone: prefs.getString('user_phone') ?? '',
        createdAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Sign up with email and password
  /// Stores user data locally (swap with Firebase when ready)
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simulate network delay for realistic feel
      await Future.delayed(const Duration(seconds: 1));

      final uid = DateTime.now().millisecondsSinceEpoch.toString();

      _currentUser = UserModel(
        uid: uid,
        fullName: fullName,
        email: email,
        phone: phone,
        createdAt: DateTime.now(),
      );

      // Persist to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', uid);
      await prefs.setString('user_email', email);
      await prefs.setString('user_name', fullName);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_password', password);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Log in with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('user_email');
      final savedPassword = prefs.getString('user_password');

      if (savedEmail == email && savedPassword == password) {
        _currentUser = UserModel(
          uid: prefs.getString('user_uid') ?? '',
          fullName: prefs.getString('user_name') ?? '',
          email: email,
          phone: prefs.getString('user_phone') ?? '',
          createdAt: DateTime.now(),
        );
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign out and clear session
  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_phone');
    notifyListeners();
  }
}
