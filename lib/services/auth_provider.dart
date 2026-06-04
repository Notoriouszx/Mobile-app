import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Called on app start — checks if a session cookie already exists
  Future<void> checkSession() async {
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _authService.getSession();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signIn(email, password);
      if (user == null) {
        _error = 'فشل تسجيل الدخول';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      if (user.role != 'patient') {
        _error = 'هذا التطبيق مخصص للمرضى فقط. دورك: ${user.role}';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
      _user = user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }
}
