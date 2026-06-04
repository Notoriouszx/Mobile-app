import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Check if user has an active session on app startup
  /// Calls GET /api/auth/get-session
  Future<void> checkSession() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final user = await _authService.getSession();
      if (user != null && user.role == 'patient') {
        _user = user;
        _status = AuthStatus.authenticated;
        _error = null;
        print('Session check: User authenticated - ${user.email}');
      } else {
        _status = AuthStatus.unauthenticated;
        _error = null;
        print('Session check: No valid patient session');
      }
    } catch (e) {
      print('checkSession error: $e');
      _status = AuthStatus.unauthenticated;
      _error = null;
    }
    notifyListeners();
  }

  /// Sign in with email and password
  /// Calls POST /api/auth/sign-in/email
  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      print('Attempting sign in with: $email');
      final user = await _authService.signIn(email, password);
      print('Sign in response: id=${user.id}, role=${user.role}, email=${user.email}');

      // Verify user is a patient
      if (user.role != 'patient') {
        _error = 'هذا التطبيق مخصص للمرضى فقط. دورك: ${user.role}';
        _status = AuthStatus.unauthenticated;
        print('Sign in failed: User is not a patient (role=${user.role})');
        notifyListeners();
        return false;
      }

      _user = user;
      _status = AuthStatus.authenticated;
      _error = null;
      print('Sign in successful: ${user.name} (${user.email})');
      notifyListeners();
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      _error = errorMsg;
      _status = AuthStatus.unauthenticated;
      print('Sign in error: $errorMsg');
      notifyListeners();
      return false;
    }
  }

  /// Sign out and clear session
  /// Calls POST /api/auth/sign-out
  Future<void> signOut() async {
    try {
      print('Signing out...');
      await _authService.signOut();
    } catch (e) {
      print('Sign out error: $e');
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
    print('Signed out');
  }

  /// Clear error message manually
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
